Mix.install([{:petri, path: "."}])

defmodule FeatureSelection do
  @moduledoc """
  Selects informative features from a synthetic dataset using a binary-coded
  GA with uniform crossover and bit-flip mutation.

  The dataset has 20 features but only 4 of them (indices 2, 5, 9, 15)
  contribute to the target. The target is a linear combination of those
  four features plus Gaussian noise. A good solution selects exactly the
  four signal features and ignores the 16 noise features.

  Each bit in the chromosome represents whether a feature is included (1)
  or excluded (0). The fitness is 1 / (1 + MSE) where MSE is the mean
  squared error when predicting the target from only the selected features.
  Because the targets contain irreducible Gaussian noise (variance 0.1),
  a perfect feature set still cannot achieve fitness 1.0 — the noise
  alone yields an MSE of ~0.1, capping fitness at ~0.909.
  """

  alias Petri.Chromosome.Binary

  @n_features 20
  @n_samples 200
  @true_features MapSet.new([2, 5, 9, 15])

  @doc """
  Runs the feature selection GA and prints results.
  """
  def run do
    # Deterministic synthetic data so the example is reproducible.
    :rand.seed(:exsss, 42)

    data = for _ <- 1..@n_samples, do: for(_ <- 1..@n_features, do: :rand.uniform())

    targets =
      Enum.map(data, fn row ->
        signal =
          row
          |> Enum.with_index(1)
          |> Enum.reduce(0.0, fn {v, i}, acc ->
            if MapSet.member?(@true_features, i), do: acc + v, else: acc
          end)

        signal + :rand.normal(0.0, 0.1)
      end)

    # Fitness: how well the selected features predict the target.
    # We use a simple sum of selected feature values as the predictor
    # (equivalent to a linear model with fixed unit weights).
    #
    # :rand.normal/2 takes (mean, variance), so the noise variance here
    # is 0.1 (std ≈ 0.316). Because the
    # fitness is 1 / (1 + MSE), the irreducible noise sets an upper
    # bound of ~1 / (1 + 0.1) ≈ 0.909 — a perfect feature set that
    # exactly reconstructs the signal still cannot reach 1.0.
    fitness = fn %Binary{genes: mask} ->
      predictions =
        Enum.map(data, fn row ->
          row
          |> Enum.zip(mask)
          |> Enum.reduce(0.0, fn {v, m}, acc -> if m == 1, do: acc + v, else: acc end)
        end)

      mse =
        Enum.zip(predictions, targets)
        |> Enum.reduce(0.0, fn {p, t}, acc -> acc + (p - t) ** 2 end)
        |> Kernel./(@n_samples)

      1.0 / (1.0 + mse)
    end

    # Uniform crossover treats each bit independently — each gene comes
    # from either parent with equal probability. This works well for
    # feature selection because features don't have a spatial ordering
    # (unlike TSP where adjacent genes matter).
    #
    # Bit-flip mutation toggles individual bits at a low per-gene rate
    # (~1/L so one bit flips per mutation event on average). This lets
    # the GA add or drop single features without disrupting the whole mask.
    config = [
        encoding: :binary,
        length: @n_features,
        population_size: 80,
        max_generations: 80,
        stagnation_generations: 15,
        seed: 17,
        selection: :tournament,
        tournament_size: 3,
        elite_count: 3,
        crossover: :uniform,
        mutation: :bit_flip,
        mutation_rate: 0.4,
        mutation_per_gene_rate: 1.0 / @n_features
      ]

    IO.puts("Running GA (#{config[:max_generations]} generations, pop #{config[:population_size]})...")

    result = Petri.run(fitness, config)

    {best_chromosome, best_fitness} = result.best
    mask = best_chromosome.genes

    selected =
      mask
      |> Enum.with_index(1)
      |> Enum.filter(fn {bit, _i} -> bit == 1 end)
      |> Enum.map(fn {_bit, i} -> i end)

    true_positives = Enum.filter(selected, &MapSet.member?(@true_features, &1))
    false_positives = Enum.reject(selected, &MapSet.member?(@true_features, &1))
    false_negatives = Enum.reject(@true_features, &(&1 in selected))

    IO.puts("""
    Feature Selection
    =================
    generations run:  #{result.generations_run}
    evaluations:      #{result.evaluations}

    Selected features: #{inspect(Enum.sort(selected))}
    True features:     #{inspect(Enum.sort(@true_features))}
    True positives:    #{inspect(Enum.sort(true_positives))}
    False positives:   #{inspect(Enum.sort(false_positives))}
    False negatives:   #{inspect(Enum.sort(false_negatives))}

    fitness:           #{:erlang.float_to_binary(best_fitness, decimals: 6)}
    """)

    visualize(result.history, @n_features)
  end

  def visualize(history, n_features) do
    IO.puts("Building feature heatmap...")

    rows =
      history
      |> Enum.take_every(2)
      |> Enum.with_index()
      |> Enum.map(fn {snapshot, idx} ->
        gen = idx * 2
        mask = snapshot.best_chromosome.genes
        selected_count = Enum.count(mask, &(&1 == 1))
        fitness = snapshot.max_fitness
        {gen, mask, selected_count, fitness}
      end)

    IO.puts("Building feature heatmap...")

    frames =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {_row, n} ->
        heatmap_svg(rows, n_features, n)
      end)

    make_webp(frames, "feature_selection.webp", fps: 12)
    IO.puts("▶ Open feature_selection.webp to watch the features converge")
  end

  defp heatmap_svg(rows, n_features, visible_until) do
    true_set = @true_features
    w = 500
    cell = 20
    gap = 1
    left_margin = 48
    header_h = 22
    row_h = cell + gap
    total_h = header_h + length(rows) * row_h + 30

    # Header: feature numbers
    header =
      1..n_features
      |> Enum.map(fn fi ->
        x = left_margin + (fi - 1) * (cell + gap)
        c = if MapSet.member?(true_set, fi), do: "#60a5fa", else: "#64748b"

        ~s(<text x="#{x + cell / 2}" y="15" fill="#{c}" font-family="monospace" font-size="10" text-anchor="middle">#{fi}</text>)
      end)
      |> Enum.join("\n      ")

    # Rows: only render up to visible_until
    row_svgs =
      rows
      |> Enum.with_index()
      |> Enum.take(visible_until + 1)
      |> Enum.map(fn {{gen, mask, _count, _fitness}, _ri} ->
        y = header_h + gen / 2 * row_h

        label =
          ~s(<text x="#{left_margin - 4}" y="#{y + cell / 2 + 4}" fill="#94a3b8" font-family="monospace" font-size="9" text-anchor="end">#{gen}</text>)

        cells =
          mask
          |> Enum.with_index(1)
          |> Enum.map(fn {bit, fi} ->
            x = left_margin + (fi - 1) * (cell + gap)
            color = if bit == 1, do: "#4ade80", else: "#1f2937"
            ~s(<rect x="#{x}" y="#{y}" width="#{cell}" height="#{cell}" rx="2" fill="#{color}"/>)
          end)
          |> Enum.join("\n        ")

        label <> "\n        " <> cells
      end)
      |> Enum.join("\n      ")

    # Overlay for the latest visible generation
    {gen, _, count, fitness} = Enum.at(rows, visible_until)

    ~s"""
    <svg xmlns="http://www.w3.org/2000/svg" width="#{w}" height="#{total_h}" viewBox="0 0 #{w} #{total_h}">
      <rect width="#{w}" height="#{total_h}" fill="#1a1a2e"/>
      #{header}
      #{row_svgs}
      <text x="#{w / 2}" y="#{total_h - 8}" fill="#94a3b8" font-family="monospace" font-size="12" text-anchor="middle">
        gen #{gen}  ·  #{count} feat  ·  #{:erlang.float_to_binary(fitness, decimals: 4)}
      </text>
    </svg>
    """
    end

    defp make_webp(frames, output, opts) do
    fps = Keyword.get(opts, :fps, 30)
    total = length(frames)

    tmp = System.tmp_dir!() |> Path.join("petri_#{System.monotonic_time()}")
    File.mkdir_p!(tmp)

    Enum.with_index(frames)
    |> Enum.each(fn {svg, i} ->
      IO.write("\rGenerating frame #{i + 1}/#{total}...")
      num = String.pad_leading(Integer.to_string(i), 4, "0")
      File.write!(Path.join(tmp, "frame_#{num}.svg"), svg)
    end)
    IO.puts("")

    svgs = Path.wildcard(Path.join(tmp, "frame_*.svg"))
    svgs
    |> Enum.with_index(1)
    |> Enum.each(fn {svg_path, n} ->
      IO.write("\rRasterizing #{n}/#{total}...")
      System.cmd("rsvg-convert", ["-b", "#1a1a2e", "-o", String.replace_suffix(svg_path, ".svg", ".png"), svg_path])
    end)
    IO.puts("")

    IO.write("Encoding #{output}...")
    System.cmd("ffmpeg", [
      "-y", "-v", "quiet", "-framerate", Integer.to_string(fps),
      "-i", Path.join(tmp, "frame_%04d.png"),
      "-c:v", "libwebp_anim",
      "-lossless", "0",
      "-quality", "80",
      "-loop", "0",
      output
    ])
    IO.puts(" done")

    File.rm_rf!(tmp)
  end
end

FeatureSelection.run()
