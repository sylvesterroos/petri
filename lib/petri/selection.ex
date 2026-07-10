defmodule Petri.Selection do
  def select(selection, population, config)
      when is_atom(selection) and is_list(population) and is_map(config) do
    case selection do
      :sus -> stochastic_universal_sampling(population, config)
      :tournament -> tournament_selection(population, config)
      :roulette -> roulette_selection(population, config)
      :rank -> rank_selection(population, config)
    end
  end

  def stochastic_universal_sampling(population, config)
      when is_list(population) and is_map(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Map.fetch!(config, :population_size)

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

  def tournament_selection(population, config)
      when is_list(population) and is_map(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Map.fetch!(config, :population_size)
    tournament_size = Map.get(config, :tournament_size, 3)

    Enum.map(1..n, fn _ ->
      contestants = Enum.take_random(population, tournament_size)
      Enum.max_by(contestants, fn {_, fitness} -> fitness end)
    end)
  end

  def roulette_selection(population, config)
      when is_list(population) and is_map(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Map.fetch!(config, :population_size)

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

  def rank_selection(population, config)
      when is_list(population) and is_map(config) do
    if length(population) == 0, do: raise(ArgumentError, "empty population")
    n = Map.fetch!(config, :population_size)

    sorted = Enum.sort_by(population, fn {_, fitness} -> fitness end)

    # Rank i (1-indexed) gets weight i, so total weight = n(n+1)/2.
    # The best (last) individual is n times more likely than the worst.
    total_weight = n * (n + 1) / 2

    Enum.map(1..n, fn _ ->
      pointer = :rand.uniform() * total_weight
      select_ranked(sorted, pointer)
    end)
  end

  ## Helpers

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
