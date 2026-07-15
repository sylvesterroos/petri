defmodule Petri.Mutation.BinaryTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Binary
  alias Petri.Mutation.Binary, as: Mutation

  describe "bit_flip/2" do
    test "returns a Binary chromosome" do
      seed(42)
      parent = %Binary{genes: [0, 1, 1, 0, 1]}
      child = Mutation.bit_flip(parent, %{mutation_per_gene_rate: 0.5})

      assert %Binary{} = child
    end

    test "produces valid offspring" do
      parent = %Binary{genes: [0, 1, 1, 0, 1, 0, 0, 1]}

      for s <- 1..200 do
        seed(s)
        child = Mutation.bit_flip(parent, %{mutation_per_gene_rate: 0.5})

        assert Petri.Chromosome.valid?(child), "seed=#{s}: invalid child"
      end
    end

    test "preserves chromosome length" do
      seed(42)
      parent = %Binary{genes: [0, 1, 1, 0, 1]}
      child = Mutation.bit_flip(parent, %{mutation_per_gene_rate: 0.5})

      assert Petri.Chromosome.length(child) == Petri.Chromosome.length(parent)
    end

    test "is deterministic with same seed" do
      parent = %Binary{genes: [0, 1, 1, 0, 1, 0, 0, 1]}
      cfg = %{mutation_per_gene_rate: 0.5}

      seed(42)
      a = Mutation.bit_flip(parent, cfg)
      seed(42)
      b = Mutation.bit_flip(parent, cfg)

      assert a == b
    end

    test "can produce a different child" do
      parent = %Binary{genes: [0, 1, 1, 0, 1, 0, 0, 1]}
      cfg = %{mutation_per_gene_rate: 0.5}

      seed(1)
      a = Mutation.bit_flip(parent, cfg)
      seed(2)
      b = Mutation.bit_flip(parent, cfg)

      refute a == b
    end

    test "no mutation when rate is 0" do
      parent = %Binary{genes: [0, 1, 1, 0, 1]}
      cfg = %{mutation_per_gene_rate: 0.0}

      seed(42)
      child = Mutation.bit_flip(parent, cfg)

      assert child.genes == parent.genes
    end

    test "full mutation flips every bit" do
      parent = %Binary{genes: [0, 0, 0, 0, 0]}
      cfg = %{mutation_per_gene_rate: 1.0}

      seed(42)
      child = Mutation.bit_flip(parent, cfg)

      assert child.genes == [1, 1, 1, 1, 1]
    end

    test "default rate is 1/length" do
      parent = %Binary{genes: [0, 1, 0, 1, 0, 1, 0, 1, 0, 1]}

      # With default rate (~0.1), most mutations should flip ~1 bit
      flips =
        Enum.map(1..200, fn s ->
          seed(s)
          child = Mutation.bit_flip(parent, %{})

          Enum.zip(child.genes, parent.genes)
          |> Enum.count(fn {a, b} -> a != b end)
        end)

      avg_flips = Enum.sum(flips) / length(flips)
      assert avg_flips < 3.0, "expected ~1 flip on average, got #{avg_flips}"
    end
  end
end
