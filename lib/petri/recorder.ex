defmodule Petri.Recorder do
  @moduledoc """
  Records per-generation statistics from a population.

  A population is a list of `{chromosome, fitness}` tuples. The recorder
  computes max, mean, min fitness and uses the population standard
  deviation of fitness as a simple diversity measure.
  """

  defstruct [:max_fitness, :mean_fitness, :min_fitness, :diversity]

  @doc """
  Build a snapshot from a population of `{chromosome, fitness}` tuples.
  """
  def record(population) when is_list(population) do
    fitnesses = Enum.map(population, fn {_chromosome, fitness} -> fitness end)

    %__MODULE__{
      max_fitness: Enum.max(fitnesses),
      mean_fitness: Enum.sum(fitnesses) / length(fitnesses),
      min_fitness: Enum.min(fitnesses),
      diversity: std_dev(fitnesses)
    }
  end

  defp std_dev(fitnesses) do
    n = length(fitnesses)
    mean = Enum.sum(fitnesses) / n

    fitnesses
    |> Enum.map(fn f -> (f - mean) ** 2 end)
    |> Enum.sum()
    |> Kernel./(n)
    |> :math.sqrt()
  end
end
