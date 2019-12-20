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
    {:ok, brook} = Brook.start_link(Application.get_env(:push_gateway, :brook)
      |> Keyword.put(:instance, @instance))

    Brook.Test.register(@instance)

    on_exit(fn ->
      kill(brook)
    end)

    :ok
  end

  describe "receives #{dataset_update()} with the 'push' cadence" do
    setup do
      dataset = TDG.create_dataset(%{technical: %{cadence: "∞"}})

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

    test "sends #{data_ingest_start()}", %{dataset: dataset} do
      refute_receive {:brook_event, %Brook.Event{type: data_ingest_start(), data: ^dataset}}
    end

    test "sends data:receive:start", %{dataset: dataset} do
      refute_receive {:brook_event, %Brook.Event{type: "data:receive:start", data: ^dataset}}
    end
  end

  describe "receives ingest start" do
    setup do
      allow(Elsa.create_topic(any(), any()), seq: [{:error, "reason"}, :ok])
      allow(Elsa.topic?(any(), any()), seq: [false, true])

      dataset = TDG.create_dataset(%{technical: %{cadence: "∞"}})

      Brook.Test.send(@instance, data_ingest_start(), "testing", dataset)

      [dataset: dataset]
    end

    test "creates topic with retries", %{dataset: dataset} do
      assert_called(Elsa.create_topic(@endpoints, "#{@topic_prefix}-#{dataset.id}"), times(2))
    end
  end


  defp kill(pid) do
    ref = Process.monitor(pid)
    Process.exit(pid, :normal)
    assert_receive {:DOWN, ^ref, _, _, _}
  end
end
