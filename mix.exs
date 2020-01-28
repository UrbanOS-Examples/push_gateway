defmodule PushGateway.MixProject do
  use Mix.Project

  def project do
    [
      app: :push_gateway,
      version: "1.0.0-static",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env())
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
      {:kitt, "~> 0.3.0"},
      {:distillery, "~> 2.1.1"},
      {:smart_city, "~> 3.11.0"},
      {:retry, "~> 0.13"},
      {:smart_city_test, "~> 0.8.0", only: [:test, :integration]},
      {:credo, "~> 1.1.5", only: :dev},
      {:placebo, "~> 1.2.2", only: :test},
      {:divo, "~> 1.1.0", only: [:dev, :integration]},
      {:divo_kafka, "~> 0.1.1", only: :integration},
      {:divo_redis, "~> 0.1.0", only: :integration}
    ]
  end

  defp elixirc_paths(env) when env in [:test, :integration], do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(_), do: ["test/unit"]
end
