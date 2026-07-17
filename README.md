<div align="center">
  <img src="https://raw.githubusercontent.com/sylvesterroos/petri/master/assets/hero.svg" alt="Petri" width="600">
</div>

# Petri

[![Hex.pm](https://img.shields.io/hexpm/v/petri.svg)](https://hex.pm/packages/petri)
[![Docs](https://img.shields.io/badge/docs-hexdocs-purple.svg)](https://hexdocs.pm/petri)
[![License](https://img.shields.io/badge/license-LGPL--3.0--or--later-blue.svg)](LICENSE)

A genetic algorithm library for Elixir.

## What's a genetic algorithm?

A genetic algorithm is a form of evolutionary optimization for problems with too many combinations to brute force. For example: the shortest route through 52 cities, the best hyperparameters for a model, or the most useful features in a dataset. A dataset of 50 features has a quadrillion combinations. At a million checks per second you're waiting 36 years. A GA gets a good answer before you've dropped programming and taken up farming.

A GA works like natural selection. Generate a population of candidate solutions, score them with a fitness function you write, pick the best, cross them to create new candidates, mutate a few to explore. Repeat for a few hundred generations. The result is rarely the mathematical optimum, but it gets there while brute force is just getting started.

Petri handles the selection, crossover, mutation, and generational loop. You pick a chromosome encoding that fits your problem, write a fitness function, and run it.

## Quick start

Below is the traveling salesman problem on Berlin52: 52 cities, find the shortest tour that visits each once.

```elixir
alias Petri.Chromosome.Permutation

# Fitness: shorter tours score higher (a GA maximizes, so invert distance)
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

{best_tour, _best_fitness} = result.best
```

> See [`examples/tsp.exs`](examples/tsp.exs) for the full runnable script with city coordinates and distance calculation.

## Capabilities

Four chromosome encodings, each with operators tuned for that representation.

| Encoding | Use when | Shape |
|---|---|---|
| `:real` | Continuous parameters | `[0.001, 0.5, 120.0]` |
| `:integer` | Discrete counts | `[3, 17, 255]` |
| `:permutation` | Ordering problems | `[4, 0, 7, 2, 5, 1, 3, 6]` |
| `:binary` | Subset selection | `[1, 0, 1, 1, 0]` |

Config validation catches operator/encoding mismatches up front so you won't get surprises mid-run.

## Running the examples

Standalone scripts that pull in Petri via `Mix.install`. Run from the repo root with `elixir` (not `mix`):

```
elixir examples/tsp.exs
elixir examples/ml_hyperparams.exs
elixir examples/feature_selection.exs
elixir examples/ring_inscription.exs
```

| Example | Encoding | What it does |
|---|---|---|
| `tsp.exs` | permutation | Order crossover + inversion on Berlin52 |
| `ml_hyperparams.exs` | real | BLX-α + Gaussian mutation tuning a linear regression |
| `feature_selection.exs` | binary | Uniform crossover + bit-flip for feature subset selection |
| `ring_inscription.exs` | integer | Two-point crossover + uniform mutation, evolve a string via bigram fitness |

## Documentation

Full API docs at [hexdocs.pm/petri](https://hexdocs.pm/petri).

## License

LGPL-3.0-or-later. See [LICENSE](LICENSE).
