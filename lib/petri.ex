defmodule Petri do
  @moduledoc """
  A multi-representation genetic algorithm library.

  Petri supports four chromosome encodings:

    * `Petri.Chromosome.Real` — continuous values with per-gene bounds
    * `Petri.Chromosome.Permutation` — integer permutations (e.g. TSP tours)
    * `Petri.Chromosome.Binary` — bit strings for subset selection
    * `Petri.Chromosome.Integer` — discrete integers with per-gene bounds

  Each encoding has its own crossover and mutation operators. Selection,
  termination, and the generational engine work across all encodings.

  ## Quick start

      iex> fitness = fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end
      iex> result = Petri.run(fitness, [
      ...>   encoding: :binary, length: 10,
      ...>   population_size: 20, max_generations: 50, seed: 42
      ...> ])
      iex> %Petri.Result{} = result
      iex> {_chrom, f} = result.best
      iex> f
      10

  ## Running the examples

  Four standalone `.exs` scripts in the `examples/` directory demonstrate
  each encoding on a realistic problem:

      elixir examples/tsp.exs               # Berlin52 TSP (permutation)
      elixir examples/ml_hyperparams.exs    # Hyperparameter tuning (real)
      elixir examples/feature_selection.exs # Feature subset selection (binary)
      elixir examples/ring_inscription.exs  # String evolution (integer)
  """

  alias Petri.Config
  alias Petri.Engine

  @doc """
  Runs a genetic algorithm.

  `fitness_fn` is a function `(chromosome -> fitness)` where higher fitness
  is better. The GA maximizes.

  `config` is a keyword list. Required fields depend on the encoding.
  See `Petri.Config.parse/1` for the full schema.

  ## Config (binary encoding)

      iex> fitness = fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end
      iex> result = Petri.run(fitness, [
      ...>   encoding: :binary, length: 8,
      ...>   population_size: 30, max_generations: 100, seed: 99
      ...> ])
      iex> {_chrom, f} = result.best
      iex> f
      8

  ## Config (real encoding)

      iex> fitness = fn %Petri.Chromosome.Real{genes: [x, y]} -> -(x*x + y*y) end
      iex> result = Petri.run(fitness, [
      ...>   encoding: :real, bounds: [{-5.0, 5.0}, {-5.0, 5.0}],
      ...>   selection: :tournament,
      ...>   population_size: 50, max_generations: 50, seed: 1
      ...> ])
      iex> {_chrom, r2} = result.best
      iex> r2 < 0.0
      true

  ## Config (permutation encoding)

      iex> fitness = fn %Petri.Chromosome.Permutation{genes: g} ->
      iex>   # Count adjacent pairs in ascending order
      ...>   g |> Enum.chunk_every(2, 1, :discard) |> Enum.count(fn [a, b] -> a < b end)
      ...> end
      iex> result = Petri.run(fitness, [
      ...>   encoding: :permutation, n: 20,
      ...>   selection: :tournament,
      ...>   population_size: 50, max_generations: 100, seed: 1,
      ...>   crossover: :ox, mutation: :swap
      ...> ])
      iex> {_chrom, p_fit} = result.best
      iex> p_fit > 10
      true

  ## Config (integer encoding)

      iex> fitness = fn c -> Petri.Chromosome.genes(c) |> Enum.sum() end
      iex> result = Petri.run(fitness, [
      ...>   encoding: :integer, bounds: [{0, 10}, {0, 10}],
      ...>   selection: :tournament,
      ...>   population_size: 50, max_generations: 50, seed: 1
      ...> ])
      iex> {_chrom, i_fit} = result.best
      iex> i_fit > 10
      true
  """
  def run(fitness_fn, config) do
    Engine.run(fitness_fn, config)
  end

  @doc """
  Validates a config without running the GA.

  Returns `{:ok, config}` or `{:error, reasons}`.

  ## Example

      iex> {:ok, config} = Petri.configure([
      ...>   encoding: :binary, length: 8,
      ...>   population_size: 20, max_generations: 10
      ...> ])
      iex> config[:encoding]
      :binary

      iex> {:error, err} = Petri.configure([
      ...>   encoding: :binary, crossover: :blx_alpha,
      ...>   length: 8, population_size: 20, max_generations: 10
      ...> ])
      iex> is_list(err)
      true
  """
  def configure(config) do
    Config.parse(config)
  end
end
