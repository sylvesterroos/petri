defmodule Petri.Chromosome.BinaryTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Binary

  describe "Petri.Chromosome protocol" do
    test "length/1 returns number of genes" do
      c = %Binary{genes: [0, 1, 1]}
      assert Petri.Chromosome.length(c) == 3
    end

    test "genes/1 returns the gene list" do
      c = %Binary{genes: [0, 1, 1]}
      assert Petri.Chromosome.genes(c) == [0, 1, 1]
    end

    test "valid?/1 accepts valid bit string" do
      c = %Binary{genes: [0, 1, 1, 0]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts all zeros" do
      c = %Binary{genes: [0, 0, 0]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts all ones" do
      c = %Binary{genes: [1, 1, 1]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects value of 2" do
      c = %Binary{genes: [0, 2, 1]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects negative value" do
      c = %Binary{genes: [0, -1, 1]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects float value" do
      c = %Binary{genes: [0, 0.5, 1]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects empty chromosome" do
      c = %Binary{genes: []}
      refute Petri.Chromosome.valid?(c)
    end
  end
end
