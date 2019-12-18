defmodule PushGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :push_gateway,
      version: "1.0.0-static",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {PushGateway.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 0.14"},
      {:jason, "~> 1.1"},
      {:distillery, "~> 2.1.1"},
      {:credo, "~> 1.1.5"}
    ]
  end
end
