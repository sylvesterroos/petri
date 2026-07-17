defmodule Petri.Config do
  alias Zoi, as: Z

  @base %{
    population_size:
      Z.integer(description: "Number of individuals in each generation") |> Z.gte(1),
    max_generations:
      Z.integer(description: "Maximum number of generations before stopping")
      |> Z.gte(1)
      |> Z.optional(),
    fitness_threshold:
      Z.float(description: "Stop when best fitness reaches or exceeds this value")
      |> Z.optional(),
    stagnation_generations:
      Z.integer(description: "Stop if no improvement after this many generations")
      |> Z.gte(1)
      |> Z.optional(),
    time_budget_ms:
      Z.integer(description: "Maximum wall-clock time in milliseconds")
      |> Z.gte(1)
      |> Z.optional(),
    selection:
      Z.enum([:tournament, :roulette, :rank, :sus],
        description: "Selection strategy"
      )
      |> Z.default(:sus),
    tournament_size:
      Z.integer(
        description: "Number of individuals in each tournament (only for :tournament selection)"
      )
      |> Z.gte(1)
      |> Z.default(3),
    elite_count:
      Z.integer(description: "Number of top individuals preserved unchanged each generation")
      |> Z.gte(0)
      |> Z.default(2),
    crossover_rate:
      Z.float(description: "Probability of applying crossover to a selected pair")
      |> Z.gte(0.0)
      |> Z.lte(1.0)
      |> Z.default(0.9),
    mutation_rate:
      Z.float(description: "Probability of applying mutation to an offspring")
      |> Z.gte(0.0)
      |> Z.lte(1.0)
      |> Z.default(0.1),
    seed: Z.integer(description: "Random seed for reproducible runs") |> Z.optional()
  }

  @permutation Z.map(
                 Map.merge(@base, %{
                   encoding: Z.literal(:permutation),
                   n: Z.integer(description: "Number of elements in the permutation") |> Z.gte(1),
                   initialization:
                     Z.enum([:random], description: "Initialization strategy")
                     |> Z.default(:random),
                   crossover:
                     Z.enum([:ox, :pmx, :cx], description: "Crossover operator")
                     |> Z.default(:pmx),
                   mutation:
                     Z.enum([:swap, :insert, :inversion], description: "Mutation operator")
                     |> Z.default(:swap)
                 })
               )

  @real Z.map(
          Map.merge(@base, %{
            encoding: Z.literal(:real),
            bounds:
              Z.list(Z.tuple({Z.float(), Z.float()}),
                description: "List of {lo, hi} tuples, one per gene, defining the search space"
              ),
            initialization:
              Z.enum([:random, :lhs], description: "Initialization strategy")
              |> Z.default(:random),
            crossover:
              Z.enum([:blx_alpha, :sbx], description: "Crossover operator")
              |> Z.default(:blx_alpha),
            blx_alpha_param:
              Z.float(
                description: "Alpha parameter for BLX-α crossover (0.0 = average, 0.5 = midpoint)"
              )
              |> Z.gte(0.0)
              |> Z.default(0.5),
            sbx_eta:
              Z.float(
                description: "Distribution index for SBX crossover (higher = closer to parents)"
              )
              |> Z.gte(1.0)
              |> Z.default(2.0),
            mutation:
              Z.enum([:gaussian, :uniform], description: "Mutation operator")
              |> Z.default(:gaussian),
            gaussian_sigma:
              Z.float(
                description:
                  "Standard deviation for Gaussian mutation (as fraction of bound width)"
              )
              |> Z.gte(0.0)
              |> Z.default(0.1),
            mutation_per_gene_rate:
              Z.float(description: "Probability of mutating each individual gene")
              |> Z.gte(0.0)
              |> Z.lte(1.0)
              |> Z.default(1.0)
          })
        )

  @binary Z.map(
            Map.merge(@base, %{
              encoding: Z.literal(:binary),
              length: Z.integer(description: "Number of bits in the chromosome") |> Z.gte(1),
              initialization:
                Z.enum([:random], description: "Initialization strategy")
                |> Z.default(:random),
              crossover:
                Z.enum([:single_point, :two_point, :uniform],
                  description: "Crossover operator"
                )
                |> Z.default(:single_point),
              mutation:
                Z.enum([:bit_flip], description: "Mutation operator")
                |> Z.default(:bit_flip),
              mutation_per_gene_rate:
                Z.float(description: "Probability of flipping each individual bit")
                |> Z.gte(0.0)
                |> Z.lte(1.0)
                |> Z.optional()
            })
          )

  @integer Z.map(
             Map.merge(@base, %{
               encoding: Z.literal(:integer),
               bounds:
                 Z.list(Z.tuple({Z.integer(), Z.integer()}),
                   description:
                     "List of {lo, hi} tuples, one per gene, defining the integer search space"
                 ),
               initialization:
                 Z.enum([:random], description: "Initialization strategy")
                 |> Z.default(:random),
               crossover:
                 Z.enum([:blx_alpha, :two_point, :sbx], description: "Crossover operator")
                 |> Z.default(:blx_alpha),
               blx_alpha_param:
                 Z.float(description: "Alpha parameter for BLX-α crossover")
                 |> Z.gte(0.0)
                 |> Z.default(0.5),
               sbx_eta:
                 Z.float(description: "Distribution index for SBX crossover")
                 |> Z.gte(1.0)
                 |> Z.default(2.0),
               mutation:
                 Z.enum([:gaussian, :uniform], description: "Mutation operator")
                 |> Z.default(:gaussian),
               gaussian_sigma:
                 Z.float(
                   description:
                     "Standard deviation for Gaussian mutation (as fraction of bound width)"
                 )
                 |> Z.gte(0.0)
                 |> Z.default(0.1),
               mutation_per_gene_rate:
                 Z.float(description: "Probability of mutating each individual gene")
                 |> Z.gte(0.0)
                 |> Z.lte(1.0)
                 |> Z.default(1.0)
             })
           )

  @schema Z.discriminated_union(:encoding, [@permutation, @real, @binary, @integer])

  @moduledoc """
  Typed config validation for `Petri.run/2`.

  Uses [Zoi](https://hexdocs.pm/zoi) to validate the config keyword list
  against a typed schema. Invalid configs return `{:error, reasons}`.

  ## Config fields

  Fields marked Required must always be present. The available fields
  depend on which `:encoding` you choose.

  ### `:binary` encoding

  #{Zoi.describe(@binary)}

  ### `:real` encoding

  #{Zoi.describe(@real)}

  ### `:permutation` encoding

  #{Zoi.describe(@permutation)}

  ### `:integer` encoding

  #{Zoi.describe(@integer)}

  ## Example

      iex> {:ok, config} = Petri.Config.parse([
      ...>   encoding: :binary,
      ...>   length: 8,
      ...>   population_size: 20,
      ...>   max_generations: 10
      ...> ])
      iex> config[:encoding]
      :binary

      iex> {:error, err} = Petri.Config.parse([
      ...>   encoding: :binary,
      ...>   length: 8,
      ...>   population_size: 0,
      ...>   max_generations: 10
      ...> ])
      iex> is_list(err)
      true
  """

  @doc """
  Parses and validates a keyword list against the config schema.

  Returns `{:ok, keyword_list}` on success or `{:error, err}` on failure.
  """
  def parse(config) do
    config_map = Map.new(config)

    @schema
    |> Zoi.refine(&termination?/1)
    |> Zoi.parse(config_map)
    |> case do
      {:ok, valid} -> {:ok, Map.to_list(valid)}
      {:error, errors} -> {:error, errors}
    end
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
