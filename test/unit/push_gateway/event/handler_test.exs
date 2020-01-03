defmodule PushGateway.Event.HandlerTest do
  use ExUnit.Case
  use Placebo
  require Logger

  import SmartCity.Event,
    only: [
      dataset_update: 0,
      data_ingest_start: 0
    ]

  alias SmartCity.TestDataGenerator, as: TDG

  @instance :push_gateway
  @endpoints Application.get_env(:push_gateway, :elsa_brokers)
  @topic_prefix Application.get_env(:push_gateway, :topic_prefix)

  setup do
    Brook.Test.clear_view_state(@instance, :datasets)

    Brook.Test.register(@instance)

    :ok
  end

  describe "receives #{dataset_update()} with the 'push' cadence" do
    setup do
      dataset = TDG.create_dataset(%{technical: %{cadence: "continuous"}})

      Brook.Test.send(@instance, dataset_update(), "testing", dataset)

      [dataset: dataset]
    end

    test "sends #{data_ingest_start()}", %{dataset: dataset} do
      assert_receive {:brook_event, %Brook.Event{type: data_ingest_start(), data: ^dataset}}
    end

    test "sends data:receive:start", %{dataset: dataset} do
      assert_receive {:brook_event, %Brook.Event{type: "data:receive:start", data: ^dataset}}
    end
  end

  describe "receives #{dataset_update()} without the 'push' cadence" do
    setup do
      dataset = TDG.create_dataset(%{technical: %{cadence: "once"}})

      Brook.Test.send(@instance, dataset_update(), "testing", dataset)

      [dataset: dataset]
    end

    test "does not send #{data_ingest_start()}", %{dataset: dataset} do
      refute_receive {:brook_event, %Brook.Event{type: data_ingest_start(), data: ^dataset}}
    end

    test "does not send data:receive:start", %{dataset: dataset} do
      refute_receive {:brook_event, %Brook.Event{type: "data:receive:start", data: ^dataset}}
    end
  end

  describe "receives ingest start" do
    setup do
      allow(Elsa.create_topic(any(), any()), seq: [{:error, "reason"}, :ok])
      allow(Elsa.topic?(any(), any()), seq: [false, true])

      dataset = TDG.create_dataset(%{technical: %{cadence: "continuous"}})

      Brook.Test.send(@instance, data_ingest_start(), "testing", dataset)

      [dataset: dataset]
    end

    test "creates topic with retries", %{dataset: dataset} do
      assert_called(Elsa.create_topic(@endpoints, "#{@topic_prefix}-#{dataset.id}"), times(2))
    end

    test "saves the dataset to its view state", %{dataset: dataset} do
      assert {:ok, ^dataset} = Brook.ViewState.get(@instance, :datasets, dataset.id)
    end
  end
end
