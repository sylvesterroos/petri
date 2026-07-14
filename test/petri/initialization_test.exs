defmodule Petri.InitializationTest do
  use ExUnit.Case, async: true

  doctest Petri.Initialization

  describe "init_random/2 for permutation" do
    test "creates a valid permutation chromosome" do
      c = Petri.Initialization.init_random(:permutation, %{n: 5})
      assert Petri.Chromosome.valid?(c)
      assert Petri.Chromosome.length(c) == 5
    end

    test "genes are a permutation of 0..n-1" do
      c = Petri.Initialization.init_random(:permutation, %{n: 8})
      assert Enum.sort(Petri.Chromosome.genes(c)) == Enum.to_list(0..7)
    end
  end

  describe "init_random/2 for real" do
    test "creates a valid real chromosome" do
      c = Petri.Initialization.init_random(:real, %{bounds: [{0.0, 1.0}, {-5.0, 5.0}]})
      assert Petri.Chromosome.valid?(c)
      assert Petri.Chromosome.length(c) == 2
    end

    test "genes are within bounds" do
      bounds = [{0.0, 1.0}, {-10.0, 10.0}, {100.0, 200.0}]

      for s <- 1..100 do
        Petri.RNG.maybe_seed(%{seed: s})
        c = Petri.Initialization.init_random(:real, %{bounds: bounds})
        genes = Petri.Chromosome.genes(c)

        Enum.zip(genes, bounds)
        |> Enum.each(fn {g, {lo, hi}} ->
          assert g >= lo and g <= hi, "seed=#{s}: gene #{g} out of bounds [#{lo}, #{hi}]"
        end)
      end
    end
  end

  describe "init_random/2 for binary" do
    test "creates a valid binary chromosome" do
      c = Petri.Initialization.init_random(:binary, %{length: 10})
      assert Petri.Chromosome.valid?(c)
      assert Petri.Chromosome.length(c) == 10
    end

    test "genes are all 0s and 1s" do
      c = Petri.Initialization.init_random(:binary, %{length: 50})
      assert Enum.all?(Petri.Chromosome.genes(c), &(&1 in [0, 1]))
    end
  end

  describe "init_latin_hypercube/1" do
    test "returns the correct number of chromosomes" do
      Petri.RNG.maybe_seed(%{seed: 42})

      pop =
        Petri.Initialization.init_latin_hypercube(%{
          bounds: [{0.0, 1.0}, {-5.0, 5.0}],
          population_size: 10
        })

      assert length(pop) == 10
    end

    test "all chromosomes are valid" do
      Petri.RNG.maybe_seed(%{seed: 42})

      pop =
        Petri.Initialization.init_latin_hypercube(%{
          bounds: [{0.0, 1.0}, {-5.0, 5.0}],
          population_size: 20
        })

      assert Enum.all?(pop, &Petri.Chromosome.valid?/1)
    end

    test "all genes are within bounds" do
      bounds = [{0.0, 1.0}, {-10.0, 10.0}]
      Petri.RNG.maybe_seed(%{seed: 42})

      pop =
        Petri.Initialization.init_latin_hypercube(%{
          bounds: bounds,
          population_size: 20
        })

      for c <- pop do
        Enum.zip(Petri.Chromosome.genes(c), bounds)
        |> Enum.each(fn {g, {lo, hi}} ->
          assert g >= lo and g <= hi
        end)
      end
    end
  end
end
