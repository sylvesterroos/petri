defmodule Petri.Crossover.Real do
  @moduledoc "Crossover operators for real-valued chromosomes."
  alias Petri.Chromosome.Real

  @doc """
  Blend Crossover (BLX-α).

  For each gene position, offspring are sampled uniformly from
  `[min - α·d, max + α·d]` where `d = |p1 - p2|` is the parent distance.
  Clamped to per-gene bounds. α defaults to 0.5.

  See Eshelman & Schaffer 1993.
  """
  def blx_alpha(%Real{genes: p0, bounds: bounds}, %Real{genes: p1, bounds: _}, config) do
    alpha = config[:blx_alpha_param]

    {c0, c1} =
      Enum.zip([p0, p1, bounds])
      |> Stream.map(fn {g0, g1, {lo, hi}} ->
        {blx_gene(g0, g1, lo, hi, alpha), blx_gene(g0, g1, lo, hi, alpha)}
      end)
      |> Enum.unzip()

    {%Real{genes: c0, bounds: bounds}, %Real{genes: c1, bounds: bounds}}
  end

  defp blx_gene(g0, g1, lo, hi, alpha) do
    min_g = min(g0, g1)
    max_g = max(g0, g1)
    d = max_g - min_g

    lower = max(min_g - alpha * d, lo)
    upper = min(max_g + alpha * d, hi)

    lower + :rand.uniform() * (upper - lower)
  end

  @doc """
  Simulated Binary Crossover (SBX).

  Mimics the offspring distribution of single-point crossover for
  real-valued genes. The spread factor η controls how far offspring
  can stray from parents (higher η = closer to parents). Default η = 2.

  See Deb & Agrawal 1995.
  """
  def sbx(%Real{genes: p0, bounds: bounds}, %Real{genes: p1, bounds: _}, config) do
    eta = config[:sbx_eta]

    {c0, c1} =
      Enum.zip([p0, p1, bounds])
      |> Stream.map(fn {g0, g1, {lo, hi}} ->
        sbx_genes(g0, g1, lo, hi, eta)
      end)
      |> Enum.unzip()

    {%Real{genes: c0, bounds: bounds}, %Real{genes: c1, bounds: bounds}}
  end

  defp sbx_genes(g0, g1, lo, hi, eta) do
    u = :rand.uniform()

    beta =
      if u <= 0.5 do
        :math.pow(2.0 * u, 1.0 / (eta + 1.0))
      else
        :math.pow(1.0 / (2.0 * (1.0 - u)), 1.0 / (eta + 1.0))
      end

    c0 = clamp(0.5 * ((1.0 + beta) * g0 + (1.0 - beta) * g1), lo, hi)
    c1 = clamp(0.5 * ((1.0 - beta) * g0 + (1.0 + beta) * g1), lo, hi)

    {c0, c1}
  end

  defp clamp(x, lo, hi) do
    x |> max(lo) |> min(hi)
  end
end
