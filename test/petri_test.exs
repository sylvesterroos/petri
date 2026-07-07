defmodule PetriTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Permutation
  alias Petri.Result

  describe "configure/1" do
    test "returns an ok tuple with a validated permutation config" do
      assert {:ok, config} =
               Petri.configure(%{
                 encoding: :permutation,
                 n: 8,
                 population_size: 20,
                 max_generations: 10
               })

      assert config.encoding == :permutation
      assert config.n == 8
      assert config.population_size == 20
      assert config.max_generations == 10
      assert config.selection == :sus
      assert config.crossover == :pmx
      assert config.mutation == :swap
      assert config.elitism == true
    end

    test "preserves explicit permutation operator choices" do
      assert {:ok, config} =
               Petri.configure(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10,
                 max_generations: 5,
                 selection: :tournament,
                 crossover: :ox,
                 mutation: :inversion,
                 elitism: false,
                 seed: 42
               })

      assert config.selection == :tournament
      assert config.crossover == :ox
      assert config.mutation == :inversion
      assert config.elitism == false
      assert config.seed == 42
    end

    test "returns an error tuple for a missing termination condition" do
      assert {:error, errors} =
               Petri.configure(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10
               })

      assert Zoi.prettify_errors(errors) == "at least one termination condition is required"
    end

    test "returns an error tuple for a missing required field" do
      assert {:error, _errors} =
               Petri.configure(%{
                 encoding: :permutation,
                 population_size: 10,
                 max_generations: 5
               })
    end

    test "returns an error tuple for an invalid permutation operator" do
      assert {:error, _errors} =
               Petri.configure(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10,
                 max_generations: 5,
                 crossover: :blx_alpha
               })
    end
  end

  describe "run/2" do
    test "returns a Result struct for a permutation problem" do
      result =
        Petri.run(
          &tsp_fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            seed: 42
          }
        )

      assert %Result{} = result
      {best_chromosome, best_fitness} = result.best
      assert %Permutation{} = best_chromosome
      assert is_float(best_fitness)
      assert length(result.history) == result.generations_run + 1

      for snapshot <- result.history do
        assert %Petri.Recorder{} = snapshot
        assert is_float(snapshot.max_fitness)
        assert is_float(snapshot.mean_fitness)
        assert is_float(snapshot.min_fitness)
        assert is_float(snapshot.diversity)
      end
    end

    test "accepts a config validated by configure/1" do
      {:ok, config} =
        Petri.configure(%{
          encoding: :permutation,
          n: 5,
          population_size: 10,
          max_generations: 3,
          seed: 42
        })

      result = Petri.run(&tsp_fitness/1, config)
      assert %Result{} = result
      assert result.generations_run == 3
      assert length(result.history) == 4
      assert result.evaluations == 10 + 3 * 9
    end

    test "validates a raw config map before running" do
      assert_raise ArgumentError, fn ->
        Petri.run(
          &tsp_fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10
          }
        )
      end
    end

    test "stops at max_generations" do
      result =
        Petri.run(
          &tsp_fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 7,
            seed: 42
          }
        )

      assert result.generations_run == 7
    end

    test "stops at fitness_threshold" do
      result =
        Petri.run(
          fn _ -> 1.0 end,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 100,
            fitness_threshold: 1.0,
            seed: 42
          }
        )

      assert result.generations_run == 0
      assert elem(result.best, 1) >= 1.0
    end

    test "is deterministic with the same seed" do
      config = %{
        encoding: :permutation,
        n: 5,
        population_size: 10,
        max_generations: 3,
        seed: 123
      }

      a = Petri.run(&tsp_fitness/1, config)
      b = Petri.run(&tsp_fitness/1, config)

      assert a == b
    end

    test "keeps all chromosomes valid throughout the run" do
      result =
        Petri.run(
          &tsp_fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 5,
            seed: 42
          }
        )

      {best_chromosome, _fitness} = result.best
      assert Petri.Chromosome.valid?(best_chromosome)
      assert Petri.Chromosome.length(best_chromosome) == 5
    end

    test "tracks the number of evaluations" do
      result =
        Petri.run(
          &tsp_fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 4,
            seed: 42
          }
        )

      # 10 initial evaluations plus 9 offspring per generation with elitism.
      assert result.evaluations == 10 + result.generations_run * 9
    end
  end

  describe "run/2 integration — tiny TSP" do
    test "finds the optimal tour for a 4-city symmetric instance" do
      # Cities arranged on a line at positions 0, 1, 2, 3.
      # The optimal tour visits them in order; distance = 6.
      # Fitness is the inverse of total tour length.
      distances = %{
        {0, 1} => 1.0,
        {0, 2} => 2.0,
        {0, 3} => 3.0,
        {1, 2} => 1.0,
        {1, 3} => 2.0,
        {2, 3} => 1.0
      }

      fitness_fn = fn %Permutation{genes: tour} ->
        total =
          Enum.chunk_every(tour ++ [hd(tour)], 2, 1, :discard)
          |> Enum.reduce(0.0, fn [a, b], acc ->
            key = if a < b, do: {a, b}, else: {b, a}
            acc + Map.fetch!(distances, key)
          end)

        1.0 / total
      end

      result =
        Petri.run(
          fitness_fn,
          %{
            encoding: :permutation,
            n: 4,
            population_size: 30,
            max_generations: 50,
            fitness_threshold: 1.0 / 6.0,
            seed: 7
          }
        )

      assert %Result{} = result
      {best_tour, best_fitness} = result.best
      assert %Permutation{} = best_tour
      assert best_fitness >= 1.0 / 6.0
      assert length(result.history) == result.generations_run + 1
    end
  end

  defp tsp_fitness(%Permutation{genes: genes}) do
    # Reward tours that put smaller numbers earlier. Not a real TSP, but
    # gives a consistent gradient for smoke tests.
    genes
    |> Enum.with_index()
    |> Enum.reduce(0.0, fn {gene, index}, acc ->
      acc + gene / (index + 1)
    end)
  end
end
