defmodule Petri.Crossover.Permutation.OXTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Permutation
  alias Petri.Crossover.Permutation, as: Crossover

  @p0 %Permutation{genes: [1, 2, 3, 4, 5, 6, 7, 8, 9]}
  @p1 %Permutation{genes: [9, 8, 7, 6, 5, 4, 3, 2, 1]}

  @validity_seeds Enum.to_list(1..200)

  describe "ox/3 — offspring validity" do
    test "returns two Permutation offspring" do
      for seed <- @validity_seeds do
        seed(seed)
        assert match?({%Permutation{}, %Permutation{}}, Crossover.ox(@p0, @p1, []))
      end
    end

    test "both offspring are valid permutations" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.ox(@p0, @p1, [])

        assert Petri.Chromosome.valid?(o0), "seed=#{seed}: o0 is not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed}: o1 is not valid"
      end
    end

    test "offspring preserve the parent value set" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.ox(@p0, @p1, [])

        assert Enum.sort(o0.genes) == Enum.sort(@p0.genes),
               "seed=#{seed}: o0 value set mismatch"

        assert Enum.sort(o1.genes) == Enum.sort(@p1.genes),
               "seed=#{seed}: o1 value set mismatch"
      end
    end

    test "offspring length equals parent length" do
      for seed <- @validity_seeds do
        seed(seed)
        {o0, o1} = Crossover.ox(@p0, @p1, [])

        assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0)
        assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1)
      end
    end

    test "recombines for at least one seed" do
      recombined? =
        Enum.any?(@validity_seeds, fn seed ->
          seed(seed)
          {o0, o1} = Crossover.ox(@p0, @p1, [])

          o0.genes != @p0.genes and o0.genes != @p1.genes and
            o1.genes != @p0.genes and o1.genes != @p1.genes
        end)

      assert recombined?, "no seed produced a recombined offspring"
    end
  end

  describe "ox/3 — recombination behavior" do
    test "identical parents produce offspring equal to the parent" do
      seed(1)
      p = %Permutation{genes: [0, 1, 2, 3, 4, 5, 6, 7]}
      {o0, o1} = Crossover.ox(p, p, [])

      assert o0.genes == p.genes
      assert o1.genes == p.genes
    end
  end

  describe "ox/3 — determinism" do
    test "same seed produces identical offspring" do
      seed(42)
      a = Crossover.ox(@p0, @p1, [])
      seed(42)
      b = Crossover.ox(@p0, @p1, [])
      assert a == b
    end
  end

  describe "ox/3 — edge cases" do
    test "empty parents produce empty offspring" do
      assert Crossover.ox(%Permutation{genes: []}, %Permutation{genes: []}, []) ==
               {%Permutation{genes: []}, %Permutation{genes: []}}
    end

    test "single-element permutations produce single-element offspring" do
      assert Crossover.ox(%Permutation{genes: [0]}, %Permutation{genes: [0]}, []) ==
               {%Permutation{genes: [0]}, %Permutation{genes: [0]}}
    end

    test "two-element permutations preserve the value set" do
      {o0, o1} =
        Crossover.ox(%Permutation{genes: [0, 1]}, %Permutation{genes: [1, 0]}, [])

      assert Enum.sort(o0.genes) == [0, 1]
      assert Enum.sort(o1.genes) == [0, 1]
    end
  end

  describe "ox/3 — error cases" do
    test "raises ArgumentError when parents have different lengths" do
      assert_raise ArgumentError, ~r/length/, fn ->
        Crossover.ox(
          %Permutation{genes: [0, 1, 2]},
          %Permutation{genes: [0, 1]},
          []
        )
      end
    end
  end
end
