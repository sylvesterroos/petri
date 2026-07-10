defmodule Petri.Chromosome.Binary do
  @moduledoc """
  A chromosome whose genes are bits (0 or 1).

  Used for subset selection, e.g. feature selection where each bit
  indicates whether a feature is included.
  """

  defstruct genes: []

  defimpl Petri.Chromosome do
    alias Petri.Chromosome.Binary

    def length(%Binary{genes: genes}), do: Kernel.length(genes)

    def genes(%Binary{genes: genes}), do: genes

    def valid?(%Binary{genes: genes}) do
      Enum.all?(genes, fn g -> g in [0, 1] end)
    end
  end
end
