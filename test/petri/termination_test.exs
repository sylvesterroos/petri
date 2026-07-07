defmodule Petri.TerminationTest do
  use ExUnit.Case, async: true

  alias Petri.State
  alias Petri.Termination

  describe "stop?/2" do
    test "returns false when no termination condition is met" do
      config = termination_fixture(%{max_generations: 100})

      state = %State{
        generation: 10,
        best_fitness: 5.0,
        last_improvement_generation: 9,
        elapsed_ms: 100
      }

      refute Termination.stop?(config, state)
    end

    test "stops when max_generations is reached" do
      config = termination_fixture(%{max_generations: 10})

      state = %State{
        generation: 10,
        best_fitness: 5.0,
        last_improvement_generation: 9,
        elapsed_ms: 100
      }

      assert Termination.stop?(config, state)
    end

    test "stops when max_generations is exceeded" do
      config = termination_fixture(%{max_generations: 10})

      state = %State{
        generation: 11,
        best_fitness: 5.0,
        last_improvement_generation: 9,
        elapsed_ms: 100
      }

      assert Termination.stop?(config, state)
    end

    test "stops when fitness_threshold is reached" do
      config = termination_fixture(%{fitness_threshold: 10.0})

      state = %State{
        generation: 5,
        best_fitness: 10.0,
        last_improvement_generation: 5,
        elapsed_ms: 100
      }

      assert Termination.stop?(config, state)
    end

    test "stops when fitness_threshold is exceeded" do
      config = termination_fixture(%{fitness_threshold: 10.0})

      state = %State{
        generation: 5,
        best_fitness: 15.0,
        last_improvement_generation: 5,
        elapsed_ms: 100
      }

      assert Termination.stop?(config, state)
    end

    test "does not stop on fitness_threshold when below" do
      config = termination_fixture(%{fitness_threshold: 10.0})

      state = %State{
        generation: 5,
        best_fitness: 9.9,
        last_improvement_generation: 5,
        elapsed_ms: 100
      }

      refute Termination.stop?(config, state)
    end

    test "stops on stagnation" do
      config = termination_fixture(%{stagnation_generations: 5})

      state = %State{
        generation: 10,
        best_fitness: 5.0,
        last_improvement_generation: 5,
        elapsed_ms: 100
      }

      assert Termination.stop?(config, state)
    end

    test "does not stop before stagnation limit" do
      config = termination_fixture(%{stagnation_generations: 5})

      state = %State{
        generation: 9,
        best_fitness: 5.0,
        last_improvement_generation: 5,
        elapsed_ms: 100
      }

      refute Termination.stop?(config, state)
    end

    test "stops when time_budget is exhausted" do
      config = termination_fixture(%{time_budget_ms: 1000})

      state = %State{
        generation: 1,
        best_fitness: 5.0,
        last_improvement_generation: 1,
        elapsed_ms: 1000
      }

      assert Termination.stop?(config, state)
    end

    test "stops when time_budget is exceeded" do
      config = termination_fixture(%{time_budget_ms: 1000})

      state = %State{
        generation: 1,
        best_fitness: 5.0,
        last_improvement_generation: 1,
        elapsed_ms: 1500
      }

      assert Termination.stop?(config, state)
    end

    test "returns true if any active condition is met" do
      config = termination_fixture(%{max_generations: 100, fitness_threshold: 20.0})

      state = %State{
        generation: 50,
        best_fitness: 25.0,
        last_improvement_generation: 49,
        elapsed_ms: 100
      }

      assert Termination.stop?(config, state)
    end
  end

  defp termination_fixture(attrs) do
    %{
      max_generations: 10,
      fitness_threshold: 10,
      stagnation_generations: 5,
      time_budget_ms: to_timeout(second: 5)
    }
    |> Map.merge(attrs)
  end
end
