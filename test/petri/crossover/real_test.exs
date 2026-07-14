defmodule Petri.Crossover.RealTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Real
  alias Petri.Crossover.Real, as: Crossover

  @bounds [{-5.0, 5.0}, {0.0, 10.0}]

  describe "blx_alpha/3" do
    test "returns valid real offspring within bounds" do
      p0 = %Real{genes: [1.0, 3.0], bounds: @bounds}
      p1 = %Real{genes: [-2.0, 7.0], bounds: @bounds}

      seed(42)
      {o0, o1} = Crossover.blx_alpha(p0, p1, config(:real))

      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)

      Enum.zip(o0.genes, @bounds)
      |> Enum.each(fn {g, {lo, hi}} ->
        assert g >= lo and g <= hi, "o0 gene #{g} outside [#{lo}, #{hi}]"
      end)

      Enum.zip(o1.genes, @bounds)
      |> Enum.each(fn {g, {lo, hi}} ->
        assert g >= lo and g <= hi, "o1 gene #{g} outside [#{lo}, #{hi}]"
      end)
    end

    test "clamps to bounds when parents are near an edge" do
      # Gene 0: parents at -5.0 and -4.9 → lower = max(min_g - α·d, lo) hits lo = -5.0
      # Gene 1: parents at  5.0 and  4.9 → upper = min(max_g + α·d, hi) hits hi = 10.0
      p0 = %Real{genes: [-5.0, 10.0], bounds: @bounds}
      p1 = %Real{genes: [-4.9, 4.9], bounds: @bounds}

      seed(42)
      {o0, o1} = Crossover.blx_alpha(p0, p1, config(:real))

      Enum.zip(o0.genes, @bounds)
      |> Enum.each(fn {g, {lo, hi}} ->
        assert g >= lo and g <= hi, "o0 gene #{g} outside [#{lo}, #{hi}]"
      end)

      Enum.zip(o1.genes, @bounds)
      |> Enum.each(fn {g, {lo, hi}} ->
        assert g >= lo and g <= hi, "o1 gene #{g} outside [#{lo}, #{hi}]"
      end)
    end

    test "is deterministic with the same seed" do
      p0 = %Real{genes: [1.0, 3.0], bounds: @bounds}
      p1 = %Real{genes: [-2.0, 7.0], bounds: @bounds}
      cfg = config(:real)

      seed(42)
      a = Crossover.blx_alpha(p0, p1, cfg)

      seed(42)
      b = Crossover.blx_alpha(p0, p1, cfg)

      assert a == b
    end
  end

  describe "sbx/3" do
    test "returns valid real offspring within bounds" do
      p0 = %Real{genes: [1.0, 3.0], bounds: @bounds}
      p1 = %Real{genes: [-2.0, 7.0], bounds: @bounds}

      seed(42)
      {o0, o1} = Crossover.sbx(p0, p1, config(:real))

      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)

      Enum.zip(o0.genes, @bounds)
      |> Enum.each(fn {g, {lo, hi}} ->
        assert g >= lo and g <= hi, "o0 gene #{g} outside [#{lo}, #{hi}]"
      end)

      Enum.zip(o1.genes, @bounds)
      |> Enum.each(fn {g, {lo, hi}} ->
        assert g >= lo and g <= hi, "o1 gene #{g} outside [#{lo}, #{hi}]"
      end)
    end

    test "both beta branches execute across seeds" do
      p0 = %Real{genes: [1.0, 3.0], bounds: @bounds}
      p1 = %Real{genes: [-2.0, 7.0], bounds: @bounds}
      cfg = config(:real)

      for seed_num <- 1..50 do
        seed(seed_num)
        {o0, o1} = Crossover.sbx(p0, p1, cfg)

        assert Petri.Chromosome.valid?(o0), "seed=#{seed_num}: o0 not valid"
        assert Petri.Chromosome.valid?(o1), "seed=#{seed_num}: o1 not valid"

        Enum.zip(o0.genes, @bounds)
        |> Enum.each(fn {g, {lo, hi}} ->
          assert g >= lo and g <= hi,
                 "seed=#{seed_num}: o0 gene #{g} outside [#{lo}, #{hi}]"
        end)

        Enum.zip(o1.genes, @bounds)
        |> Enum.each(fn {g, {lo, hi}} ->
          assert g >= lo and g <= hi,
                 "seed=#{seed_num}: o1 gene #{g} outside [#{lo}, #{hi}]"
        end)
      end
    end

    test "is deterministic with the same seed" do
      p0 = %Real{genes: [1.0, 3.0], bounds: @bounds}
      p1 = %Real{genes: [-2.0, 7.0], bounds: @bounds}
      cfg = config(:real)

      seed(42)
      a = Crossover.sbx(p0, p1, cfg)

      seed(42)
      b = Crossover.sbx(p0, p1, cfg)

      assert a == b
    end
  end
end
