defmodule Petri.Operator.Integer do
  @moduledoc """
  """

  alias Petri.Crossover.Integer, as: Crossover
  alias Petri.Mutation.Integer, as: Mutation

  @doc "Returns the crossover function for the given integer operator name."
  def crossover(:blx_alpha), do: &Crossover.blx_alpha/3
  def crossover(:two_point), do: &Crossover.two_point/3
  def crossover(:sbx), do: &Crossover.sbx/3

  @doc "Returns the mutation function for the given integer operator name."
  def mutation(:gaussian), do: &Mutation.gaussian/2
  def mutation(:uniform), do: &Mutation.uniform/2
end
