defmodule Petri.TestHelpers do
  @moduledoc """
  Shared helpers for Petri tests.

  Individual operators no longer seed the process-local RNG themselves;
  the engine seeds once at the start of a run. Tests that call operators
  directly must seed explicitly when they want reproducible draws.
  """

  @doc """
  Seeds the process-local `:rand` module with the given integer.
  """
  def seed(n) when is_integer(n) do
    Petri.RNG.maybe_seed(%{seed: n})
  end

  @doc """
  Returns a base config map for the given encoding, merged with overrides.

  Use in operator tests that need a config with the right keys present.
  """
  def config(encoding, overrides \\ %{})

  def config(:real, overrides) do
    Map.merge(
      %{
        blx_alpha_param: 0.5,
        sbx_eta: 2.0,
        gaussian_sigma: 0.1,
        mutation_per_gene_rate: 1.0,
        crossover_rate: 0.9,
        mutation_rate: 0.1
      },
      overrides
    )
  end

  def config(:permutation, overrides) do
    Map.merge(
      %{
        crossover_rate: 0.9,
        mutation_rate: 0.1
      },
      overrides
    )
  end

  def config(:binary, overrides) do
    Map.merge(
      %{
        crossover_rate: 0.9,
        mutation_rate: 0.1
      },
      overrides
    )
  end
end
