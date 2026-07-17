Mix.install([{:petri, path: "."}])

defmodule RingInscription do
  @moduledoc """
  Evolve a string to match a target using integer chromosomes.

  Each gene is a byte (0–255), one character.
  Correctly positioned characters provide incremental fitness, while matching
  bigrams receive an additional bonus so selection also favors contiguous
  fragments.
  """

  alias Petri.Chromosome.Integer, as: Chromosome

  @target "One Ring to rule them all, One Ring to find them, One Ring to bring them all, and in the darkness bind them"

  def run do
    n = String.length(@target)
    target_chars = String.to_charlist(@target)
    target_bigrams = bigrams(target_chars)
    max_fitness = n + 2 * length(target_bigrams)

    fitness = fn %Chromosome{genes: string} ->
      character_score =
        string
        |> Enum.zip(target_chars)
        |> Enum.count(fn {a, b} -> a == b end)

      bigram_score =
        string
        |> bigrams()
        |> Enum.zip(target_bigrams)
        |> Enum.count(fn {a, b} -> a == b end)

      character_score + 2 * bigram_score
    end

    # Two-point crossover swaps a contiguous segment between parents, preserving
    # correctly positioned bigrams except where the segment boundaries cut them.
    # Tournament selection favors chromosomes with more correct bigrams, while
    # elitism preserves the best complete chromosome unchanged.
    result =
      Petri.run(fitness, [
        encoding: :integer,
        bounds: List.duplicate({0, 255}, n),
        population_size: 200,
        max_generations: 10_000,
        stagnation_generations: 200,
        selection: :tournament,
        tournament_size: 5,
        crossover: :two_point,
        crossover_rate: 0.9,
        mutation: :uniform,
        mutation_per_gene_rate: 0.01,
        mutation_rate: 1.0,
        elite_count: 1,
        fitness_threshold: max_fitness * 1.0,
        seed: 9
      ])

    animate(result.history)

    {best_chromosome, best_fitness} = result.best

    best_string =
      best_chromosome.genes
      |> Enum.map(fn
        10 -> ?·
        13 -> ?·
        g when g < 32 or g > 126 -> ?·
        g -> g
      end)
      |> List.to_string()

    IO.puts("""

    Ring Inscription
    ================
    generations run: #{result.generations_run}
    evaluations:     #{result.evaluations}
    fitness:         #{best_fitness} / #{max_fitness}

    target: #{@target}
    best:   #{best_string}
    """)
  end

  defp bigrams(chars) do
    Enum.chunk_every(chars, 2, 1, :discard)
  end

  defp animate(history) do
    Enum.each(history, fn snapshot ->
      string =
        snapshot.best_chromosome.genes
        |> Enum.map(fn
          10 -> ?·
          13 -> ?·
          g when g < 32 or g > 126 -> ?·
          g -> g
        end)
        |> List.to_string()

      IO.write("\r#{string}")
      Process.sleep(5)
    end)

    IO.puts("")
  end
end

RingInscription.run()
