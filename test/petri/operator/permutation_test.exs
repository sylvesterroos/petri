defmodule Petri.Operator.PermutationTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Permutation
  alias Petri.Operator.Permutation, as: Operator

  describe "crossover/1" do
    test "returns a function for :ox" do
      seed(1)
      p0 = %Permutation{genes: [0, 1, 2, 3, 4]}
      p1 = %Permutation{genes: [4, 3, 2, 1, 0]}

      fun = Operator.crossover(:ox)
      {o0, o1} = fun.(p0, p1, [])

      assert %Permutation{} = o0
      assert %Permutation{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :pmx" do
      seed(1)
      p0 = %Permutation{genes: [0, 1, 2, 3, 4]}
      p1 = %Permutation{genes: [4, 3, 2, 1, 0]}

      fun = Operator.crossover(:pmx)
      {o0, o1} = fun.(p0, p1, [])

      assert %Permutation{} = o0
      assert %Permutation{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :cx" do
      seed(1)
      p0 = %Permutation{genes: [0, 1, 2, 3, 4]}
      p1 = %Permutation{genes: [4, 3, 2, 1, 0]}

      fun = Operator.crossover(:cx)
      {o0, o1} = fun.(p0, p1, [])

      assert %Permutation{} = o0
      assert %Permutation{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end
  end

  describe "mutation/1" do
    test "returns a function for :inversion" do
      seed(1)
      parent = %Permutation{genes: [0, 1, 2, 3, 4]}

      fun = Operator.mutation(:inversion)
      child = fun.(parent, [])

      assert %Permutation{} = child
      assert Petri.Chromosome.valid?(child)
    end

    test "returns a function for :swap" do
      seed(1)
      parent = %Permutation{genes: [0, 1, 2, 3, 4]}

      fun = Operator.mutation(:swap)
      child = fun.(parent, [])

      assert %Permutation{} = child
      assert Petri.Chromosome.valid?(child)
    end

    test "returns a function for :insert" do
      seed(1)
      parent = %Permutation{genes: [0, 1, 2, 3, 4]}

      fun = Operator.mutation(:insert)
      child = fun.(parent, [])

      assert %Permutation{} = child
      assert Petri.Chromosome.valid?(child)
    end
  end
end
