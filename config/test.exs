use Mix.Config

config :push_gateway,
  port: 5555,
  processors: 2,
  min_batch: 75,
  max_batch: 100,
  elsa_brokers: [localhost: 9092],
  topic_prefix: "raw",
  assigned_dataset_id: "a-pushed-dataset-uuid"

config :push_gateway, :brook,
  instance: :push_gateway,
  driver: [
    module: Brook.Driver.Test,
    init_arg: []
  ],
  handlers: [PushGateway.Event.Handler],
  storage: [
    module: Brook.Storage.Ets,
    init_arg: []
  ],
  dispatcher: Brook.Dispatcher.Noop
