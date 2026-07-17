defmodule Petri.Crossover.PermutationTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Permutation
  alias Petri.Crossover.Permutation, as: Crossover

  @p0 %Permutation{genes: [5, 0, 3, 8, 1, 7, 2, 6, 4]}
  @p1 %Permutation{genes: [1, 4, 7, 2, 6, 0, 8, 3, 5]}

  @validity_seeds Enum.to_list(1..200)

  describe "pmx/3 — offspring validity (property: holds for every cut)" do
    test "returns a two-element tuple of offspring for every seed" do
      for seed <- @validity_seeds do
        seed(seed)
        assert match?({%Permutation{}, %Permutation{}}, Crossover.pmx(@p0, @p1, []))
      end
    end

    test "both offspring are valid permutations" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.pmx(@p0, @p1, [])

        assert Petri.Chromosome.valid?(o0), "seed=#{seed}: o0 is not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed}: o1 is not valid"
      end
    end

    test "offspring genes are permutations of the parents' value set" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.pmx(@p0, @p1, [])

        assert Enum.sort(o0.genes) == Enum.sort(@p0.genes),
               "seed=#{seed}: o0 genes are not a permutation of p0"

        assert Enum.sort(o1.genes) == Enum.sort(@p1.genes),
               "seed=#{seed}: o1 genes are not a permutation of p1"
      end
    end

    test "offspring length equals parent length" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.pmx(@p0, @p1, [])

        assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0),
               "seed=#{seed}: o0 length mismatch"

        assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1),
               "seed=#{seed}: o1 length mismatch"
      end
    end

    test "recombines for at least one seed (not a copy-only operator)" do
      recombined? =
        Enum.any?(@validity_seeds, fn seed ->
          seed(seed)
          {o0, _o1} = Crossover.pmx(@p0, @p1, [])
          o0.genes != @p0.genes and o0.genes != @p1.genes
        end)

      assert recombined?, "no seed in 1..200 produced a recombined offspring"
    end
  end

  describe "pmx/3 — recombination behavior" do
    test "identical parents produce offspring equal to the parent" do
      seed(1)
      p = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7]}
      {o0, o1} = Crossover.pmx(p, p, [])

      assert o0.genes == p.genes
      assert o1.genes == p.genes
    end
  end

  describe "pmx/3 — determinism" do
    test "same seed produces identical offspring" do
      seed(42)
      a = Crossover.pmx(@p0, @p1, [])
      seed(42)
      b = Crossover.pmx(@p0, @p1, [])
      assert a == b
    end
  end

  describe "pmx/3 — edge cases" do
    test "empty parents produce empty offspring" do
      assert Crossover.pmx(%Permutation{genes: []}, %Permutation{genes: []}, []) ==
               {%Permutation{genes: []}, %Permutation{genes: []}}
    end

    test "single-element permutations produce single-element offspring" do
      assert Crossover.pmx(%Permutation{genes: [0]}, %Permutation{genes: [0]}, []) ==
               {%Permutation{genes: [0]}, %Permutation{genes: [0]}}
    end

    test "two-element permutations preserve the value set" do
      {o0, o1} =
        Crossover.pmx(%Permutation{genes: [0, 1]}, %Permutation{genes: [1, 0]}, [])

      assert Enum.sort(o0.genes) == [0, 1]
      assert Enum.sort(o1.genes) == [0, 1]
    end
  end

  describe "pmx/3 — error cases" do
    test "raises ArgumentError when parents have different lengths" do
      assert_raise ArgumentError, ~r/length/, fn ->
        Crossover.pmx(
          %Permutation{genes: [0, 1, 2]},
          %Permutation{genes: [0, 1]},
          []
        )
      end
    end

    test "raises ArgumentError on empty-vs-nonempty length mismatch" do
      assert_raise ArgumentError, ~r/length/, fn ->
        Crossover.pmx(%Permutation{genes: []}, %Permutation{genes: [0]}, [])
      end
    end
  end

  describe "cx/3 — offspring validity" do
    @cx_validity_seeds Enum.to_list(1..200)

    test "returns a two-element tuple of offspring for every seed" do
      for seed <- @cx_validity_seeds do
        seed(seed)
        assert match?({%Permutation{}, %Permutation{}}, Crossover.cx(@p0, @p1, []))
      end
    end

    test "both offspring are valid permutations" do
      for seed <- @cx_validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.cx(@p0, @p1, [])

        assert Petri.Chromosome.valid?(o0), "seed=#{seed}: o0 is not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed}: o1 is not valid"
      end
    end

    test "returns parents unchanged for length-1 chromosomes" do
      p0 = %Permutation{genes: [0]}
      p1 = %Permutation{genes: [0]}
      {o0, o1} = Crossover.cx(p0, p1, [])
      assert o0.genes == [0]
      assert o1.genes == [0]
    end
  end
end
