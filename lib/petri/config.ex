defmodule Petri.Config do
  @moduledoc """
  Typed config validation for `Petri.run/2`.

  Uses [Zoi](https://hexdocs.pm/zoi) to validate the config map
  against a typed schema. Invalid configs return `{:error, reasons}`.

  ## Encoding-specific schemas

  The schema is a discriminated union on `:encoding`. Fields shared across
  all encodings live in a common base; encoding-specific fields (`:bounds`,
  `:crossover`, `:mutation`, etc.) are added per variant.

  ## Example

      iex> {:ok, config} = Petri.Config.parse(%{
      ...>   encoding: :binary, length: 8,
      ...>   population_size: 20, max_generations: 10
      ...> })
      iex> config.encoding
      :binary

      iex> {:error, err} = Petri.Config.parse(%{
      ...>   encoding: :binary, length: 8,
      ...>   population_size: 0, max_generations: 10
      ...> })
      iex> is_list(err)
      true
  """

  alias Zoi, as: Z

  @base %{
    population_size: Z.integer() |> Z.gte(1),
    max_generations: Z.integer() |> Z.gte(1) |> Z.optional(),
    fitness_threshold: Z.float() |> Z.optional(),
    stagnation_generations: Z.integer() |> Z.gte(1) |> Z.optional(),
    time_budget_ms: Z.integer() |> Z.gte(1) |> Z.optional(),
    selection: Z.enum([:tournament, :roulette, :rank, :sus]) |> Z.default(:sus),
    tournament_size: Z.integer() |> Z.gte(1) |> Z.optional(),
    seed: Z.integer() |> Z.optional(),
    elite_count: Z.integer() |> Z.gte(0) |> Z.default(2),
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
            initialization: Z.enum([:random, :lhs]) |> Z.default(:random),
            crossover: Z.enum([:blx_alpha, :sbx]) |> Z.default(:blx_alpha),
            mutation: Z.enum([:gaussian, :uniform]) |> Z.default(:gaussian),
            blx_alpha_param: Z.float() |> Z.gte(0.0) |> Z.default(0.5),
            sbx_eta: Z.float() |> Z.gte(1.0) |> Z.default(2.0),
            gaussian_sigma: Z.float() |> Z.gte(0.0) |> Z.default(0.1),
            mutation_per_gene_rate: Z.float() |> Z.gte(0.0) |> Z.lte(1.0) |> Z.optional()
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

  @doc """
  Parses and validates a map against the config schema.

  Returns `{:ok, typed_map}` on success or `{:error, err}` on failure.
  """
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
