defmodule Petri.Chromosome.Permutation do
  @moduledoc """
  A chromosome whose genes are a permutation of integers, e.g. a TSP tour.
  Validity requires every gene to be an integer with no duplicates.
  """

  defstruct genes: []

  defimpl Petri.Chromosome do
    alias Petri.Chromosome.Permutation

    def length(%Permutation{genes: genes}), do: Kernel.length(genes)

    def genes(%Permutation{genes: genes}), do: genes

    def valid?(%Permutation{genes: genes}) do
      genes != [] and
        Enum.all?(genes, &is_integer/1) and
        Kernel.length(genes) == Kernel.length(Enum.uniq(genes))
    end
  end
end
