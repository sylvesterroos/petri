defmodule Petri.Mutation.RealTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Real
  alias Petri.Mutation.Real, as: RealMutation

  describe "gaussian/2" do
    test "perturbs genes when per_gene_rate is 1.0" do
      seed(42)
      parent = %Real{genes: [0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}]}

      child =
        RealMutation.gaussian(
          parent,
          config(:real, [mutation_per_gene_rate: 1.0, gaussian_sigma: 0.5])
        )

      assert Petri.Chromosome.valid?(child)
      assert Petri.Chromosome.length(child) == 2

      child_genes = Petri.Chromosome.genes(child)
      assert child_genes != parent.genes
    end

    test "leaves genes unchanged when per_gene_rate is 0.0" do
      seed(42)
      parent = %Real{genes: [0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}]}

      child =
        RealMutation.gaussian(
          parent,
          config(:real, [mutation_per_gene_rate: 0.0, gaussian_sigma: 0.5])
        )

      assert Petri.Chromosome.valid?(child)
      assert Petri.Chromosome.genes(child) == parent.genes
    end

    test "keeps genes within bounds across many seeds" do
      parent = %Real{genes: [0.5, 0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}, {0.0, 1.0}]}

      for s <- 1..50 do
        seed(s)

        child =
          RealMutation.gaussian(
            parent,
            config(:real, [mutation_per_gene_rate: 1.0, gaussian_sigma: 0.5])
          )

        assert Petri.Chromosome.valid?(child)
      end
    end

    test "is deterministic with the same seed" do
      parent = %Real{genes: [0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}]}
      conf = config(:real, [mutation_per_gene_rate: 1.0, gaussian_sigma: 0.5])

      seed(7)
      first = RealMutation.gaussian(parent, conf)

      seed(7)
      second = RealMutation.gaussian(parent, conf)

      assert Petri.Chromosome.genes(first) == Petri.Chromosome.genes(second)
    end

    test "clamps perturbed genes to bounds" do
      seed(42)
      parent = %Real{genes: [0.5], bounds: [{0.0, 1.0}]}

      child =
        RealMutation.gaussian(
          parent,
          config(:real, [mutation_per_gene_rate: 1.0, gaussian_sigma: 10.0])
        )

      child_genes = Petri.Chromosome.genes(child)
      assert hd(child_genes) >= 0.0
      assert hd(child_genes) <= 1.0
    end
  end

  describe "uniform/2" do
    test "replaces genes within bounds when per_gene_rate is 1.0" do
      seed(42)
      parent = %Real{genes: [0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}]}
      child = RealMutation.uniform(parent, config(:real, [mutation_per_gene_rate: 1.0]))

      assert Petri.Chromosome.valid?(child)
      assert Petri.Chromosome.length(child) == 2

      child_genes = Petri.Chromosome.genes(child)
      assert child_genes != parent.genes
    end

    test "leaves genes unchanged when per_gene_rate is 0.0" do
      seed(42)
      parent = %Real{genes: [0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}]}
      child = RealMutation.uniform(parent, config(:real, [mutation_per_gene_rate: 0.0]))

      assert Petri.Chromosome.valid?(child)
      assert Petri.Chromosome.genes(child) == parent.genes
    end

    test "is deterministic with the same seed" do
      parent = %Real{genes: [0.5, 0.5], bounds: [{0.0, 1.0}, {0.0, 1.0}]}
      conf = config(:real, [mutation_per_gene_rate: 1.0])

      seed(7)
      first = RealMutation.uniform(parent, conf)

      seed(7)
      second = RealMutation.uniform(parent, conf)

      assert Petri.Chromosome.genes(first) == Petri.Chromosome.genes(second)
    end
  end
end
