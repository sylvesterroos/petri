defmodule Petri.Operator.IntegerTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Integer, as: IntChr
  alias Petri.Operator.Integer, as: Operator

  describe "crossover/1" do
    test "returns a function for :blx_alpha" do
      seed(42)
      p0 = %IntChr{genes: [1, 5, 10], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      p1 = %IntChr{genes: [3, 8, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      fun = Operator.crossover(:blx_alpha)
      {o0, o1} = fun.(p0, p1, config(:integer))

      assert %IntChr{} = o0
      assert %IntChr{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :two_point" do
      seed(42)
      p0 = %IntChr{genes: [1, 5, 10], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      p1 = %IntChr{genes: [3, 8, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      fun = Operator.crossover(:two_point)
      {o0, o1} = fun.(p0, p1, config(:integer))

      assert %IntChr{} = o0
      assert %IntChr{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :sbx" do
      seed(42)
      p0 = %IntChr{genes: [1, 5, 10], bounds: [{0, 20}, {0, 20}, {0, 20}]}
      p1 = %IntChr{genes: [3, 8, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      fun = Operator.crossover(:sbx)
      {o0, o1} = fun.(p0, p1, config(:integer))

      assert %IntChr{} = o0
      assert %IntChr{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end
  end

  describe "mutation/1" do
    test "returns a function for :gaussian" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      fun = Operator.mutation(:gaussian)
      child = fun.(parent, config(:integer))

      assert %IntChr{} = child
      assert Petri.Chromosome.valid?(child)
    end

    test "returns a function for :uniform" do
      seed(42)
      parent = %IntChr{genes: [5, 10, 15], bounds: [{0, 20}, {0, 20}, {0, 20}]}

      fun = Operator.mutation(:uniform)
      child = fun.(parent, config(:integer))

      assert %IntChr{} = child
      assert Petri.Chromosome.valid?(child)
    end
  end
end
