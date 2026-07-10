defmodule Petri.Operator.Binary do
  @moduledoc """
  Dispatches configuration atoms to concrete binary operators.
  """

  alias Petri.Crossover.Binary, as: Crossover
  alias Petri.Mutation.Binary, as: Mutation

  def crossover(:single_point), do: &Crossover.single_point/3
  def crossover(:two_point), do: &Crossover.two_point/3
  def crossover(:uniform), do: &Crossover.uniform/3

  def mutation(:bit_flip), do: &Mutation.bit_flip/2
end
