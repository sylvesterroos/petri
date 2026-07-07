defmodule Petri.Config do
  alias Zoi, as: Z

  @base %{
    population_size: Z.integer() |> Z.gte(1),
    max_generations: Z.integer() |> Z.gte(1) |> Z.optional(),
    fitness_threshold: Z.float() |> Z.optional(),
    stagnation_generations: Z.integer() |> Z.gte(1) |> Z.optional(),
    time_budget_ms: Z.integer() |> Z.gte(1) |> Z.optional(),
    selection: Z.enum([:tournament, :roulette, :rank, :sus]) |> Z.default(:sus),
    seed: Z.integer() |> Z.optional(),
    elitism: Z.boolean() |> Z.default(true),
    crossover_rate: Z.float() |> Z.gte(0.0) |> Z.lte(1.0) |> Z.default(0.9),
    mutation_rate: Z.float() |> Z.gte(0.0) |> Z.lte(1.0) |> Z.default(0.1)
  }

  @permutation Z.map(
                 Map.merge(@base, %{
                   encoding: Z.literal(:permutation),
                   n: Z.integer() |> Z.gte(1),
                   crossover: Z.enum([:ox, :pmx, :cx]) |> Z.default(:pmx),
                   mutation: Z.enum([:swap, :insert, :inversion]) |> Z.default(:swap)
                 })
               )

  @real Z.map(
          Map.merge(@base, %{
            encoding: Z.literal(:real),
            bounds: Z.any(),
            crossover: Z.enum([:blx_alpha, :sbx]) |> Z.default(:blx_alpha),
            mutation: Z.enum([:gaussian, :uniform]) |> Z.default(:gaussian)
          })
        )

  @binary Z.map(
            Map.merge(@base, %{
              encoding: Z.literal(:binary),
              length: Z.integer() |> Z.gte(1),
              crossover:
                Z.enum([:single_point, :two_point, :uniform]) |> Z.default(:single_point),
              mutation: Z.enum([:bit_flip]) |> Z.default(:bit_flip)
            })
          )

  @schema Z.discriminated_union(:encoding, [@permutation, @real, @binary])

  def parse(config) do
    @schema
    |> Zoi.refine(&termination?/1)
    |> Zoi.parse(config)
  end

  defp termination?(config) do
    if config
       |> Map.take(~w[max_generations fitness_threshold stagnation_generations time_budget_ms]a)
       |> Enum.any?() do
      :ok
    else
      {:error, "at least one termination condition is required"}
    end
  end
end
