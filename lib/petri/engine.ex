defmodule Petri.Engine do
  @moduledoc "The generational genetic algorithm engine."
  alias Petri.Initialization
  alias Petri.State
  alias Petri.RNG
  alias Petri.Termination
  alias Petri.Selection
  alias Petri.Recorder
  alias Petri.Result

  def run(fitness_fn, config) do
    config = parse_config!(config)

    RNG.maybe_seed(config)

    population = init_population(config)

    evaluated = evaluate(population, fitness_fn, 0)

    best = Enum.max_by(evaluated, fn {_, fitness} -> fitness end)

    history = [Recorder.record(evaluated)]

    initial_state = %State{
      generation: 0,
      best_fitness: elem(best, 1),
      last_improvement_generation: 0,
      elapsed_ms: 0,
      started_at_ms: System.monotonic_time(:millisecond),
      evaluations: config.population_size
    }

    {final_best, final_history, final_state} =
      loop(evaluated, best, history, initial_state, config, fitness_fn)

    Result.new(final_best, final_history, final_state)
  end

  defp parse_config!(raw_config) do
    case Petri.Config.parse(raw_config) do
      {:ok, config} -> config
      {:error, errors} -> raise ArgumentError, "invalid config: #{inspect(errors)}"
    end
  end

  defp init_population(%{encoding: :real, initialization: initialization} = config) do
    case initialization do
      :lhs -> Initialization.init_latin_hypercube(config)
      :random -> random_population(config)
    end
  end

  defp init_population(%{encoding: encoding, initialization: :random} = config)
       when encoding in [:permutation, :binary, :integer] do
    random_population(config)
  end

  defp random_population(config) do
    Stream.repeatedly(fn -> Initialization.init_random(config) end)
    |> Enum.take(config.population_size)
  end

  defp loop(population, best, history, state, config, fitness_fn) do
    state = %{state | elapsed_ms: System.monotonic_time(:millisecond) - state.started_at_ms}

    if Termination.stop?(config, state) do
      {best, Enum.reverse(history), state}
    else
      parents = Selection.select(config.selection, population, config)
      offspring_chromosomes = reproduce(parents, config)
      mutated = Enum.map(offspring_chromosomes, fn c -> mutate(c, config) end)

      evaluated_offspring = evaluate(mutated, fitness_fn, state.evaluations)

      new_population = replace(population, evaluated_offspring, config)
      generation_best = Enum.max_by(new_population, fn {_, fitness} -> fitness end)
      {new_best, new_last_improvement} = update_best(generation_best, best, state)

      new_state = %{
        state
        | generation: state.generation + 1,
          best_fitness: elem(new_best, 1),
          last_improvement_generation: new_last_improvement,
          evaluations: state.evaluations + length(evaluated_offspring)
      }

      new_history = [Recorder.record(new_population) | history]

      loop(new_population, new_best, new_history, new_state, config, fitness_fn)
    end
  end

  defp evaluate(chromosomes, fitness_fn, _offset) do
    Enum.map(chromosomes, fn chromosome ->
      fitness = fitness_fn.(chromosome)
      {chromosome, fitness}
    end)
  end

  defp reproduce(parents, config) do
    target = config.population_size - config.elite_count

    parents
    |> Stream.chunk_every(2)
    |> Stream.flat_map(fn
      [p0, p1] ->
        {o0, o1} = crossover_pair(p0, p1, config)
        [o0, o1]

      [p] ->
        [elem(p, 0)]
    end)
    |> Enum.take(max(target, 0))
  end

  defp crossover_pair(
         {c0, _},
         {c1, _},
         %{encoding: :permutation, crossover: crossover, crossover_rate: rate} = config
       ) do
    if :rand.uniform() <= rate do
      Petri.Operator.Permutation.crossover(crossover).(c0, c1, config)
    else
      {c0, c1}
    end
  end

  defp crossover_pair(
         {c0, _},
         {c1, _},
         %{encoding: :real, crossover: crossover, crossover_rate: rate} = config
       ) do
    if :rand.uniform() <= rate do
      Petri.Operator.Real.crossover(crossover).(c0, c1, config)
    else
      {c0, c1}
    end
  end

  defp crossover_pair(
         {c0, _},
         {c1, _},
         %{encoding: :binary, crossover: crossover, crossover_rate: rate} = config
       ) do
    if :rand.uniform() <= rate do
      Petri.Operator.Binary.crossover(crossover).(c0, c1, config)
    else
      {c0, c1}
    end
  end

  defp crossover_pair(
         {c0, _},
         {c1, _},
         %{encoding: :integer, crossover: crossover, crossover_rate: rate} = config
       ) do
    if :rand.uniform() <= rate do
      Petri.Operator.Integer.crossover(crossover).(c0, c1, config)
    else
      {c0, c1}
    end
  end

  defp mutate(
         chromosome,
         %{encoding: :permutation, mutation: mutation, mutation_rate: rate} = config
       ) do
    if :rand.uniform() <= rate do
      Petri.Operator.Permutation.mutation(mutation).(chromosome, config)
    else
      chromosome
    end
  end

  defp mutate(chromosome, %{encoding: :real, mutation: mutation, mutation_rate: rate} = config) do
    if :rand.uniform() <= rate do
      Petri.Operator.Real.mutation(mutation).(chromosome, config)
    else
      chromosome
    end
  end

  defp mutate(chromosome, %{encoding: :binary, mutation: mutation, mutation_rate: rate} = config) do
    if :rand.uniform() <= rate do
      Petri.Operator.Binary.mutation(mutation).(chromosome, config)
    else
      chromosome
    end
  end

  defp mutate(chromosome, %{encoding: :integer, mutation: mutation, mutation_rate: rate} = config) do
    if :rand.uniform() <= rate do
      Petri.Operator.Integer.mutation(mutation).(chromosome, config)
    else
      chromosome
    end
  end

  defp replace(population, offspring, %{population_size: size, elite_count: elite_count}) do
    elites =
      population
      |> Enum.sort_by(fn {_, fitness} -> fitness end, :desc)
      |> Enum.take(elite_count)

    offspring_needed = size - length(elites)
    elites ++ Enum.take(offspring, offspring_needed)
  end

  defp update_best(generation_best, best, state) do
    {_, generation_fitness} = generation_best
    {_, best_fitness} = best

    if generation_fitness > best_fitness do
      {generation_best, state.generation}
    else
      {best, state.last_improvement_generation}
    end
  end
end
