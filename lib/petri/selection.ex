defmodule Petri.Selection do
  @moduledoc """
  Representation-agnostic parent selection.

  Selection operators work on `{chromosome, fitness}` pairs. One module
  serves all chromosome types.

  All operators select `population_size` parents from the current population.
  Higher fitness = more likely to be selected.
  """

  @doc """
  Dispatches to the named selection operator.

  Valid operators: `:tournament`, `:roulette`, `:rank`, `:sus`.

  The `config` keyword list must contain `:population_size`. Tournament selection
  also reads `:tournament_size` (defaults to 3).

  ## Example

      iex> pop = [
      ...>   {%Petri.Chromosome.Binary{genes: [0, 0, 1]}, 1.0},
      ...>   {%Petri.Chromosome.Binary{genes: [1, 1, 0]}, 2.0},
      ...>   {%Petri.Chromosome.Binary{genes: [1, 1, 1]}, 3.0}
      ...> ]
      iex> parents = Petri.Selection.select(:tournament, pop, [population_size: 2, tournament_size: 2])
      iex> length(parents)
      2
  """
  def select(selection, population, config)
      when is_atom(selection) and is_list(population) and is_list(config) do
    case selection do
      :sus -> stochastic_universal_sampling(population, config)
      :tournament -> tournament_selection(population, config)
      :roulette -> roulette_selection(population, config)
      :rank -> rank_selection(population, config)
    end
  end

  @doc """
  Tournament selection. Picks `tournament_size` random individuals and
  returns the fittest. Repeat `population_size` times.

  Fast, works with negative fitness, and doesn't require fitness scaling.
  """
  def tournament_selection(population, config)
      when is_list(population) and is_list(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Keyword.fetch!(config, :population_size)
    tournament_size = config[:tournament_size]

    Enum.map(1..n, fn _ ->
      contestants = Enum.take_random(population, tournament_size)
      Enum.max_by(contestants, fn {_, fitness} -> fitness end)
    end)
  end

  @doc """
  Fitness-proportional (roulette wheel) selection.

  Each individual's selection probability is proportional to its fitness.
  Requires all fitness values to be non-negative and total fitness > 0.
  """
  def roulette_selection(population, config)
      when is_list(population) and is_list(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Keyword.fetch!(config, :population_size)

    total_fitness =
      Enum.reduce(population, 0.0, fn {_, fitness}, acc ->
        if fitness < 0.0, do: raise(ArgumentError, "negative fitness: #{fitness}")
        acc + fitness
      end)

    if total_fitness == 0.0, do: raise(ArgumentError, "total fitness is zero")

    Enum.map(1..n, fn _ ->
      pointer = :rand.uniform() * total_fitness
      select_one(population, pointer)
    end)
  end

  @doc """
  Rank-based selection. Sorts the population by fitness and assigns
  selection probability by rank (not raw fitness value).

  Resistant to outliers — a chromosome with 100× the fitness of the rest
  won't dominate the selection pool.
  """
  def rank_selection(population, config)
      when is_list(population) and is_list(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Keyword.fetch!(config, :population_size)

    sorted = Enum.sort_by(population, fn {_, fitness} -> fitness end)

    # Rank i (1-indexed) gets weight i, so total weight = n(n+1)/2.
    # The best (last) individual is n times more likely than the worst.
    total_weight = n * (n + 1) / 2

    Enum.map(1..n, fn _ ->
      pointer = :rand.uniform() * total_weight
      select_ranked(sorted, pointer)
    end)
  end

  @doc """
  Stochastic Universal Sampling. Places `population_size` equally-spaced
  pointers on the roulette wheel.

  Guarantees that very fit individuals are selected at least floor(p_i * n)
  times, giving lower variance than repeated roulette spins.
  """
  def stochastic_universal_sampling(population, config)
      when is_list(population) and is_list(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Keyword.fetch!(config, :population_size)

    total_fitness =
      Enum.reduce(population, 0.0, fn {_, fitness}, acc ->
        if fitness < 0.0, do: raise(ArgumentError, "negative fitness: #{fitness}")
        acc + fitness
      end)

    if total_fitness == 0.0, do: raise(ArgumentError, "total fitness is zero")
    pointer_spacing = total_fitness / n
    start = :rand.uniform() * pointer_spacing

    pointers =
      for i <- 0..(n - 1) do
        start + i * pointer_spacing
      end

    Enum.map(pointers, &select_one(population, &1))
  end

  defp select_one(population, pointer) do
    Enum.reduce_while(population, 0.0, fn {_gene, fitness} = chromosome, cumulative ->
      next = cumulative + fitness

      if next >= pointer do
        {:halt, chromosome}
      else
        {:cont, next}
      end
    end)
  end

  defp select_ranked(sorted, pointer) do
    {selected, _} =
      Enum.reduce_while(Enum.with_index(sorted, 1), 0.0, fn {item, rank}, acc ->
        next = acc + rank

        if next >= pointer do
          {:halt, {item, next}}
        else
          {:cont, next}
        end
      end)

    selected
  end
end
