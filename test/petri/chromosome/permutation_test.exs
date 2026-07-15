defmodule Petri.Chromosome.PermutationTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Permutation

  describe "Petri.Chromosome protocol" do
    test "length/1 returns number of genes" do
      c = %Permutation{genes: [0, 2, 1]}
      assert Petri.Chromosome.length(c) == 3
    end

    test "genes/1 returns the gene list" do
      c = %Permutation{genes: [0, 2, 1]}
      assert Petri.Chromosome.genes(c) == [0, 2, 1]
    end

    test "valid?/1 accepts valid permutation" do
      c = %Permutation{genes: [0, 2, 1]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts single element" do
      c = %Permutation{genes: [0]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects duplicate genes" do
      c = %Permutation{genes: [0, 1, 1]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects non-integer genes" do
      c = %Permutation{genes: [0.0, 1.0, 2.0]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects empty chromosome" do
      c = %Permutation{genes: []}
      refute Petri.Chromosome.valid?(c)
    end
  end
end
