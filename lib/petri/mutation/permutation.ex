defmodule Petri.Mutation.Permutation do
  alias Petri.Chromosome.Permutation

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
