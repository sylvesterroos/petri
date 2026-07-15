defmodule Petri.Mutation.Integer do
  @moduledoc "Mutation operators for integer chromosomes."
  alias Petri.Chromosome.Integer

  @doc "Gaussian mutation. Perturbs each gene with probability `mutation_per_gene_rate`."
  def gaussian(%Integer{genes: genes, bounds: bounds} = chromosome, config) do
    sigma = config.gaussian_sigma
    per_gene_rate = config.mutation_per_gene_rate

    new_genes =
      Enum.zip(genes, bounds)
      |> Enum.map(fn {g, {lo, hi}} ->
        if :rand.uniform() <= per_gene_rate do
          perturb = rand_normal() * sigma * (hi - lo)
          clamp(g + perturb, lo, hi) |> round()
        else
          g
        end
      end)

    %{chromosome | genes: new_genes}
  end

  @doc "Uniform mutation. Replaces each gene with a random value in its bounds."
  def uniform(%Integer{genes: genes, bounds: bounds} = chromsome, config) do
    per_gene_rate = config.mutation_per_gene_rate

    new_genes =
      Enum.zip(genes, bounds)
      |> Enum.map(fn {g, {lo, hi}} ->
        if :rand.uniform() <= per_gene_rate do
          lo + :rand.uniform(hi - lo + 1) - 1
        else
          g
        end
      end)

    %{chromsome | genes: new_genes}
  end

  defp rand_normal do
    u1 = :rand.uniform()
    u2 = :rand.uniform()
    :math.sqrt(-2.0 * :math.log(max(u1, 1.0e-10))) * :math.cos(2.0 * :math.pi() * u2)
  end

  defp clamp(x, lo, hi) do
    x |> max(lo) |> min(hi)
  end
end
