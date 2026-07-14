defmodule Petri.Operator.BinaryTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Binary
  alias Petri.Operator.Binary, as: Operator

  describe "crossover/1" do
    test "returns a function for :single_point" do
      seed(1)
      p0 = %Binary{genes: [0, 1, 1, 0, 1]}
      p1 = %Binary{genes: [1, 0, 0, 1, 0]}

      fun = Operator.crossover(:single_point)
      {o0, o1} = fun.(p0, p1, config(:binary))

      assert %Binary{} = o0
      assert %Binary{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :two_point" do
      seed(2)
      p0 = %Binary{genes: [0, 1, 1, 0, 1]}
      p1 = %Binary{genes: [1, 0, 0, 1, 0]}

      fun = Operator.crossover(:two_point)
      {o0, o1} = fun.(p0, p1, config(:binary))

      assert %Binary{} = o0
      assert %Binary{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :uniform" do
      seed(3)
      p0 = %Binary{genes: [0, 1, 1, 0, 1]}
      p1 = %Binary{genes: [1, 0, 0, 1, 0]}

      fun = Operator.crossover(:uniform)
      {o0, o1} = fun.(p0, p1, config(:binary))

      assert %Binary{} = o0
      assert %Binary{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end
  end

  describe "mutation/1" do
    test "returns a function for :bit_flip" do
      seed(4)
      parent = %Binary{genes: [0, 1, 1, 0, 1]}

      fun = Operator.mutation(:bit_flip)
      child = fun.(parent, config(:binary))

      assert %Binary{} = child
      assert Petri.Chromosome.valid?(child)
    end
  end
end
