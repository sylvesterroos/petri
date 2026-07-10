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
    result =
      Petri.run(fitness, %{
        encoding: :binary,
        length: @n_features,
        population_size: 80,
        max_generations: 80,
        seed: 17,
        selection: :tournament,
        tournament_size: 3,
        elite_count: 3,
        crossover: :uniform,
        mutation: :bit_flip,
        mutation_rate: 0.4,
        mutation_per_gene_rate: 1.0 / @n_features
      })

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
  end
end

FeatureSelection.run()
