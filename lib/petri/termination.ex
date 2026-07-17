defmodule Petri.Termination do
  @moduledoc """
  Stop conditions for the generational loop.

  Any one condition being met halts the run. At least one termination
  condition must be configured (enforced by `Petri.Config`).

  ## Conditions

    * `max_generations` — stop after this many generations
    * `fitness_threshold` — stop when best fitness reaches this value
    * `stagnation_generations` — stop if no improvement for this many generations
    * `time_budget_ms` — stop after this many milliseconds elapsed
  """

  alias Petri.State

  @doc false
  def stop?(config, %State{} = state) when is_list(config) do
    max_generations = Keyword.get(config, :max_generations)
    fitness_threshold = Keyword.get(config, :fitness_threshold)
    stagnation_generations = Keyword.get(config, :stagnation_generations)
    time_budget_ms = Keyword.get(config, :time_budget_ms)

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
