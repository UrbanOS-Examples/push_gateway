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
      {:elsa, "~> 0.11.1"},
      {:brook, "~> 0.4.9"},
      {:gen_stage, "~> 0.14"},
      {:jason, "~> 1.1"},
      {:distillery, "~> 2.1.1"},
      {:smart_city, "~> 3.11.0"},
      {:retry, "~> 0.13"},
      {:smart_city_test, "~> 0.8.0", only: :test},
      {:credo, "~> 1.1.5", only: :dev},
      {:placebo, "~> 1.2.2", only: :test}
    ]
  end
end
