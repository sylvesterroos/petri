defmodule Petri.Initialization do
  @moduledoc """
  Random initialization per chromosome representation.

  ## Dispatch

  `init_random/2` takes a representation tag (`:permutation`, `:real`,
  `:binary`) and a map config, returning a **single** chromosome. Build
  a population by calling it repeatedly.

  ## Reproducibility

  Pass `seed: integer` to make initialization deterministic. This seeds the
  process-local `:rand` module (`:exsss`); for concurrent evaluation, seed
  per task.
  """

  alias Petri.Chromosome.Permutation

  @doc """
  Initialize a single random chromosome of the given representation.

  ## Options by representation

  ### `:permutation`
    - `:n` (required) — length; genes are a shuffle of `0..n-1`

  ### Common
    - `:seed` — integer seed for `:rand` (optional)

  ## Examples

      iex> c = Petri.Initialization.init_random(:permutation, %{n: 5})
      iex> Petri.Chromosome.valid?(c) and Petri.Chromosome.length(c) == 5
      true
  """
  def init_random(tag, config)

  def init_random(:permutation, config) do
    n = Map.fetch!(config, :n)
    %Permutation{genes: Enum.shuffle(0..(n - 1))}
  end
end
