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
end
