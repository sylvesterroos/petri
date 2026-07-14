defmodule Petri.Mutation.Real do
  alias Petri.Chromosome.Real

  @doc """
  Gaussian mutation. Adds zero-mean Gaussian noise to each gene
  independently with probability `mutation_per_gene_rate` (default 1.0).
  Each perturbation is scaled by `gaussian_sigma` (default 0.1) times
  the gene's bound range. Output is clamped to bounds.
  """
  def gaussian(%Real{genes: genes, bounds: bounds} = chromosome, config) do
    sigma = config.gaussian_sigma
    per_gene_rate = config.mutation_per_gene_rate

    new_genes =
      Enum.zip(genes, bounds)
      |> Enum.map(fn {g, {lo, hi}} ->
        if :rand.uniform() <= per_gene_rate do
          perturb = rand_normal() * sigma * (hi - lo)
          clamp(g + perturb, lo, hi)
        else
          g
        end
      end)

    %{chromosome | genes: new_genes}
  end

  @doc """
  Uniform mutation. Replaces each gene with uniform random in [lo, hi]
  with probability `mutation_per_gene_rate` (default 1 / length).
  """
  def uniform(%Real{genes: genes, bounds: bounds} = chromosome, config) do
    per_gene_rate = config.mutation_per_gene_rate

    new_genes =
      Enum.zip(genes, bounds)
      |> Enum.map(fn {g, {lo, hi}} ->
        if :rand.uniform() <= per_gene_rate do
          lo + :rand.uniform() * (hi - lo)
        else
          g
        end
      end)

    %{chromosome | genes: new_genes}
  end

  # Box-Muller transform for standard normal samples.
  defp rand_normal do
    u1 = :rand.uniform()
    u2 = :rand.uniform()
    :math.sqrt(-2.0 * :math.log(max(u1, 1.0e-10))) * :math.cos(2.0 * :math.pi() * u2)
  end

  defp clamp(x, lo, hi) do
    x |> max(lo) |> min(hi)
  end
end
