# PushGateway

## Configuration
In your environment config file, set up gateway with the following:

```elixir
config :push_gateway,
  port: 5555,
  max_batch: 100,  (optional, default // 100)
  min_batch: 75,   (optional, default // 75)
  processors: 5    (optional, default // 1)
```

The only required value is the port the gateway will listen on for incoming packets.
