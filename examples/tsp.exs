Mix.install([{:petri, path: "."}])

defmodule TSP do
  @moduledoc """
  Solves the Berlin52 TSP instance with Petri.

  Berlin52 has 52 cities in Euclidean 2D space. The known optimal tour
  length is approximately 7542 distance units. This example keeps the
  chromosome as a permutation of city indices and uses a fitness function
  that rewards short tours.
  """

  alias Petri.Chromosome.Permutation

  @cities [
    {0, 565.0, 575.0},
    {1, 25.0, 185.0},
    {2, 345.0, 750.0},
    {3, 945.0, 685.0},
    {4, 845.0, 655.0},
    {5, 880.0, 660.0},
    {6, 25.0, 230.0},
    {7, 525.0, 1000.0},
    {8, 580.0, 1175.0},
    {9, 650.0, 1130.0},
    {10, 1605.0, 620.0},
    {11, 1220.0, 580.0},
    {12, 1465.0, 200.0},
    {13, 1530.0, 5.0},
    {14, 845.0, 680.0},
    {15, 725.0, 370.0},
    {16, 145.0, 665.0},
    {17, 415.0, 635.0},
    {18, 510.0, 875.0},
    {19, 560.0, 365.0},
    {20, 300.0, 465.0},
    {21, 520.0, 585.0},
    {22, 480.0, 415.0},
    {23, 835.0, 625.0},
    {24, 975.0, 580.0},
    {25, 1215.0, 245.0},
    {26, 1320.0, 315.0},
    {27, 1250.0, 400.0},
    {28, 660.0, 180.0},
    {29, 410.0, 250.0},
    {30, 420.0, 555.0},
    {31, 575.0, 665.0},
    {32, 1150.0, 1160.0},
    {33, 700.0, 580.0},
    {34, 685.0, 595.0},
    {35, 685.0, 610.0},
    {36, 770.0, 610.0},
    {37, 795.0, 645.0},
    {38, 720.0, 635.0},
    {39, 760.0, 650.0},
    {40, 475.0, 960.0},
    {41, 95.0, 260.0},
    {42, 875.0, 920.0},
    {43, 700.0, 500.0},
    {44, 555.0, 815.0},
    {45, 830.0, 485.0},
    {46, 1170.0, 65.0},
    {47, 830.0, 610.0},
    {48, 605.0, 625.0},
    {49, 595.0, 360.0},
    {50, 1340.0, 725.0},
    {51, 1740.0, 245.0}
  ]

  @optimal 7542.0

  def run do
    fitness = fn %Permutation{genes: tour} ->
      1.0 / tour_distance(tour)
    end

    # TSP tours are permutations. Order Crossover (OX) preserves long
    # contiguous sub-tours from one parent, which is good for TSP because
    # edge length matters locally. Inversion mutation reverses a random
    # segment, which is the classic 2-opt neighbourhood move and helps
    # untangle crossing edges.
    config = [
        encoding: :permutation,
        n: length(@cities),
        population_size: 400,
        max_generations: 1000,
        stagnation_generations: 100,
        seed: 67,
        # Tournament selection focuses search on the fittest individuals,
        # which is helpful for TSP where small tour-length improvements are
        # hard to find by chance.
        selection: :tournament,
        tournament_size: 5,
        # Preserve a small set of the best tours each generation so good
        # edge collections are not destroyed by crossover or mutation.
        elite_count: 8,
        crossover: :ox,
        mutation: :inversion
      ]

    IO.puts("Running GA (#{config[:max_generations]} generations, pop #{config[:population_size]})...")

    result = Petri.run(fitness, config)

    {best_tour, best_fitness} = result.best
    best_distance = 1.0 / best_fitness

    IO.puts("""
    Berlin52 TSP
    ============
    generations run: #{result.generations_run}
    evaluations:     #{result.evaluations}
    best distance:   #{:erlang.float_to_binary(best_distance, decimals: 2)}
    optimal:         #{:erlang.float_to_binary(@optimal, decimals: 2)}
    gap:             #{:erlang.float_to_binary(100.0 * (best_distance - @optimal) / @optimal, decimals: 2)}%
    best tour:       #{inspect(best_tour.genes)}
    """)

    visualize(result.history)
  end

  defp tour_distance(tour) do
    tour
    |> Enum.chunk_every(2, 1, [hd(tour)])
    |> Enum.reduce(0.0, fn [a, b], acc -> acc + distance(a, b) end)
  end

  defp distance(a, b) do
    {_, ax, ay} = Enum.at(@cities, a)
    {_, bx, by} = Enum.at(@cities, b)

    dx = ax - bx
    dy = ay - by

    :math.sqrt(dx * dx + dy * dy)
  end

  def visualize(history) do
    sample_rate = 5

    IO.puts("Building tour animation...")

    frames =
      history
      |> Enum.take_every(sample_rate)
      |> Enum.with_index()
      |> Enum.map(fn {snapshot, idx} ->
        gen = idx * sample_rate
        tour = snapshot.best_chromosome.genes
        distance = tour_distance(tour)
        svg_frame(tour, gen, distance)
      end)

    make_webp(frames, "tsp_evolution.webp", fps: 20, width: 1900)
    IO.puts("▶ Open tsp_evolution.webp to watch the tour converge")
  end

  defp make_webp(frames, output, opts) do
    fps = Keyword.get(opts, :fps, 30)
    width = Keyword.get(opts, :width)
    total = length(frames)

    tmp = System.tmp_dir!() |> Path.join("petri_#{System.monotonic_time()}")
    File.mkdir_p!(tmp)

    Enum.with_index(frames)
    |> Enum.each(fn {svg, i} ->
      IO.write("\r  Rendering frame #{i + 1}/#{total}...")
      num = String.pad_leading(Integer.to_string(i), 4, "0")
      File.write!(Path.join(tmp, "frame_#{num}.svg"), svg)
    end)

    IO.puts("")

    rsvg_args = ["-b", "#1a1a2e"]
    rsvg_args = if width, do: rsvg_args ++ ["-w", Integer.to_string(width)], else: rsvg_args

    svgs = Path.wildcard(Path.join(tmp, "frame_*.svg"))

    svgs
    |> Enum.with_index(1)
    |> Enum.each(fn {svg_path, n} ->
      IO.write("\r  Encoding #{n}/#{total}...")

      System.cmd(
        "rsvg-convert",
        rsvg_args ++ ["-o", String.replace_suffix(svg_path, ".svg", ".png"), svg_path]
      )
    end)

    IO.puts("")

    IO.write("  Compressing...")

    System.cmd("ffmpeg", [
      "-y",
      "-v",
      "quiet",
      "-framerate",
      Integer.to_string(fps),
      "-i",
      Path.join(tmp, "frame_%04d.png"),
      "-c:v",
      "libwebp_anim",
      "-lossless",
      "1",
      "-loop",
      "0",
      output
    ])

    IO.puts(" done")

    File.rm_rf!(tmp)
  end

  defp svg_frame(tour, gen, distance) do
    # Build individual line segments between consecutive cities
    pairs = Enum.chunk_every(tour, 2, 1, [hd(tour)])

    # Color gradient: red (gen 0) → green (gen 1000)
    t = min(1.0, gen / 1000)
    r = round((1.0 - t) * 255)
    g = round(t * 255)
    color = "rgb(#{r},#{g},0)"

    tour_lines =
      Enum.map(pairs, fn [a, b] ->
        {_, ax, ay} = Enum.at(@cities, a)
        {_, bx, by} = Enum.at(@cities, b)
        ~s(<line x1="#{ax}" y1="#{ay}" x2="#{bx}" y2="#{by}" stroke="#{color}" stroke-width="2"/>)
      end)
      |> Enum.join("\n      ")

    ~s"""
    <svg xmlns="http://www.w3.org/2000/svg" width="1900" height="1200" viewBox="0 0 1900 1200">
      <rect width="1900" height="1200" fill="#1a1a2e"/>
      #{tour_lines}
      #{city_dots()}
      <text x="20" y="36" fill="#e0e0e0" font-family="monospace" font-size="18">
        gen #{gen}  ·  distance #{:erlang.float_to_binary(distance, decimals: 1)}
      </text>
    </svg>
    """
  end

  defp city_dots do
    @cities
    |> Enum.map(fn {_idx, x, y} ->
      ~s(<circle cx="#{x}" cy="#{y}" r="4" fill="#6b7280"/>)
    end)
    |> Enum.join("\n      ")
  end
end

TSP.run()
