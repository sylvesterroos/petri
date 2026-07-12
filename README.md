# Petri

A multi-representation genetic algorithm library for Elixir.

Supports three chromosome encodings:
real (continuous), permutation (ordering), and binary. Each has its own
crossover and mutation operators. Selection, termination, and the
generational engine are shared across all three.

## Usage

Three snippets from `examples/`.

### Permutation: TSP on Berlin52

```elixir
alias Petri.Chromosome.Permutation

fitness = fn %Permutation{genes: tour} ->
  1.0 / tour_distance(tour)
end

result =
  Petri.run(fitness, %{
    encoding: :permutation,
    n: 52,
    population_size: 400,
    max_generations: 1000,
    seed: 67,
    selection: :tournament,
    tournament_size: 5,
    elite_count: 8,
    crossover: :ox,
    mutation: :inversion
  })

{best_tour, best_fitness} = result.best
best_distance = 1.0 / best_fitness
```

From [`examples/tsp.exs`](examples/tsp.exs).

### Real: ML hyperparameter tuning

```elixir
alias Petri.Chromosome.Real

fitness = fn %Real{genes: [lr, lambda, epochs]} ->
  epochs_int = max(1, round(epochs))
  weights = train(train_x, train_y, lr, lambda, epochs_int)
  r2(test_y, Nx.dot(test_x, weights))
end

result =
  Petri.run(fitness, %{
    encoding: :real,
    bounds: [{1.0e-4, 1.0e-1}, {1.0e-6, 1.0e-1}, {10.0, 200.0}],
    population_size: 50,
    max_generations: 40,
    seed: 42,
    selection: :tournament,
    tournament_size: 3,
    elite_count: 3,
    crossover: :blx_alpha,
    blx_alpha_param: 0.5,
    mutation: :gaussian,
    gaussian_sigma: 0.15,
    mutation_rate: 0.3
  })

{best_chromosome, best_fitness} = result.best
[lr, lambda, epochs] = best_chromosome.genes
```

From [`examples/ml_hyperparams.exs`](examples/ml_hyperparams.exs).

### Binary: feature subset selection

```elixir
alias Petri.Chromosome.Binary

fitness = fn %Binary{genes: mask} ->
  predictions =
    Enum.map(data, fn row ->
      row |> Enum.zip(mask)
      |> Enum.reduce(0.0, fn {v, m}, acc -> if m == 1, do: acc + v, else: acc end)
    end)

  mse =
    Enum.zip(predictions, targets)
    |> Enum.reduce(0.0, fn {p, t}, acc -> acc + (p - t) ** 2 end)
    |> Kernel./(@n_samples)

  1.0 / (1.0 + mse)
end

result =
  Petri.run(fitness, %{
    encoding: :binary,
    length: 20,
    population_size: 80,
    max_generations: 80,
    seed: 17,
    selection: :tournament,
    tournament_size: 3,
    elite_count: 3,
    crossover: :uniform,
    mutation: :bit_flip,
    mutation_rate: 0.4,
    mutation_per_gene_rate: 0.05
  })

{best_chromosome, best_fitness} = result.best
```

From [`examples/feature_selection.exs`](examples/feature_selection.exs).

## Running the examples

Standalone `.exs` scripts that use `Mix.install` to pull in dependencies.
Run from the repo root with `elixir` (not `mix`):

```
elixir examples/tsp.exs
elixir examples/ml_hyperparams.exs
elixir examples/feature_selection.exs
```

| Example | Encoding | What it does |
|---|---|---|
| `tsp.exs` | permutation | Order crossover + swap mutation on Berlin52 |
| `ml_hyperparams.exs` | real | BLX-α + Gaussian mutation tuning a linear regression |
| `feature_selection.exs` | binary | Uniform crossover + bit-flip for feature subset selection |

## Installation

```elixir
def deps do
  [
    {:petri, "~> 0.1.0"}
  ]
end
```
