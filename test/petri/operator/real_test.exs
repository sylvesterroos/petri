defmodule Petri.Operator.RealTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Chromosome.Real
  alias Petri.Operator.Real, as: Operator

  describe "crossover/1" do
    test "returns a function for :blx_alpha" do
      seed(1)
      p0 = %Real{genes: [1.0, 2.0], bounds: [{0.0, 5.0}, {0.0, 5.0}]}
      p1 = %Real{genes: [3.0, 4.0], bounds: [{0.0, 5.0}, {0.0, 5.0}]}

      fun = Operator.crossover(:blx_alpha)
      {o0, o1} = fun.(p0, p1, config(:real))

      assert %Real{} = o0
      assert %Real{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end

    test "returns a function for :sbx" do
      seed(2)
      p0 = %Real{genes: [1.0, 2.0], bounds: [{0.0, 5.0}, {0.0, 5.0}]}
      p1 = %Real{genes: [3.0, 4.0], bounds: [{0.0, 5.0}, {0.0, 5.0}]}

      fun = Operator.crossover(:sbx)
      {o0, o1} = fun.(p0, p1, config(:real))

      assert %Real{} = o0
      assert %Real{} = o1
      assert Petri.Chromosome.valid?(o0)
      assert Petri.Chromosome.valid?(o1)
    end
  end

  describe "mutation/1" do
    test "returns a function for :gaussian" do
      seed(3)
      parent = %Real{genes: [1.0, 2.0], bounds: [{0.0, 5.0}, {0.0, 5.0}]}

      fun = Operator.mutation(:gaussian)
      child = fun.(parent, config(:real))

      assert %Real{} = child
      assert Petri.Chromosome.valid?(child)
    end

    test "returns a function for :uniform" do
      seed(4)
      parent = %Real{genes: [1.0, 2.0], bounds: [{0.0, 5.0}, {0.0, 5.0}]}

      fun = Operator.mutation(:uniform)
      child = fun.(parent, config(:real))

      assert %Real{} = child
      assert Petri.Chromosome.valid?(child)
    end
  end
end
