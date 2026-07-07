defmodule Petri.RecorderTest do
  use ExUnit.Case, async: true

  alias Petri.Recorder

  describe "record/1" do
    test "computes max, mean, min fitness from a population" do
      population = build_population(fitnesses: [10.0, 20.0, 30.0])

      snapshot = Recorder.record(population)

      assert snapshot.max_fitness == 30.0
      assert snapshot.mean_fitness == 20.0
      assert snapshot.min_fitness == 10.0
    end

    test "computes standard deviation of fitness as diversity" do
      population = build_population(fitnesses: [10.0, 20.0, 30.0])

      snapshot = Recorder.record(population)

      expected = :math.sqrt(200 / 3)
      assert_in_delta snapshot.diversity, expected, 1.0e-10
    end

    test "diversity is zero when all fitnesses are identical" do
      population = build_population(fitnesses: [5.0, 5.0, 5.0, 5.0])

      snapshot = Recorder.record(population)

      assert snapshot.diversity == 0.0
    end

    test "returns a Recorder struct" do
      population = build_population(fitnesses: [1.0, 2.0])

      snapshot = Recorder.record(population)

      assert %Recorder{} = snapshot
      assert snapshot.__struct__ == Recorder
    end
  end

  defp build_population(fitnesses: fitnesses) do
    Enum.map(fitnesses, fn fitness ->
      chromosome = %{genes: []}
      {chromosome, fitness}
    end)
  end
end
