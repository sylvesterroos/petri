Mix.install([{:petri, path: "."}, :nx, {:exla, "~> 0.12"}])
Nx.global_default_backend(EXLA.Backend)

defmodule MLHyperparams do
  @moduledoc """
  Tunes learning rate, L2 regularization, and training epochs for a linear
  regression model using a real-coded GA.

  The dataset is synthetic: 10 features, target = 2x₁ + 3x₂ − 1.5x₃ + noise.
  Each fitness evaluation trains a model from scratch with the candidate
  hyperparameters and scores it on a held-out test set.

  Uses Nx for tensor operations.
  """

  alias Petri.Chromosome.Real

  @n_features 10
  @true_weights_list [2.0, 3.0, -1.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

  @n_train 100
  @n_test 40

  @doc """
  Runs the hyperparameter tuning GA and prints results.
  """
  def run do
    # Synthetic dataset: 10 features but only the first 3 carry signal.
    # The true relationship is y = 2x₁ + 3x₂ − 1.5x₃ + ε, where ε ~ N(0, σ²=0.01).
    # ε is Gaussian noise (mean 0, std dev 0.1) that models measurement error and
    # unobserved factors. Without it the relationship would be deterministic and any
    # model could fit perfectly; the noise makes it realistic and tests whether the
    # GA can find hyperparameters that recover the signal through the scatter.
    # Features 4–10 are noise, but the GA doesn't know that. It has to learn
    # which hyperparameters let the model fit the signal and ignore the rest.
    key = Nx.Random.key(99)
    keys = Nx.Random.split(key, parts: 4)

    {train_x, _key} = Nx.Random.uniform(Nx.take(keys, 0), shape: {@n_train, @n_features})
    {test_x, _key} = Nx.Random.uniform(Nx.take(keys, 1), shape: {@n_test, @n_features})

    {noise_train, _key} = Nx.Random.normal(Nx.take(keys, 2), 0.0, 0.1, shape: {@n_train})
    {noise_test, _key} = Nx.Random.normal(Nx.take(keys, 3), 0.0, 0.1, shape: {@n_test})

    true_weights = Nx.tensor(@true_weights_list)

    train_y = Nx.add(Nx.dot(train_x, true_weights), noise_train)
    test_y = Nx.add(Nx.dot(test_x, true_weights), noise_test)

    oracle_r2 = r2(test_y, Nx.dot(test_x, true_weights))

    fitness = fn %Real{genes: [lr, lambda, epochs]} ->
      epochs_int = max(1, round(epochs))
      weights = train(train_x, train_y, lr, lambda, epochs_int)
      r2(test_y, Nx.dot(test_x, weights))
    end

    # BLX-α creates offspring in an interval extending beyond the parents
    # by a fraction α of their distance, which helps explore continuous
    # spaces without getting stuck. Gaussian mutation adds small
    # perturbations for local fine-tuning.
    config = %{
        encoding: :real,
        bounds: [
          {1.0e-4, 1.0e-1},
          {1.0e-6, 1.0e-1},
          {10.0, 200.0}
        ],
        population_size: 50,
        max_generations: 40,
        stagnation_generations: 10,
        seed: 42,
        selection: :tournament,
        tournament_size: 3,
        elite_count: 3,
        crossover: :blx_alpha,
        blx_alpha_param: 0.5,
        mutation: :gaussian,
        gaussian_sigma: 0.15,
        mutation_rate: 0.3
      }

    IO.puts("Running GA (#{config.max_generations} generations, pop #{config.population_size})...")

    result = Petri.run(fitness, config)

    {best_chromosome, best_fitness} = result.best
    [lr, lambda, epochs] = best_chromosome.genes

    # Retrain with the best hyperparams on all data to get final weights.
    all_x = Nx.concatenate([train_x, test_x])
    all_y = Nx.concatenate([train_y, test_y])
    final_weights = train(all_x, all_y, lr, lambda, round(epochs))

    IO.puts("""
    ML Hyperparameter Tuning — Linear Regression
    ============================================
    generations run: #{result.generations_run}
    evaluations:     #{result.evaluations}

    Best hyperparameters found:
      learning rate:       #{:erlang.float_to_binary(lr, decimals: 6)}
      L2 regularization:   #{:erlang.float_to_binary(lambda, decimals: 8)}
      training epochs:     #{round(epochs)}

    Test R² achieved:      #{:erlang.float_to_binary(best_fitness, decimals: 4)}
    Oracle R² (true wts):  #{:erlang.float_to_binary(oracle_r2, decimals: 4)}

    Learned weights vs true weights:
    #{weight_table(Nx.to_list(final_weights), @true_weights_list)}
    """)

    visualize(result.history)
  end

  # Vanilla gradient descent. The dataset is small enough to use the full
  # batch each step. L2 regularization (lambda) shrinks weights toward zero,
  # which helps when the model has more features than signal.
  defp train(x, y, lr, lambda, epochs) do
    n_features = Nx.axis_size(x, 1)
    n = Nx.axis_size(x, 0)
    w = Nx.broadcast(0.0, {n_features})

    Enum.reduce(1..epochs, w, fn _, w ->
      pred = Nx.dot(x, w)
      error = Nx.subtract(pred, y)
      grad = Nx.add(Nx.dot(Nx.transpose(x), error) |> Nx.divide(n), Nx.multiply(lambda, w))
      Nx.subtract(w, Nx.multiply(lr, grad))
    end)
  end

  # R² = 1 − (residual sum of squares / total sum of squares).
  # 1.0 means perfect prediction, 0.0 means the model is no better than
  # predicting the mean. Can go negative if the model is worse than that.
  defp r2(y_true, y_pred) do
    y_mean = Nx.mean(y_true)
    ss_res = Nx.sum(Nx.pow(Nx.subtract(y_true, y_pred), 2))
    ss_tot = Nx.sum(Nx.pow(Nx.subtract(y_true, y_mean), 2))
    if Nx.to_number(ss_tot) == 0.0, do: 1.0, else: 1.0 - Nx.to_number(Nx.divide(ss_res, ss_tot))
  end

  defp weight_table(learned, target) do
    header = "  feature | learned | true\n  --------|---------|------"

    rows =
      Enum.zip([learned, target])
      |> Enum.with_index(1)
      |> Enum.map(fn {{l, t}, i} ->
        sl = :erlang.float_to_binary(l, decimals: 4) |> String.pad_leading(7)
        st = :erlang.float_to_binary(t, decimals: 4) |> String.pad_leading(7)
        "  #{Integer.to_string(i) |> String.pad_leading(7)} | #{sl} | #{st}"
      end)
      |> Enum.join("\n")

    header <> "\n" <> rows
  end

  def visualize(history) do
    IO.puts("Building parameter charts...")

    data =
      history
      |> Enum.with_index()
      |> Enum.map(fn {snapshot, gen} ->
        [lr, lambda, epochs] = snapshot.best_chromosome.genes
        %{gen: gen, lr: lr, lambda: lambda, epochs: round(epochs), fitness: snapshot.max_fitness}
      end)

    n = length(data) - 1
    frames = Enum.map(0..n, fn i -> chart_svg(data, i, n) end)

    make_webp(frames, "hyperparams_evolution.webp", fps: 12)
    IO.puts("▶ Open hyperparams_evolution.webp to watch the parameters evolve")
  end

  defp chart_svg(data, frame_n, total_n) do
    w = 800
    h = 200
    ml = 60
    mr = 20
    mt = 16
    mb = 28
    pw = w - ml - mr
    ph = h - mt - mb

    panel = fn y_off, title, lo, hi, log?, extract, fmt ->
      scale =
        if log?,
          do: fn v ->
            max(v, lo)
            |> then(&:math.log10(&1))
            |> then(&((&1 - :math.log10(lo)) / (:math.log10(hi) - :math.log10(lo))))
          end,
          else: fn v -> (v - lo) / (hi - lo) end

      # Grid lines + Y labels
      grid =
        0..5
        |> Enum.map(fn g ->
          t = g / 5
          gy = y_off + mt + (1 - t) * ph

          val =
            if log?,
              do: :math.pow(10, :math.log10(lo) + t * (:math.log10(hi) - :math.log10(lo))),
              else: lo + t * (hi - lo)

          label =
            if log?,
              do: :io_lib.format("~.2e", [val]) |> List.to_string(),
              else: :erlang.float_to_binary(val, decimals: if(title =~ "R²", do: 2, else: 0))

          ~s(<line x1="#{ml}" x2="#{w - mr}" y1="#{gy}" y2="#{gy}" stroke="#1e293b" stroke-width="0.5"/>) <>
            ~s(<text x="#{ml - 3}" y="#{gy + 3}" fill="#64748b" font-family="monospace" font-size="9" text-anchor="end">#{label}</text>)
        end)
        |> Enum.join("\n        ")

      # X labels
      step = max(1, div(total_n, 10))

      x_labels =
        0..total_n
        |> Enum.take_every(step)
        |> Enum.map(fn g ->
          x = ml + g / total_n * pw

          ~s(<text x="#{x}" y="#{y_off + h - 5}" fill="#64748b" font-family="monospace" font-size="8" text-anchor="middle">#{g}</text>)
        end)
        |> Enum.join("\n        ")

      # Polyline
      points =
        0..frame_n
        |> Enum.map(fn j ->
          v = extract.(Enum.at(data, j))
          x = ml + j / total_n * pw
          y = y_off + mt + (1 - scale.(v)) * ph
          "#{x},#{y}"
        end)
        |> Enum.join(" ")

      # Latest point marker
      latest_v = extract.(Enum.at(data, frame_n))
      lx = ml + frame_n / total_n * pw
      ly = y_off + mt + (1 - scale.(latest_v)) * ph
      val_str = fmt.(latest_v)

      ~s"""
      <rect width="#{w}" height="#{h}" x="0" y="#{y_off}" fill="#1a1a2e"/>
      <text x="#{ml}" y="#{y_off + 12}" fill="#94a3b8" font-family="monospace" font-size="10">#{title}</text>
      <text x="#{w - mr}" y="#{y_off + 12}" fill="#60a5fa" font-family="monospace" font-size="11" text-anchor="end" font-weight="bold">#{val_str}</text>
      #{grid}
      #{x_labels}
      <polyline points="#{points}" fill="none" stroke="#4ade80" stroke-width="1.5"/>
      <circle cx="#{lx}" cy="#{ly}" r="4" fill="#4ade80"/>
      """
    end

    lr_fmt = fn v -> :io_lib.format("~.2e", [v]) |> List.to_string() end
    lambda_fmt = fn v -> :io_lib.format("~.2e", [v]) |> List.to_string() end
    epochs_fmt = fn v -> Integer.to_string(v) end
    fitness_fmt = fn v -> :erlang.float_to_binary(v, decimals: 4) end

    p0 = panel.(0, "Learning Rate", 1.0e-4, 1.0e-1, true, fn d -> d.lr end, lr_fmt)
    p1 = panel.(200, "L2 Regularization λ", 1.0e-6, 1.0e-1, true, fn d -> d.lambda end, lambda_fmt)
    p2 = panel.(400, "Training Epochs", 10, 200, false, fn d -> d.epochs end, epochs_fmt)
    p3 = panel.(600, "Best Fitness (R²)", 0.0, 1.0, false, fn d -> d.fitness end, fitness_fmt)

    ~s"""
    <svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" viewBox="0 0 800 800">
      #{p0}
      #{p1}
      #{p2}
      #{p3}
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

MLHyperparams.run()
