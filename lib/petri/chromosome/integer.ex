defmodule Petri.Chromosome.Integer do
  @moduledoc """
  An integer-encoded chromosome with per-gene bounds.

  Each gene is an integer clamped to `{lo, hi}`. Use this when your search
  space is discrete but not permutation-constrained — integer parameters,
  byte sequences, categorical indices.

  ## Example

      iex> chrom = %Petri.Chromosome.Integer{genes: [3, 7], bounds: [{0, 9}, {0, 9}]}
      iex> Petri.Chromosome.length(chrom)
      2
      iex> Petri.Chromosome.genes(chrom)
      [3, 7]
      iex> Petri.Chromosome.valid?(chrom)
      true

  Compatible crossover operators: `:blx_alpha`, `:two_point`, `:sbx`.
  Compatible mutation operators: `:gaussian`, `:uniform`.
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
