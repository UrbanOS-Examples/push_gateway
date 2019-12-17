use Mix.Config

config :push_gateway,
  port: 5555,
  processors: 2,
  min_batch: 75,
  max_batch: 100
