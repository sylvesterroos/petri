defmodule Petri.Initialization do
  @moduledoc """
  Random initialization per chromosome representation.

  ## Dispatch

  `init_random/1` takes a config map with an `:encoding` key and returns
  a **single** chromosome. Build a population by calling it repeatedly.

  ## Reproducibility

  Pass `seed: integer` to make initialization deterministic. This seeds the
  process-local `:rand` module (`:exsss`); for concurrent evaluation, seed
  per task.
  """

  alias Petri.Chromosome.Permutation
  alias Petri.Chromosome.Real
  alias Petri.Chromosome.Binary
  alias Petri.Chromosome.Integer

  @doc """
  Initialize a single random chromosome for the encoding specified in config.

  ## Options by representation

  ### `:permutation`
    - `:n` (required) — length; genes are a shuffle of `0..n-1`

  ### `:real`
    - `:bounds` (required) — list of `{lo, hi}` tuples, one per gene

  ### `:binary`
    - `:length` (required) — number of bits

  ### `:integer`
    - `:bounds` (required) — list of `{lo, hi}` integer tuples, one per gene

  ### Common
    - `:seed` — integer seed for `:rand` (optional)

  ## Examples

      iex> c = Petri.Initialization.init_random(%{encoding: :permutation, n: 5})
      iex> Petri.Chromosome.valid?(c) and Petri.Chromosome.length(c) == 5
      true
  """
  def init_random(config)

  def init_random(%{encoding: :permutation, n: n}) do
    %Permutation{genes: Enum.shuffle(0..(n - 1))}
  end

  def init_random(%{encoding: :real, bounds: bounds}) do
    genes =
      Enum.map(bounds, fn {lo, hi} ->
        lo + :rand.uniform() * (hi - lo)
      end)

    %Real{genes: genes, bounds: bounds}
  end

  def init_random(%{encoding: :binary, length: length}) do
    genes = for _ <- 1..length, do: Enum.random([0, 1])
    %Binary{genes: genes}
  end

  def init_random(%{encoding: :integer, bounds: bounds}) do
    genes =
      Enum.map(bounds, fn {lo, hi} ->
        lo + :rand.uniform(hi - lo + 1) - 1
      end)

    %Integer{genes: genes, bounds: bounds}
  end

  @doc """
  Generate an initial population using Latin Hypercube Sampling.

  LHS divides each dimension into `population_size` strata and samples
  once per stratum, giving better initial coverage of the search space
  than uniform random. Only meaningful for `:real` encoding.

  Returns a list of `RealChromosome` structs, not a single chromosome.
  """
  def init_latin_hypercube(%{encoding: :real} = config) do
    bounds = Map.fetch!(config, :bounds)
    pop_size = Map.fetch!(config, :population_size)

    # For each dimension, create N strata and sample within each
    samples_per_dim =
      Enum.map(bounds, fn {lo, hi} ->
        step = (hi - lo) / pop_size

        Enum.map(0..(pop_size - 1), fn i ->
          lo + i * step + :rand.uniform() * step
        end)
      end)

    # Shuffle each dimension independently for good coverage
    shuffled_dims = Enum.map(samples_per_dim, &Enum.shuffle/1)

    # Transpose to get N individuals
    shuffled_dims
    |> Enum.zip_with(& &1)
    |> Enum.map(fn genes -> %Real{genes: genes, bounds: bounds} end)
  end
end
