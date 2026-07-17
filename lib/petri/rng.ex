defmodule Petri.RNG do
  @moduledoc """
  Seeding policy for Petri's stochastic operators.
  """

  @doc """
  Seed the process-local `:rand` if `:seed` is present in `config`.
  """
  def maybe_seed(config) do
    case Keyword.get(config, :seed) do
      nil -> :ok
      seed -> :rand.seed(:exsss, seed)
    end
  end
end
