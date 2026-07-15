defmodule Petri.Mutation.IntegerTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Integer, as: IntChr
  alias Petri.Mutation.Integer, as: Mutation

  describe "gaussian/2" do
    test "returns an Integer chromosome" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      child = Mutation.gaussian(parent, config(:integer))

      assert %IntChr{} = child
    end

    test "produces valid offspring" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      for s <- 1..200 do
        seed(s)
        child = Mutation.gaussian(parent, config(:integer))

        assert Petri.Chromosome.valid?(child), "seed=#{s}: invalid child"
      end
    end

    test "offspring genes are integers" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      for s <- 1..200 do
        seed(s)
        child = Mutation.gaussian(parent, config(:integer))

        assert Enum.all?(child.genes, &is_integer/1), "seed=#{s}: non-integer gene"
      end
    end

    test "preserves chromosome length" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      child = Mutation.gaussian(parent, config(:integer))

      assert Petri.Chromosome.length(child) == Petri.Chromosome.length(parent)
    end

    test "is deterministic with same seed" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      config = config(:integer)

      seed(42)
      a = Mutation.gaussian(parent, config)
      seed(42)
      b = Mutation.gaussian(parent, config)

      assert a == b
    end

    test "can produce a different child with different seed" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      config = config(:integer)

      seed(1)
      a = Mutation.gaussian(parent, config)
      seed(2)
      b = Mutation.gaussian(parent, config)

      # With high mutation rate, very unlikely to be identical
      refute a == b
    end

    test "low sigma keeps genes close to originals" do
      parent = %IntChr{genes: [10, 10, 10], bounds: [{0, 100}, {0, 100}, {0, 100}]}
      config = config(:integer, %{gaussian_sigma: 0.01})

      for s <- 1..100 do
        seed(s)
        child = Mutation.gaussian(parent, config)

        Enum.zip(child.genes, parent.genes)
        |> Enum.each(fn {g, orig} ->
          assert abs(g - orig) <= 10,
                 "seed=#{s}: gene drifted too far: #{orig} -> #{g}"
        end)
      end
    end

    test "no mutation when rate is 0" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      config = config(:integer, %{mutation_per_gene_rate: 0.0})

      seed(42)
      child = Mutation.gaussian(parent, config)

      assert child.genes == parent.genes
    end

    test "respects bounds even with high sigma" do
      parent = %IntChr{genes: [5, 5], bounds: [{0, 10}, {0, 10}]}
      config = config(:integer, %{gaussian_sigma: 10.0})

      for s <- 1..200 do
        seed(s)
        child = Mutation.gaussian(parent, config)

        assert Enum.all?(child.genes, fn g -> g >= 0 and g <= 10 end),
               "seed=#{s}: out of bounds: #{inspect(child.genes)}"
      end
    end

    test "uses defaults when config keys are missing" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      child = Mutation.gaussian(parent, config(:integer))

      assert Petri.Chromosome.valid?(child)
    end
  end

  describe "uniform/2" do
    test "returns an Integer chromosome" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      child = Mutation.uniform(parent, config(:integer))

      assert %IntChr{} = child
    end

    test "produces valid offspring" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      for s <- 1..200 do
        seed(s)
        child = Mutation.uniform(parent, config(:integer))

        assert Petri.Chromosome.valid?(child), "seed=#{s}: invalid child"
      end
    end

    test "offspring genes are integers" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      for s <- 1..200 do
        seed(s)
        child = Mutation.uniform(parent, config(:integer))

        assert Enum.all?(child.genes, &is_integer/1), "seed=#{s}: non-integer gene"
      end
    end

    test "preserves chromosome length" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      child = Mutation.uniform(parent, config(:integer))

      assert Petri.Chromosome.length(child) == Petri.Chromosome.length(parent)
    end

    test "is deterministic with same seed" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      config = config(:integer)

      seed(42)
      a = Mutation.uniform(parent, config)
      seed(42)
      b = Mutation.uniform(parent, config)

      assert a == b
    end

    test "respects bounds" do
      parent = %IntChr{genes: [5, 5], bounds: [{3, 7}, {3, 7}]}
      config = config(:integer)

      for s <- 1..200 do
        seed(s)
        child = Mutation.uniform(parent, config)

        assert Enum.all?(child.genes, fn g -> g >= 3 and g <= 7 end),
               "seed=#{s}: out of bounds: #{inspect(child.genes)}"
      end
    end

    test "no mutation when rate is 0" do
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      config = config(:integer, %{mutation_per_gene_rate: 0.0})

      seed(42)
      child = Mutation.uniform(parent, config)

      assert child.genes == parent.genes
    end

    test "full mutation can produce any valid integer in bounds" do
      # With very many trials, every value in a small range should appear
      parent = %IntChr{genes: [5], bounds: [{0, 10}]}
      config = config(:integer)

      seen =
        Enum.map(1..1000, fn s ->
          seed(s)
          [g] = Mutation.uniform(parent, config).genes
          g
        end)
        |> MapSet.new()

      # Should see at least most values in 0..10
      assert MapSet.size(seen) >= 8, "only saw: #{inspect(MapSet.to_list(seen))}"
    end

    test "uses default rate when not specified" do
      seed(42)

      parent = %IntChr{
        genes: [5, 10, 15, 20, 25],
        bounds: [{0, 30}, {0, 30}, {0, 30}, {0, 30}, {0, 30}]
      }

      child = Mutation.uniform(parent, config(:integer))

      assert Petri.Chromosome.valid?(child)
    end
  end
end
