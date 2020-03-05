use Mix.Config

required_envars = [
  "ASSIGNED_DATASET_ID",
  "KAFKA_BROKERS",
  "REDIS_HOST",
  "LISTEN_PORT"
]

Enum.each(required_envars, fn var ->
  if is_nil(System.get_env(var)) do
    raise ArgumentError, message: "Required environment variable #{var} is undefined"
  end
end)

assigned_dataset_id = System.get_env("ASSIGNED_DATASET_ID")
kafka_brokers = System.get_env("KAFKA_BROKERS")
redis_host = System.get_env("REDIS_HOST")
listen_port = System.get_env("LISTEN_PORT") |> String.to_integer()

endpoints =
  kafka_brokers
  |> String.split(",")
  |> Enum.map(&String.trim/1)
  |> Enum.map(fn entry -> String.split(entry, ":") end)
  |> Enum.map(fn [host, port] -> {String.to_atom(host), String.to_integer(port)} end)

config :push_gateway,
  elsa_brokers: endpoints,
  port: listen_port,
  topic_prefix: "raw",
  assigned_dataset_id: assigned_dataset_id

config :push_gateway, :brook,
  instance: :push_gateway,
  driver: %{
    module: Brook.Driver.Kafka,
    init_arg: [
      endpoints: endpoints,
      topic: "event-stream",
      group: "push-gateway-event-stream",
      consumer_config: [
        begin_offset: :earliest
      ]
    ]
  },
  handlers: [PushGateway.Event.Handler],
  storage: [
    module: Brook.Storage.Redis,
    init_arg: [redix_args: [host: redis_host], namespace: "push-gateway:view"]
  ]
