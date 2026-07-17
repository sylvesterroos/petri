defmodule Petri.EngineTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Permutation
  alias Petri.Chromosome.Integer, as: IntChr
  alias Petri.Engine
  alias Petri.Result

  describe "run/2" do
    test "integer encoding returns a Result struct" do
      result =
        Engine.run(
          fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end,
          [
            encoding: :integer,
            bounds: [{0, 10}, {0, 10}, {0, 10}],
            population_size: 10,
            max_generations: 3,
            seed: 42
          ]
        )

      assert %Result{} = result
    end

    test "integer encoding chromosomes stay valid" do
      result =
        Engine.run(
          fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end,
          [
            encoding: :integer,
            bounds: [{0, 10}, {0, 10}, {0, 10}],
            population_size: 10,
            max_generations: 5,
            seed: 42
          ]
        )

      {best_chromosome, _} = result.best
      assert %IntChr{} = best_chromosome
      assert Petri.Chromosome.valid?(best_chromosome)
    end

    test "integer encoding converges toward upper bounds" do
      fitness = fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end

      result =
        Engine.run(fitness, [
          encoding: :integer,
          bounds: [{0, 10}, {0, 10}, {0, 10}, {0, 10}, {0, 10}],
          population_size: 50,
          max_generations: 50,
          seed: 42
        ])

      {_best_chromosome, best_fitness} = result.best
      assert best_fitness >= 30, "expected convergence toward 50, got #{best_fitness}"
    end

    test "integer encoding with sbx and uniform mutation" do
      result =
        Engine.run(
          fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end,
          [
            encoding: :integer,
            bounds: [{0, 100}, {0, 100}],
            population_size: 30,
            max_generations: 30,
            crossover: :sbx,
            mutation: :uniform,
            seed: 42
          ]
        )

      {best_chromosome, _} = result.best
      assert Petri.Chromosome.valid?(best_chromosome)
    end

    test "integer encoding is deterministic with same seed" do
      config = [
        encoding: :integer,
        bounds: [{0, 10}, {0, 10}],
        population_size: 10,
        max_generations: 3,
        seed: 123
      ]

      a = Engine.run(fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end, config)
      b = Engine.run(fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end, config)

      assert a == b
    end

    test "integer encoding tracks evaluations" do
      result =
        Engine.run(
          fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end,
          [
            encoding: :integer,
            bounds: [{0, 10}],
            population_size: 10,
            max_generations: 3,
            elite_count: 1,
            seed: 42
          ]
        )

      assert result.evaluations == 10 + result.generations_run * 9
    end

    test "returns a Result struct" do
      result =
        Engine.run(
          &fitness/1,
          [
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            seed: 42
          ]
        )

      assert %Result{} = result
    end

    test "runs for max_generations" do
      result =
        Engine.run(
          &fitness/1,
          [
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 5,
            seed: 42
          ]
        )

      assert result.generations_run == 5
      assert length(result.history) == 6
    end

    test "stops at fitness_threshold" do
      result =
        Engine.run(
          fn _ -> 1.0 end,
          [
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 100,
            fitness_threshold: 1.0,
            seed: 42
          ]
        )

      assert result.generations_run == 0
      assert elem(result.best, 1) >= 1.0
    end

    test "all chromosomes stay valid" do
      result =
        Engine.run(
          &fitness/1,
          [
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            seed: 42
          ]
        )

      {best_chromosome, _fitness} = result.best

      assert Petri.Chromosome.valid?(best_chromosome)
      assert Petri.Chromosome.length(best_chromosome) == 5
    end

    test "tracks evaluations" do
      result =
        Engine.run(
          &fitness/1,
          [
            encoding: :permutation,
            n: 5,
            population_size: 10,
            max_generations: 3,
            elite_count: 1,
            seed: 42
          ]
        )

      assert result.evaluations == 10 + result.generations_run * 9
    end

    test "is deterministic with the same seed" do
      config = [
        encoding: :permutation,
        n: 5,
        population_size: 10,
        max_generations: 3,
        seed: 123
      ]

      a = Engine.run(&fitness/1, config)
      b = Engine.run(&fitness/1, config)

      assert a == b
    end

    test "raises on invalid config" do
      assert_raise ArgumentError, fn ->
        Engine.run(&fitness/1, [encoding: :permutation, population_size: 10])
      end
    end
  end

  defp fitness(%Permutation{genes: genes}) do
    List.first(genes, 0) / 1.0
  end
end
