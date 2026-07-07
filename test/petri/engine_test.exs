defmodule Petri.EngineTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Permutation
  alias Petri.Engine
  alias Petri.Result

  describe "run/2" do
    test "returns a Result struct" do
      result =
        Engine.run(
          &fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            seed: 42
          }
        )

      assert %Result{} = result
    end

    test "runs for max_generations" do
      result =
        Engine.run(
          &fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 5,
            seed: 42
          }
        )

      assert result.generations_run == 5
      assert length(result.history) == 6
    end

    test "stops at fitness_threshold" do
      result =
        Engine.run(
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

    test "all chromosomes stay valid" do
      result =
        Engine.run(
          &fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            seed: 42
          }
        )

      {best_chromosome, _fitness} = result.best

      assert Petri.Chromosome.valid?(best_chromosome)
      assert Petri.Chromosome.length(best_chromosome) == 5
    end

    test "tracks evaluations" do
      result =
        Engine.run(
          &fitness/1,
          %{
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            seed: 42
          }
        )

      assert result.evaluations == 10 + result.generations_run * 9
    end

    test "is deterministic with the same seed" do
      config = %{
        encoding: :permutation,
        n: 5,
        population_size: 10,
        max_generations: 3,
        seed: 123
      }

      a = Engine.run(&fitness/1, config)
      b = Engine.run(&fitness/1, config)

      assert a == b
    end

    test "raises on invalid config" do
      assert_raise ArgumentError, fn ->
        Engine.run(&fitness/1, %{encoding: :permutation, population_size: 10})
      end
    end
  end

  defp fitness(%Permutation{genes: genes}) do
    List.first(genes, 0) / 1.0
  end
end
