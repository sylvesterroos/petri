defmodule Petri.MixProject do
  use Mix.Project

  def project do
    [
      app: :petri,
      version: "0.3.0-dev",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description:
        "A multi-representation genetic algorithm library with representation-specific crossover and mutation operators.",
      source_url: "https://github.com/sylvesterroos/petri",
      homepage_url: "https://github.com/sylvesterroos/petri",
      docs: [
        main: "Petri",
        extras: ["README.md"]
      ],
      package: package(),
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:zoi, "~> 0.18"},
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:tidewave, "~> 0.6", only: [:dev]},
      {:bandit, "~> 1.0", only: :dev}
    ]
  end

  defp aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end

  defp package do
    [
      licenses: ["LGPL-3.0-or-later"],
      links: %{
        "GitHub" => "https://github.com/sylvesterroos/petri"
      }
    ]
  end
end
