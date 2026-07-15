defmodule Petri.Chromosome.Integer do
  @moduledoc """
  """

  defstruct genes: [], bounds: []

  defimpl Petri.Chromosome do
    alias Petri.Chromosome.Integer

    def length(%Integer{genes: genes}), do: Kernel.length(genes)

    def genes(%Integer{genes: genes}), do: genes

    def valid?(%Integer{genes: genes, bounds: bounds}) when is_list(genes) and is_list(bounds) do
      Kernel.length(genes) > 0 and
        Kernel.length(genes) == Kernel.length(bounds) and
        Enum.zip([genes, bounds])
        |> Enum.all?(fn {gene, bounds} ->
          check_validity(gene, bounds)
        end)
    end

    defp check_validity(gene, {lo, hi}) do
      [
        lo <= hi,
        is_integer(gene),
        gene >= lo,
        gene <= hi
      ]
      |> Enum.all?()
    end
  end
end
