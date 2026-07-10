defmodule Petri.Operator.Permutation do
  @moduledoc """
  Dispatches configuration atoms to concrete permutation operators.
  """

  alias Petri.Crossover.Permutation, as: Crossover
  alias Petri.Mutation.Permutation, as: Mutation

  @doc """
  Returns the crossover function for the given permutation operator name.
  """
  def crossover(:ox), do: &Crossover.ox/3
  def crossover(:pmx), do: &Crossover.pmx/3
  def crossover(:cx), do: &Crossover.cx/3

  @doc """
  Returns the mutation function for the given permutation operator name.
  """
  def mutation(:inversion), do: &Mutation.inversion/2
  def mutation(:swap), do: &Mutation.swap/2
  def mutation(:insert), do: &Mutation.insert/2
end
