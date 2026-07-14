defmodule Petri.Chromosome.Real do
  @moduledoc """
  A chromosome whose genes are real-valued floats with per-gene bounds.

  `bounds` is a list of `{lo, hi}` tuples, one per gene. Crossover and
  mutation operators clamp output to these bounds.
  """

  defstruct genes: [], bounds: []

  defimpl Petri.Chromosome do
    alias Petri.Chromosome.Real

    def length(%Real{genes: genes}), do: Kernel.length(genes)

    def genes(%Real{genes: genes}), do: genes

    def valid?(%Real{genes: genes, bounds: bounds}) do
      genes != [] and
        Enum.count(genes) == Enum.count(bounds) and
        Enum.all?(genes, &is_number/1) and
        (bounds == [] or
           Enum.zip(genes, bounds)
           |> Enum.all?(fn {g, {lo, hi}} -> g >= lo and g <= hi end))
    end
  end
end
