defmodule Petri.Mutation.Permutation.InversionTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Permutation
  alias Petri.Mutation.Permutation, as: PermMutation

  describe "inversion/2" do
    test "returns a valid permutation" do
      seed(123)
      parent = %Permutation{genes: [0, 1, 2, 3, 4]}
      child = PermMutation.inversion(parent, %{})

      assert Petri.Chromosome.valid?(child)
      assert Petri.Chromosome.length(child) == 5
      assert Enum.sort(Petri.Chromosome.genes(child)) == [0, 1, 2, 3, 4]
    end

    test "leaves a length-1 permutation unchanged" do
      seed(42)
      parent = %Permutation{genes: [0]}
      child = PermMutation.inversion(parent, %{})

      assert Petri.Chromosome.genes(child) == [0]
    end

    test "leaves an empty permutation unchanged" do
      seed(42)
      parent = %Permutation{genes: []}
      child = PermMutation.inversion(parent, %{})

      assert Petri.Chromosome.genes(child) == []
    end

    test "is deterministic with the same seed" do
      parent = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}

      seed(7)
      first = PermMutation.inversion(parent, %{})
      seed(7)
      second = PermMutation.inversion(parent, %{})

      assert Petri.Chromosome.genes(first) == Petri.Chromosome.genes(second)
    end

    test "can produce a different child with a different seed" do
      parent = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}

      seed(1)
      first = PermMutation.inversion(parent, %{})
      seed(2)
      second = PermMutation.inversion(parent, %{})

      assert Petri.Chromosome.genes(first) != Petri.Chromosome.genes(second)
    end

    test "reverses a contiguous segment" do
      parent = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}

      # With a fixed seed we assert the specific segment is reversed.
      seed(123)
      child = PermMutation.inversion(parent, %{})

      # Find the reversed segment by locating where order differs.
      mismatches =
        Enum.zip(Petri.Chromosome.genes(parent), Petri.Chromosome.genes(child))
        |> Enum.with_index()
        |> Enum.reject(fn {{a, b}, _i} -> a == b end)
        |> Enum.map(fn {_, i} -> i end)

      assert length(mismatches) >= 2

      [first | _] = mismatches
      last = List.last(mismatches)

      reversed_segment =
        Petri.Chromosome.genes(parent)
        |> Enum.slice(first..last)
        |> Enum.reverse()

      assert Enum.slice(Petri.Chromosome.genes(child), first..last) == reversed_segment
    end
  end
end
