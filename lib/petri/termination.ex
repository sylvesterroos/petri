defmodule Petri.Termination do
  alias Petri.State

  def stop?(config, %State{} = state) do
    max_generations = Map.get(config, :max_generations)
    fitness_threshold = Map.get(config, :fitness_threshold)
    stagnation_generations = Map.get(config, :stagnation_generations)
    time_budget_ms = Map.get(config, :time_budget_ms)

    [
      not is_nil(max_generations) and state.generation >= max_generations,
      not is_nil(fitness_threshold) and state.best_fitness >= fitness_threshold,
      not is_nil(time_budget_ms) and state.elapsed_ms >= time_budget_ms,
      not is_nil(stagnation_generations) and
        stagnated?(state, stagnation_generations)
    ]
    |> Enum.any?()
  end

  defp stagnated?(
         %State{generation: generation, last_improvement_generation: last_improvement_generation},
         stagnation_generations
       ) do
    generation - last_improvement_generation >= stagnation_generations
  end
end
