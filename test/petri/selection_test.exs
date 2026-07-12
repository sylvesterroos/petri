defmodule Petri.SelectionTest do
  use ExUnit.Case, async: true

  doctest Petri.Selection

  import Petri.TestHelpers

  alias Petri.Selection

  # Selection is representation-agnostic: it works on {chromosome, fitness}
  # pairs and never touches gene values. The tests use plain integers as
  # stand-in chromosomes so we can assert on which chromosome was picked
  # without constructing real chromosome structs.

  @pop [
    {0, 10.0},
    {1, 15.0},
    {2, 5.0},
    {3, 8.0},
    {4, 2.0}
  ]

  describe "stochastic_universal_sampling/2" do
    test "returns exactly population_size chromosomes" do
      seed(1)
      selected = Selection.stochastic_universal_sampling(@pop, %{population_size: 3})
      assert length(selected) == 3
    end

    test "every selected chromosome comes from the input population" do
      seed(1)
      selected = Selection.stochastic_universal_sampling(@pop, %{population_size: 20})
      labels = Enum.map(selected, fn {c, _f} -> c end)
      assert Enum.all?(labels, &(&1 in [0, 1, 2, 3, 4]))
    end

    test "is deterministic for a fixed seed" do
      seed(42)
      s1 = Selection.stochastic_universal_sampling(@pop, %{population_size: 5})
      seed(42)
      s2 = Selection.stochastic_universal_sampling(@pop, %{population_size: 5})
      assert s1 == s2
    end

    test "selects the only chromosome when population has one member" do
      selected = Selection.stochastic_universal_sampling([{42, 1.0}], %{population_size: 5})
      assert selected == [{42, 1.0}, {42, 1.0}, {42, 1.0}, {42, 1.0}, {42, 1.0}]
    end

    test "raises on negative fitness" do
      neg_pop = [{0, -1.0}, {1, 2.0}, {2, 3.0}]

      assert_raise ArgumentError, ~r/negative/, fn ->
        Selection.stochastic_universal_sampling(neg_pop, %{population_size: 3})
      end
    end

    test "raises when total fitness is zero" do
      zero_pop = [{0, 0.0}, {1, 0.0}, {2, 0.0}]

      assert_raise ArgumentError, ~r/zero|total/, fn ->
        Selection.stochastic_universal_sampling(zero_pop, %{population_size: 3})
      end
    end
  end
end
