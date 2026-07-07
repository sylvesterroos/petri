defmodule Petri do
  alias Petri.Config
  alias Petri.Engine

  def run(fitness_fn, config) do
    Engine.run(fitness_fn, config)
  end

  def configure(config) do
    Config.parse(config)
  end
end
