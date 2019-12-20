defmodule PushGateway.Event.Handler do
  use Brook.Event.Handler
  use Retry

  import SmartCity.Event,
    only: [
      dataset_update: 0,
      data_ingest_start: 0
    ]

  @instance :push_gateway

  def handle_event(%Brook.Event{type: dataset_update(), data: %SmartCity.Dataset{technical: %{cadence: "∞"}} = dataset}) do
    :ok = Brook.Event.send(@instance, data_ingest_start(), :push_gateway, dataset)
    :ok = Brook.Event.send(@instance, "data:receive:start", :push_gateway, dataset)

    :discard
  end

  def handle_event(%Brook.Event{type: data_ingest_start(), data: %SmartCity.Dataset{} = dataset}) do
    topic = topic(dataset)

    wait_for_condition!(fn -> Elsa.create_topic(endpoints(), topic) == :ok end)
    wait_for_condition!(fn -> Elsa.topic?(endpoints(), topic) end)

    :discard
  end

  defp wait_for_condition!(function) do
    wait exponential_backoff(500) |> Stream.take(5) do
      function.()
    after
      _ -> :ok
    else
      reason -> raise "Timed out waiting for condition with error #{inspect(reason)}"
    end
  end

  defp endpoints() do
    Application.get_env(:push_gateway, :elsa_brokers)
  end

  defp topic(dataset) do
    "#{topic_prefix()}-#{dataset.id}"
  end

  defp topic_prefix() do
    Application.get_env(:push_gateway, :topic_prefix)
  end

end
