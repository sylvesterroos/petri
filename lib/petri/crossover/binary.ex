defmodule Petri.Crossover.Binary do
  @moduledoc "Crossover operators for binary chromosomes."
  alias Petri.Chromosome.Binary

  @doc """
  Single-point crossover. Pick one random cut point and swap tails.
  """
  def single_point(%Binary{genes: p0}, %Binary{genes: p1}, _config) do
    n = length(p0)

    if n < 2 do
      {%Binary{genes: p0}, %Binary{genes: p1}}
    else
      cp = :rand.uniform(n - 1)
      c0 = Enum.take(p0, cp) ++ Enum.drop(p1, cp)
      c1 = Enum.take(p1, cp) ++ Enum.drop(p0, cp)
      {%Binary{genes: c0}, %Binary{genes: c1}}
    end
  end

  @doc """
  Two-point crossover. Pick two cut points and swap the middle segment.
  """
  def two_point(%Binary{genes: p0}, %Binary{genes: p1}, _config) do
    n = length(p0)

    if n < 2 do
      {%Binary{genes: p0}, %Binary{genes: p1}}
    else
      [a, b] = Enum.sort(Enum.take_random(0..(n - 1), 2))

      c0 =
        Enum.take(p0, a) ++
          Enum.slice(p1, a..b) ++
          Enum.drop(p0, b + 1)

      c1 =
        Enum.take(p1, a) ++
          Enum.slice(p0, a..b) ++
          Enum.drop(p1, b + 1)

      {%Binary{genes: c0}, %Binary{genes: c1}}
    end
  end

  @doc """
  Uniform crossover. Each gene is independently taken from either parent
  with equal probability.
  """
  def uniform(%Binary{genes: p0}, %Binary{genes: p1}, _config) do
    {c0, c1} =
      Enum.zip(p0, p1)
      |> Enum.map(fn {g0, g1} ->
        if :rand.uniform() <= 0.5 do
          {g0, g1}
        else
          {g1, g0}
        end
      end)
      |> Enum.unzip()

    {%Binary{genes: c0}, %Binary{genes: c1}}
  end
end
