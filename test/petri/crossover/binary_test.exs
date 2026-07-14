defmodule Petri.Crossover.BinaryTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Binary
  alias Petri.Crossover.Binary, as: Crossover

  # Multi-gene parents to exercise the recombination path
  @p0 %Binary{genes: [0, 1, 0, 1, 0, 0, 1, 1, 0, 1]}
  @p1 %Binary{genes: [1, 0, 1, 0, 1, 1, 0, 0, 1, 0]}

  @validity_seeds Enum.to_list(1..200)

  describe "single_point/3" do
    test "returns valid binary offspring" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.single_point(@p0, @p1, %{})
        assert Petri.Chromosome.valid?(o0), "seed=#{seed}: o0 not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed}: o1 not valid"
      end
    end

    test "offspring length equals parent length" do
      seed(1)
      {o0, o1} = Crossover.single_point(@p0, @p1, %{})
      assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0)
      assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1)
    end

    test "all genes are 0 or 1" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.single_point(@p0, @p1, %{})
        assert Enum.all?(o0.genes, &(&1 in [0, 1])), "seed=#{seed}: o0 has bad gene"
        assert Enum.all?(o1.genes, &(&1 in [0, 1])), "seed=#{seed}: o1 has bad gene"
      end
    end

    test "returns parents unchanged for length-1 chromosomes" do
      p0 = %Binary{genes: [1]}
      p1 = %Binary{genes: [0]}
      {o0, o1} = Crossover.single_point(p0, p1, %{})
      assert o0.genes == [1]
      assert o1.genes == [0]
    end

    test "is deterministic with the same seed" do
      seed(42)
      a = Crossover.single_point(@p0, @p1, %{})
      seed(42)
      b = Crossover.single_point(@p0, @p1, %{})
      assert a == b
    end

    test "recombines tails (offspring differ from both parents for at least one seed)" do
      recombined? =
        Enum.any?(@validity_seeds, fn seed ->
          seed(seed)
          {o0, _o1} = Crossover.single_point(@p0, @p1, %{})
          o0.genes != @p0.genes and o0.genes != @p1.genes
        end)

      assert recombined?,
             "no seed in #{inspect(@validity_seeds)} produced recombined offspring"
    end
  end

  describe "two_point/3" do
    test "returns valid binary offspring" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.two_point(@p0, @p1, %{})
        assert Petri.Chromosome.valid?(o0), "seed=#{seed}: o0 not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed}: o1 not valid"
      end
    end

    test "offspring length equals parent length" do
      seed(1)
      {o0, o1} = Crossover.two_point(@p0, @p1, %{})
      assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0)
      assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1)
    end

    test "all genes are 0 or 1" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.two_point(@p0, @p1, %{})
        assert Enum.all?(o0.genes, &(&1 in [0, 1])), "seed=#{seed}: o0 has bad gene"
        assert Enum.all?(o1.genes, &(&1 in [0, 1])), "seed=#{seed}: o1 has bad gene"
      end
    end

    test "returns parents unchanged for length-1 chromosomes" do
      p0 = %Binary{genes: [1]}
      p1 = %Binary{genes: [0]}
      {o0, o1} = Crossover.two_point(p0, p1, %{})
      assert o0.genes == [1]
      assert o1.genes == [0]
    end

    test "is deterministic with the same seed" do
      seed(42)
      a = Crossover.two_point(@p0, @p1, %{})
      seed(42)
      b = Crossover.two_point(@p0, @p1, %{})
      assert a == b
    end
  end

  describe "uniform/3" do
    test "returns valid binary offspring" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.uniform(@p0, @p1, %{})
        assert Petri.Chromosome.valid?(o0), "seed=#{seed}: o0 not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed}: o1 not valid"
      end
    end

    test "offspring length equals parent length" do
      seed(1)
      {o0, o1} = Crossover.uniform(@p0, @p1, %{})
      assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0)
      assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1)
    end

    test "all genes are 0 or 1" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.uniform(@p0, @p1, %{})
        assert Enum.all?(o0.genes, &(&1 in [0, 1])), "seed=#{seed}: o0 has bad gene"
        assert Enum.all?(o1.genes, &(&1 in [0, 1])), "seed=#{seed}: o1 has bad gene"
      end
    end

    test "is deterministic with the same seed" do
      seed(42)
      a = Crossover.uniform(@p0, @p1, %{})
      seed(42)
      b = Crossover.uniform(@p0, @p1, %{})
      assert a == b
    end

    test "genes can come from either parent" do
      p0_genes = @p0.genes
      p1_genes = @p1.genes

      some_recombined? =
        Enum.any?(@validity_seeds, fn seed ->
          seed(seed)
          {o0, o1} = Crossover.uniform(@p0, @p1, %{})

          # In at least one offspring, some genes match parent 0 and some match parent 1
          o0_from_p0 = Enum.zip(o0.genes, p0_genes) |> Enum.count(fn {o, p} -> o == p end)
          o0_from_p1 = Enum.zip(o0.genes, p1_genes) |> Enum.count(fn {o, p} -> o == p end)
          o1_from_p0 = Enum.zip(o1.genes, p0_genes) |> Enum.count(fn {o, p} -> o == p end)
          o1_from_p1 = Enum.zip(o1.genes, p1_genes) |> Enum.count(fn {o, p} -> o == p end)

          (o0_from_p0 > 0 and o0_from_p1 > 0) or (o1_from_p0 > 0 and o1_from_p1 > 0)
        end)

      assert some_recombined?,
             "uniform crossover never produced offspring with genes from both parents across #{inspect(@validity_seeds)} seeds"
    end
  end
end
