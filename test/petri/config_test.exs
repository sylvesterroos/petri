defmodule Petri.ConfigTest do
  use ExUnit.Case, async: true

  alias Petri.Config

  describe "parse/1" do
    test "accepts a valid permutation config" do
      assert {:ok, config} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 10,
                 population_size: 50,
                 max_generations: 100,
                 crossover: :pmx,
                 mutation: :swap
               })

      assert config.encoding == :permutation
      assert config.n == 10
      assert config.population_size == 50
      assert config.max_generations == 100
      assert config.crossover == :pmx
      assert config.mutation == :swap
    end

    test "applies defaults" do
      assert {:ok, config} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 10,
                 population_size: 10,
                 max_generations: 5
               })

      assert config.selection == :sus
      assert config.crossover == :pmx
      assert config.mutation == :swap
      assert config.elite_count == 2
      assert config.crossover_rate == 0.9
      assert config.mutation_rate == 0.1
    end

    test "requires encoding" do
      assert {:error, _errors} = Config.parse(%{population_size: 10, max_generations: 5})
    end

    test "requires population_size" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 5,
                 max_generations: 5
               })
    end

    test "rejects non-positive population_size" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 0,
                 max_generations: 5
               })
    end

    test "rejects unknown encoding" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :matrix,
                 n: 5,
                 population_size: 10,
                 max_generations: 5
               })
    end

    test "rejects invalid selection operator" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10,
                 max_generations: 5,
                 selection: :random_guessing
               })
    end

    test "requires at least one termination condition" do
      assert {:error, errors} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10
               })

      assert Zoi.prettify_errors(errors) == "at least one termination condition is required"
    end
  end

  describe "operator compatibility via discriminated union" do
    test "permits all valid permutation operators" do
      for crossover <- [:ox, :pmx, :cx],
          mutation <- [:swap, :insert, :inversion] do
        assert {:ok, _config} =
                 Config.parse(%{
                   encoding: :permutation,
                   n: 5,
                   population_size: 10,
                   max_generations: 5,
                   crossover: crossover,
                   mutation: mutation
                 })
      end
    end

    test "permits all valid real operators" do
      for crossover <- [:blx_alpha, :sbx],
          mutation <- [:gaussian, :uniform] do
        assert {:ok, _config} =
                 Config.parse(%{
                   encoding: :real,
                   bounds: [{0.0, 1.0}],
                   population_size: 10,
                   max_generations: 5,
                   crossover: crossover,
                   mutation: mutation
                 })
      end
    end

    test "permits all valid binary operators" do
      for crossover <- [:single_point, :two_point, :uniform],
          mutation <- [:bit_flip] do
        assert {:ok, _config} =
                 Config.parse(%{
                   encoding: :binary,
                   length: 20,
                   population_size: 10,
                   max_generations: 5,
                   crossover: crossover,
                   mutation: mutation
                 })
      end
    end

    test "rejects real crossover with permutation encoding" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10,
                 max_generations: 5,
                 crossover: :blx_alpha
               })
    end

    test "rejects binary mutation with permutation encoding" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :permutation,
                 n: 5,
                 population_size: 10,
                 max_generations: 5,
                 mutation: :bit_flip
               })
    end

    test "rejects permutation crossover with real encoding" do
      assert {:error, _errors} =
               Config.parse(%{
                 encoding: :real,
                 bounds: [{0.0, 1.0}],
                 population_size: 10,
                 max_generations: 5,
                 crossover: :pmx
               })
    end
  end
end
