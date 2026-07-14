defmodule Petri.State do
  @moduledoc "Internal engine state tracked across generations."
  defstruct generation: 1,
            best_fitness: 0.0,
            last_improvement_generation: 1,
            elapsed_ms: 0,
            started_at_ms: 0,
            evaluations: 0
end
