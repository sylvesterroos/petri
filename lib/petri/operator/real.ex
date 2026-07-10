defmodule Petri.Operator.Real do
  @moduledoc """
  Dispatches configuration atoms to concrete real-valued operators.
  """

  alias Petri.Crossover.Real, as: Crossover
  alias Petri.Mutation.Real, as: Mutation

  def crossover(:blx_alpha), do: &Crossover.blx_alpha/3
  def crossover(:sbx), do: &Crossover.sbx/3

  def mutation(:gaussian), do: &Mutation.gaussian/2
  def mutation(:uniform), do: &Mutation.uniform/2
end
