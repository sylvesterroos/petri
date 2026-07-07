defmodule Petri.Selection.TournamentTest do
  use ExUnit.Case, async: true

  import Petri.TestHelpers

  alias Petri.Selection

  @pop [
    {0, 10.0},
    {1, 15.0},
    {2, 5.0},
    {3, 8.0},
    {4, 2.0}
  ]

  describe "tournament_selection/2" do
    test "returns exactly population_size chromosomes" do
      seed(1)
      selected = Selection.tournament_selection(@pop, %{population_size: 3})
      assert length(selected) == 3
    end

    test "every selected chromosome comes from the input population" do
      seed(1)
      selected = Selection.tournament_selection(@pop, %{population_size: 20})
      labels = Enum.map(selected, fn {c, _f} -> c end)
      assert Enum.all?(labels, &(&1 in [0, 1, 2, 3, 4]))
    end

    test "defaults to tournament size 3" do
      seed(1)
      selected = Selection.tournament_selection(@pop, %{population_size: 100})
      labels = Enum.map(selected, fn {c, _f} -> c end)
      assert Enum.count(labels, &(&1 == 1)) > Enum.count(labels, &(&1 == 4))
    end

    test "respects configured tournament_size" do
      seed(1)
      selected = Selection.tournament_selection(@pop, %{population_size: 100, tournament_size: 1})
      labels = Enum.map(selected, fn {c, _f} -> c end)
      # With size 1 selection is uniform, so the best individual should not dominate.
      assert Enum.count(labels, &(&1 == 1)) < 50
    end

    test "is deterministic for a fixed seed" do
      seed(42)
      s1 = Selection.tournament_selection(@pop, %{population_size: 5})
      seed(42)
      s2 = Selection.tournament_selection(@pop, %{population_size: 5})
      assert s1 == s2
    end

    test "selects the only chromosome when population has one member" do
      selected = Selection.tournament_selection([{42, 1.0}], %{population_size: 5})
      assert selected == [{42, 1.0}, {42, 1.0}, {42, 1.0}, {42, 1.0}, {42, 1.0}]
    end
  end
end
