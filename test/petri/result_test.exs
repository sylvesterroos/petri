defmodule Petri.ResultTest do
  use ExUnit.Case, async: true

  alias Petri.Chromosome.Permutation
  alias Petri.Recorder
  alias Petri.Result
  alias Petri.State

  describe "new/3" do
    test "returns a Result struct" do
      best = {%Permutation{genes: [1, 0]}, 10.0}
      history = []
      state = %State{generation: 5, evaluations: 50}

      result = Result.new(best, history, state)

      assert %Result{} = result
      assert result.best == best
      assert result.history == history
      assert result.generations_run == 5
      assert result.evaluations == 50
    end

    test "stores a history of recorder snapshots" do
      best = {%Permutation{genes: [0, 1]}, 5.0}

      history = [
        %Recorder{
          max_fitness: 10.0,
          mean_fitness: 7.0,
          min_fitness: 4.0,
          diversity: 1.5
        },
        %Recorder{
          max_fitness: 12.0,
          mean_fitness: 8.0,
          min_fitness: 5.0,
          diversity: 1.2
        }
      ]

      state = %State{generation: 2, evaluations: 20}
      result = Result.new(best, history, state)

      assert length(result.history) == 2
      assert hd(result.history).max_fitness == 10.0
    end

    test "history includes generation 0" do
      best = {%Permutation{genes: [0, 1]}, 5.0}
      history = [%Recorder{max_fitness: 1.0, mean_fitness: 1.0, min_fitness: 1.0, diversity: 0.0}]
      state = %State{generation: 0, evaluations: 10}

      result = Result.new(best, history, state)

      assert result.generations_run == 0
      assert length(result.history) == 1
    end

    test "history length equals generations_run + 1" do
      best = {%Permutation{genes: [0, 1]}, 5.0}

      history =
        for _i <- 0..5 do
          %Recorder{max_fitness: 1.0, mean_fitness: 1.0, min_fitness: 1.0, diversity: 0.0}
        end

      state = %State{generation: 5, evaluations: 60}
      result = Result.new(best, history, state)

      assert result.generations_run == 5
      assert length(result.history) == 6
    end
  end
end
