defmodule Petri.Chromosome.RealTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Real

  describe "Petri.Chromosome protocol" do
    test "length/1 returns number of genes" do
      c = %Real{genes: [1.0, 5.0, 3.0], bounds: [{0.0, 10.0}, {0.0, 10.0}, {0.0, 10.0}]}
      assert Petri.Chromosome.length(c) == 3
    end

    test "genes/1 returns the gene list" do
      genes = [1.0, 5.0, 3.0]
      c = %Real{genes: genes, bounds: [{0.0, 10.0}, {0.0, 10.0}, {0.0, 10.0}]}
      assert Petri.Chromosome.genes(c) == genes
    end

    test "valid?/1 accepts genes within bounds" do
      c = %Real{genes: [1.0, 5.0, 10.0], bounds: [{0.0, 10.0}, {0.0, 10.0}, {0.0, 10.0}]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 accepts genes at exact bounds" do
      c = %Real{genes: [0.0, 10.0], bounds: [{0.0, 10.0}, {0.0, 10.0}]}
      assert Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects gene below lower bound" do
      c = %Real{genes: [-0.1, 5.0], bounds: [{0.0, 10.0}, {0.0, 10.0}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects gene above upper bound" do
      c = %Real{genes: [5.0, 10.1], bounds: [{0.0, 10.0}, {0.0, 10.0}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects non-numeric genes" do
      c = %Real{genes: [1.0, :atom, 3.0], bounds: [{0.0, 10.0}, {0.0, 10.0}, {0.0, 10.0}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects when bounds count mismatches genes" do
      c = %Real{genes: [1.0, 5.0], bounds: [{0.0, 10.0}]}
      refute Petri.Chromosome.valid?(c)
    end

    test "valid?/1 rejects empty chromosome" do
      c = %Real{genes: [], bounds: []}
      refute Petri.Chromosome.valid?(c)
    end
  end
end
