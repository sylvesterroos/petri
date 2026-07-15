defmodule Petri.Crossover.IntegerTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Integer, as: IntChr
  alias Petri.Crossover.Integer, as: Crossover

  @p0 %IntChr{genes: [1, 5, 10, 3, 8], bounds: [{0, 20}, {0, 20}, {0, 20}, {0, 20}, {0, 20}]}
  @p1 %IntChr{genes: [3, 8, 15, 7, 2], bounds: [{0, 20}, {0, 20}, {0, 20}, {0, 20}, {0, 20}]}

  @seeds Enum.to_list(1..200)

  describe "blx_alpha/3" do
    test "returns two Integer chromosomes" do
      seed(42)
      {o0, o1} = Crossover.blx_alpha(@p0, @p1, config(:integer))

      assert %IntChr{} = o0
      assert %IntChr{} = o1
    end

    test "offspring are valid for many seeds" do
      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.blx_alpha(@p0, @p1, config(:integer))

        assert Petri.Chromosome.valid?(o0), "seed=#{s}: o0 invalid"
        assert Petri.Chromosome.valid?(o1), "seed=#{s}: o1 invalid"
      end
    end

    test "offspring genes are integers" do
      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.blx_alpha(@p0, @p1, config(:integer))

        assert Enum.all?(o0.genes, &is_integer/1), "seed=#{s}: o0 has non-integer gene"
        assert Enum.all?(o1.genes, &is_integer/1), "seed=#{s}: o1 has non-integer gene"
      end
    end

    test "offspring length equals parent length" do
      seed(42)
      {o0, o1} = Crossover.blx_alpha(@p0, @p1, config(:integer))

      assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0)
      assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1)
    end

    test "recombines for at least one seed (not copy-only)" do
      recombined? =
        Enum.any?(@seeds, fn s ->
          seed(s)
          {o0, _} = Crossover.blx_alpha(@p0, @p1, config(:integer))
          o0.genes != @p0.genes and o0.genes != @p1.genes
        end)

      assert recombined?, "no seed in 1..200 produced a recombined offspring"
    end

    test "is deterministic with same seed" do
      seed(42)
      a = Crossover.blx_alpha(@p0, @p1, config(:integer))
      seed(42)
      b = Crossover.blx_alpha(@p0, @p1, config(:integer))

      assert a == b
    end

    test "identical parents produce identical offspring" do
      seed(1)
      {o0, o1} = Crossover.blx_alpha(@p0, @p0, config(:integer))

      assert o0.genes == @p0.genes
      assert o1.genes == @p0.genes
    end

    test "empty parents produce empty offspring" do
      empty = %IntChr{genes: [], bounds: []}
      {o0, o1} = Crossover.blx_alpha(empty, empty, config(:integer))

      assert o0.genes == []
      assert o1.genes == []
    end

    test "offspring respect tight bounds" do
      p0 = %IntChr{genes: [0, 10], bounds: [{0, 10}, {0, 10}]}
      p1 = %IntChr{genes: [1, 9], bounds: [{0, 10}, {0, 10}]}

      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.blx_alpha(p0, p1, config(:integer))

        assert Enum.all?(o0.genes, fn g -> g >= 0 and g <= 10 end),
               "seed=#{s}: o0 out of bounds: #{inspect(o0.genes)}"

        assert Enum.all?(o1.genes, fn g -> g >= 0 and g <= 10 end),
               "seed=#{s}: o1 out of bounds: #{inspect(o1.genes)}"
      end
    end

    test "works with default config" do
      seed(42)
      {o0, _} = Crossover.blx_alpha(@p0, @p1, config(:integer))
      assert %IntChr{} = o0
      assert Petri.Chromosome.valid?(o0)
    end
  end

  describe "two_point/3" do
    test "swaps one contiguous segment without inventing gene values" do
      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.two_point(@p0, @p1, config(:integer))

        assert Enum.zip([o0.genes, o1.genes, @p0.genes, @p1.genes])
               |> Enum.all?(fn {g0, g1, p0, p1} -> {g0, g1} in [{p0, p1}, {p1, p0}] end)
      end
    end

    test "preserves chromosome bounds" do
      seed(42)
      {o0, o1} = Crossover.two_point(@p0, @p1, config(:integer))

      assert o0.bounds == @p0.bounds
      assert o1.bounds == @p0.bounds
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns length-one parents unchanged" do
      p0 = %IntChr{genes: [1], bounds: [{0, 10}]}
      p1 = %IntChr{genes: [9], bounds: [{0, 10}]}

      assert Crossover.two_point(p0, p1, config(:integer)) == {p0, p1}
    end

    test "is deterministic with the same seed" do
      seed(42)
      a = Crossover.two_point(@p0, @p1, config(:integer))
      seed(42)
      b = Crossover.two_point(@p0, @p1, config(:integer))

      assert a == b
    end
  end

  describe "sbx/3" do
    test "returns two Integer chromosomes" do
      seed(42)
      {o0, o1} = Crossover.sbx(@p0, @p1, config(:integer))

      assert %IntChr{} = o0
      assert %IntChr{} = o1
    end

    test "offspring are valid for many seeds" do
      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.sbx(@p0, @p1, config(:integer))

        assert Petri.Chromosome.valid?(o0), "seed=#{s}: o0 invalid"
        assert Petri.Chromosome.valid?(o1), "seed=#{s}: o1 invalid"
      end
    end

    test "offspring genes are integers" do
      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.sbx(@p0, @p1, config(:integer))

        assert Enum.all?(o0.genes, &is_integer/1), "seed=#{s}: o0 has non-integer gene"
        assert Enum.all?(o1.genes, &is_integer/1), "seed=#{s}: o1 has non-integer gene"
      end
    end

    test "offspring length equals parent length" do
      seed(42)
      {o0, o1} = Crossover.sbx(@p0, @p1, config(:integer))

      assert Petri.Chromosome.length(o0) == Petri.Chromosome.length(@p0)
      assert Petri.Chromosome.length(o1) == Petri.Chromosome.length(@p1)
    end

    test "recombines for at least one seed" do
      recombined? =
        Enum.any?(@seeds, fn s ->
          seed(s)
          {o0, _} = Crossover.sbx(@p0, @p1, config(:integer))
          o0.genes != @p0.genes and o0.genes != @p1.genes
        end)

      assert recombined?, "no seed in 1..200 produced a recombined offspring"
    end

    test "is deterministic with same seed" do
      seed(42)
      a = Crossover.sbx(@p0, @p1, config(:integer))
      seed(42)
      b = Crossover.sbx(@p0, @p1, config(:integer))

      assert a == b
    end

    test "identical parents produce identical offspring" do
      seed(1)
      {o0, o1} = Crossover.sbx(@p0, @p0, config(:integer))

      assert o0.genes == @p0.genes
      assert o1.genes == @p0.genes
    end

    test "offspring respect tight bounds" do
      p0 = %IntChr{genes: [0, 10], bounds: [{0, 10}, {0, 10}]}
      p1 = %IntChr{genes: [1, 9], bounds: [{0, 10}, {0, 10}]}

      for s <- @seeds do
        seed(s)
        {o0, o1} = Crossover.sbx(p0, p1, config(:integer))

        assert Enum.all?(o0.genes, fn g -> g >= 0 and g <= 10 end),
               "seed=#{s}: o0 out of bounds"

        assert Enum.all?(o1.genes, fn g -> g >= 0 and g <= 10 end),
               "seed=#{s}: o1 out of bounds"
      end
    end

    test "works with default config" do
      seed(42)
      {o0, _} = Crossover.sbx(@p0, @p1, config(:integer))
      assert %IntChr{} = o0
      assert Petri.Chromosome.valid?(o0)
    end

    test "higher eta produces offspring closer to parents" do
      seed(42)
      {lo_eta_o0, _} = Crossover.sbx(@p0, @p1, config(:integer, %{sbx_eta: 1.0}))
      seed(42)
      {hi_eta_o0, _} = Crossover.sbx(@p0, @p1, config(:integer, %{sbx_eta: 100.0}))

      # With very high eta, offspring should be very close to parents
      # This is a soft check — the genes should be closer on average
      lo_dist =
        Enum.zip(lo_eta_o0.genes, @p0.genes)
        |> Enum.map(fn {a, b} -> abs(a - b) end)
        |> Enum.sum()

      hi_dist =
        Enum.zip(hi_eta_o0.genes, @p0.genes)
        |> Enum.map(fn {a, b} -> abs(a - b) end)
        |> Enum.sum()

      assert hi_dist <= lo_dist
    end
  end
end
