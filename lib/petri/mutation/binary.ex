defmodule Petri.Mutation.Binary do
  alias Petri.Chromosome.Binary

  @doc """
  Bit-flip mutation. Flips each bit independently with probability
  `mutation_per_gene_rate` (default 1 / length, so ~1 bit flips
  per mutation event on average).
  """
  def bit_flip(%Binary{genes: genes} = chromosome, config) do
    per_gene_rate = Map.get(config, :mutation_per_gene_rate, 1.0 / max(length(genes), 1))

    new_genes =
      Enum.map(genes, fn
        0 -> if :rand.uniform() <= per_gene_rate, do: 1, else: 0
        1 -> if :rand.uniform() <= per_gene_rate, do: 0, else: 1
      end)

    %{chromosome | genes: new_genes}
  end
end
