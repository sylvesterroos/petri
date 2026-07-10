# Petri

A multi-representation genetic algorithm library for Elixir.

Supports three chromosome encodings — real (continuous), permutation, and
binary — each with representation-specific crossover and mutation operators.
Selection and the generational engine work across all encodings.

## Running the examples

Examples are standalone `.exs` scripts that use `Mix.install` to pull in
dependencies. Run them from the repo root with `elixir` (not `mix`):

```
elixir examples/tsp.exs
elixir examples/ml_hyperparams.exs
elixir examples/feature_selection.exs
```

| Example | Encoding | Demonstrates |
|---|---|---|
| `tsp.exs` | permutation | Order crossover + swap mutation on Berlin52 |
| `ml_hyperparams.exs` | real | BLX-α + Gaussian mutation tuning a linear regression |
| `feature_selection.exs` | binary | Uniform crossover + bit-flip for feature subset selection |

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `petri` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:petri, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/petri>.
