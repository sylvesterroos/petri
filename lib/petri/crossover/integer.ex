defmodule Petri.Crossover.Integer do
  @moduledoc "Crossover operators for integer chromosomes."
  alias Petri.Chromosome.Integer

  @doc "BLX-α crossover for integer chromosomes."
  def blx_alpha(%Integer{genes: p0, bounds: bounds}, %Integer{genes: p1, bounds: _}, config) do
    alpha = config.blx_alpha_param

    {c0, c1} =
      Enum.zip([p0, p1, bounds])
      |> Stream.map(fn {g0, g1, {lo, hi}} ->
        {blx_gene(g0, g1, lo, hi, alpha) |> round(), blx_gene(g0, g1, lo, hi, alpha) |> round()}
      end)
      |> Enum.unzip()

    {%Integer{genes: c0, bounds: bounds}, %Integer{genes: c1, bounds: bounds}}
  end

  defp blx_gene(g0, g1, lo, hi, alpha) do
    min_g = min(g0, g1)
    max_g = max(g0, g1)
    d = max_g - min_g

    lower = max(min_g - alpha * d, lo)
    upper = min(max_g + alpha * d, hi)

    lower + :rand.uniform() * (upper - lower)
  end

  @doc "SBX crossover for integer chromosomes."
  def sbx(%Integer{genes: p0, bounds: bounds}, %Integer{genes: p1, bounds: _}, config) do
    eta = config.sbx_eta

    {c0, c1} =
      Enum.zip([p0, p1, bounds])
      |> Stream.map(fn {g0, g1, {lo, hi}} ->
        sbx_genes(g0, g1, lo, hi, eta)
      end)
      |> Enum.unzip()

    {%Integer{genes: c0, bounds: bounds}, %Integer{genes: c1, bounds: bounds}}
  end

  defp sbx_genes(g0, g1, lo, hi, eta) do
    u = :rand.uniform()

    beta =
      if u <= 0.5 do
        :math.pow(2.0 * u, 1.0 / (eta + 1.0))
      else
        :math.pow(1.0 / (2.0 * (1.0 - u)), 1.0 / (eta + 1.0))
      end

    c0 = (0.5 * ((1.0 + beta) * g0 + (1.0 - beta) * g1)) |> round() |> clamp(lo, hi)
    c1 = (0.5 * ((1.0 - beta) * g0 + (1.0 + beta) * g1)) |> round() |> clamp(lo, hi)

    {c0, c1}
  end

  defp clamp(x, lo, hi) do
    x |> max(lo) |> min(hi)
  end
end
