defmodule Petri.Result do
  @moduledoc """
  The return value of `Petri.run/2`.

  ## Fields

    * `best` — a `{chromosome, fitness}` tuple for the best individual found
    * `history` — a list of per-generation snapshots (see `Petri.Recorder`)
    * `generations_run` — number of generations completed
    * `evaluations` — total number of fitness function calls
  """

  alias Petri.State

  defstruct [:best, :history, :generations_run, :evaluations]

  @doc "Builds a Result from the best individual, generation history, and final engine state."
  def new(best, history, %State{} = state) do
    %__MODULE__{
      best: best,
      history: history,
      generations_run: state.generation,
      evaluations: state.evaluations
    }
  end
end
