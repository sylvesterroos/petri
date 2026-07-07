defmodule Petri.State do
  defstruct generation: 1,
            best_fitness: 0.0,
            last_improvement_generation: 1,
            elapsed_ms: 0,
            evaluations: 0
end
