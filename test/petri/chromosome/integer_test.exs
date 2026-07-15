defmodule Petri.Chromosome.IntegerTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Integer

  describe "Petri.Chromosome protocol" do
    test "length/1 returns number of genes" do
      c = %Integer{genes: [1, 5, 3], bounds: [{0, 10}, {0, 10}, {0, 10}]}
      assert Petri.Chromosome.length(c) == 3
    end

    test "genes/1 returns the gene list" do
      genes = [1, 5, 3]
      c = %Integer{genes: genes, bounds: [{0, 10}, {0, 10}, {0, 10}]}
      assert Petri.Chromosome.genes(c) == genes
    end

    test "valid?/1 accepts integer genes within bounds" do
      c = %Integer{genes: [1, 5, 10], bounds: [{0, 10}, {0, 10}, {0, 10}]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts genes at exact bounds" do
      c = %Integer{genes: [0, 10], bounds: [{0, 10}, {0, 10}]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects gene below lower bound" do
      c = %Integer{genes: [-1, 5], bounds: [{0, 10}, {0, 10}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects gene above upper bound" do
      c = %Integer{genes: [5, 11], bounds: [{0, 10}, {0, 10}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects float genes" do
      c = %Integer{genes: [1.5, 5, 3], bounds: [{0, 10}, {0, 10}, {0, 10}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects when bounds count mismatches genes" do
      c = %Integer{genes: [1, 5], bounds: [{0, 10}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects empty chromosome" do
      c = %Integer{genes: [], bounds: []}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts negative bounds" do
      c = %Integer{genes: [-5, 0, 3], bounds: [{-10, 10}, {-10, 10}, {-10, 10}]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts single-element bounds (lo == hi)" do
      c = %Integer{genes: [5], bounds: [{5, 5}]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects when lo == hi but gene differs" do
      c = %Integer{genes: [6], bounds: [{5, 5}]}
      refute Petri.Chromosome.valid?(c)
    end
  end
end
