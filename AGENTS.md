# AGENTS.md

## Commands

All commands run via `devenv shell -- <cmd>`. The devenv sets `MIX_HOME` and `HEX_HOME` to local directories (`.mix`, `.hex`) inside the repo.

```
devenv shell -- mix compile                           # build
devenv shell -- mix test                              # full suite (115 tests, ~0.1s)
devenv shell -- mix test test/petri/engine_test.exs   # single file
devenv shell -- mix test test/petri/engine_test.exs:45           # single test (line)
devenv shell -- mix test --trace test/petri/engine_test.exs:45   # verbose single test
devenv shell -- mix format                            # format all Elixir files
devenv shell -- mix docs                              # generate docs to doc/

devenv shell -- elixir examples/tsp.exs               # run examples (NOT mix run)
devenv shell -- elixir examples/ml_hyperparams.exs
devenv shell -- elixir examples/feature_selection.exs
```

Examples are standalone `.exs` scripts that use `Mix.install([{:petri, path: "."}])`. They run directly with `elixir` from the repo root, no compilation needed.

## Architecture

Three chromosome encodings, each a struct implementing the `Petri.Chromosome` protocol:

- `Petri.Chromosome.Real` — continuous floats, per-gene `{lo, hi}` bounds
- `Petri.Chromosome.Permutation` — integer permutations, no duplicates
- `Petri.Chromosome.Binary` — bit strings (0/1)

The protocol provides `length/1`, `genes/1`, and `valid?/1`.

Operator dispatch is per-encoding: `Petri.Operator.{Encoding}.crossover/1` and `mutation/1` take an atom and return a function reference. Selection, termination, and the generational engine (`Petri.Engine`) are representation-agnostic — they work on `{chromosome, fitness}` tuples.

Config validation uses [Zoi](https://hexdocs.pm/zoi) with a discriminated union on `:encoding`. Encoding-specific fields (e.g., `:bounds`, `:crossover`, `:mutation`) are only valid for their matching encoding.

## Conventions

**RNG.** The engine seeds `:rand` once at the start of a run (via `Petri.RNG.maybe_seed/1`). Individual operators do NOT seed themselves. Tests that call operators directly must seed manually:

```elixir
import Petri.TestHelpers
seed(42)
```

The test helper module at `test/support/test_helpers.ex` is compiled in test env — `mix.exs` adds `test/support` to `elixirc_paths` for `:test`.

**Fitness.** Always maximization. Higher fitness = better. There is no `direction: :minimize` option — invert your fitness function if you need to minimize.

**Config.** Use `Petri.configure/1` to validate without running. Returns `{:ok, config}` or `{:error, reasons}`. `Petri.run/2` raises `ArgumentError` on bad config.

## Gotchas

- At least one termination condition is required: `max_generations`, `fitness_threshold`, `stagnation_generations`, or `time_budget_ms`. Config validation rejects a map with none of these.
- Operator fields are encoding-scoped. `crossover: :blx_alpha` is only valid with `encoding: :real`. Passing it with `:binary` or `:permutation` fails validation.
- Examples are Elixir scripts, not Mix tasks. Use `elixir`, not `mix run`.
