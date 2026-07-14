defmodule Petri.Mutation.Permutation do
  @moduledoc "Mutation operators for permutation chromosomes."
  alias Petri.Chromosome.Permutation

  @doc "Reverses a random segment of the permutation."
  def inversion(%Permutation{genes: genes} = chromosome, _config) do
    if length(genes) <= 1 do
      chromosome
    else
      [a, b] = Enum.sort(Enum.take_random(0..(length(genes) - 1), 2))

      %{
        chromosome
        | genes:
            genes
            |> Enum.take(a)
            |> Kernel.++(Enum.slice(genes, a..b) |> Enum.reverse())
            |> Kernel.++(Enum.drop(genes, b + 1))
      }
    end
  end

  @doc "Swaps two random positions."
  def swap(%Permutation{genes: genes} = chromosome, _config) do
    if length(genes) <= 1 do
      chromosome
    else
      [a, b] = Enum.sort(Enum.take_random(0..(length(genes) - 1), 2))

      %{
        chromosome
        | genes:
            genes
            |> List.replace_at(a, Enum.at(genes, b))
            |> List.replace_at(b, Enum.at(genes, a))
      }
    end
  end

  @doc "Moves a random element to a new position."
  def insert(%Permutation{genes: genes} = chromosome, _config) do
    n = length(genes)

    if n <= 1 do
      chromosome
    else
      from = :rand.uniform(n) - 1
      to = :rand.uniform(n) - 1
      value = Enum.at(genes, from)
      without = List.delete_at(genes, from)
      inserted = List.insert_at(without, to, value)
      %{chromosome | genes: inserted}
    end
  end
end
