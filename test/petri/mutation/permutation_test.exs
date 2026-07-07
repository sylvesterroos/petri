defmodule Petri.Mutation.PermutationTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Permutation
  alias Petri.Mutation.Permutation, as: PermMutation

  describe "swap/2" do
    test "returns a valid permutation" do
      seed(123)
      parent = %Permutation{genes: [0, 1, 2, 3, 4]}
      child = PermMutation.swap(parent, %{})

      assert Petri.Chromosome.valid?(child)
      assert Petri.Chromosome.length(child) == 5
      assert Enum.sort(Petri.Chromosome.genes(child)) == [0, 1, 2, 3, 4]
    end

    test "leaves a length-1 permutation unchanged" do
      seed(42)
      parent = %Permutation{genes: [0]}
      child = PermMutation.swap(parent, %{})

      assert Petri.Chromosome.genes(child) == [0]
    end

    test "is deterministic with the same seed" do
      parent = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}

      seed(7)
      first = PermMutation.swap(parent, %{})
      seed(7)
      second = PermMutation.swap(parent, %{})

      assert Petri.Chromosome.genes(first) == Petri.Chromosome.genes(second)
    end

    test "can produce a different child with a different seed" do
      parent = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}

      seed(1)
      first = PermMutation.swap(parent, %{})
      seed(2)
      second = PermMutation.swap(parent, %{})

      assert Petri.Chromosome.genes(first) != Petri.Chromosome.genes(second)
    end

    test "swaps exactly two positions" do
      seed(99)
      parent = %Permutation{genes: [0, 1, 2, 3, 4]}
      child = PermMutation.swap(parent, %{})

      parent_genes = Petri.Chromosome.genes(parent)
      child_genes = Petri.Chromosome.genes(child)

      mismatches =
        Enum.zip(parent_genes, child_genes)
        |> Enum.count(fn {a, b} -> a != b end)

      assert mismatches == 2
    end
  end
end
