defmodule Petri.StateTest do
  use ExUnit.Case, async: true

  alias Petri.State

  test "can be constructed with all run metadata fields" do
    state = %State{
      generation: 10,
      best_fitness: 5.0,
      last_improvement_generation: 5,
      elapsed_ms: 100,
      evaluations: 500
    }

    assert state.generation == 10
    assert state.best_fitness == 5.0
    assert state.last_improvement_generation == 5
    assert state.elapsed_ms == 100
    assert state.evaluations == 500
  end
end
