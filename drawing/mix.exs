defmodule Drawing.MixProject do
  use Mix.Project
  
  def project do
    [
      app: :drawing,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        drawing: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end
  def application do
    [
      extra_applications: [:logger],
      mod: {Drawing.Application, []}
    ]
  end
  
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:websock_adapter, "~> 0.5"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.4"}  # ADD THIS LINE IF YOU DON'T HAVE IT
    ]
  end
end
