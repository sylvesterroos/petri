defmodule Petri.Result do
  alias Petri.State

  defstruct [:best, :history, :generations_run, :evaluations]

  def new(best, history, %State{} = state) do
    %__MODULE__{
      best: best,
      history: history,
      generations_run: state.generation,
      evaluations: state.evaluations
    }
  end
end
