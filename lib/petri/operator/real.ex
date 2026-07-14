defmodule Petri.Operator.Real do
  @moduledoc """
  Dispatches configuration atoms to concrete real-valued operators.
  """

  alias Petri.Crossover.Real, as: Crossover
  alias Petri.Mutation.Real, as: Mutation

  @doc "Returns the crossover function for the given real-valued operator name."
  def crossover(:blx_alpha), do: &Crossover.blx_alpha/3
  def crossover(:sbx), do: &Crossover.sbx/3

  @doc "Returns the mutation function for the given real-valued operator name."
  def mutation(:gaussian), do: &Mutation.gaussian/2
  def mutation(:uniform), do: &Mutation.uniform/2
end
