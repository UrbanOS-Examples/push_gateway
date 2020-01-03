use Mix.Config

host = "localhost"
endpoints = [{host, 9092}]

config :push_gateway,
  divo: [
    {DivoKafka, [create_topics: "event-stream:1:1", outside_host: host]},
    DivoRedis
  ],
  divo_wait: [dwell: 1000, max_tries: 120],
  elsa_brokers: endpoints,
  port: 5555,
  processors: 2,
  min_batch: 75,
  max_batch: 100,
  topic_prefix: "raw"

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
    init_arg: [redix_args: [host: host], namespace: "push-gateway:view"]
  ]

