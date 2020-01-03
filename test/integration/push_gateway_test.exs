defmodule PushGateway.Test do
  use ExUnit.Case
  use Divo

  import SmartCity.Event,
    only: [
      dataset_update: 0,
      data_ingest_start: 0
    ]

  alias SmartCity.TestDataGenerator, as: TDG
  import SmartCity.TestHelper, only: [eventually: 1]

  @instance :push_gateway
  @endpoints Application.get_env(:push_gateway, :elsa_brokers)
  @topic_prefix Application.get_env(:push_gateway, :topic_prefix)

  describe "receives #{dataset_update()} with the 'push' cadence" do
    setup do
      dataset = TDG.create_dataset(%{technical: %{cadence: "continuous"}})

      Brook.Event.send(@instance, dataset_update(), "testing", dataset)

      [dataset: dataset]
    end

    test "sends data:receive:start" do
      eventually(fn ->
        assert Elsa.Fetch.search_keys(@endpoints, "event-stream", "data:receive:start") |> Enum.to_list() |> length >= 1
      end)
    end

    test "sends #{data_ingest_start()}" do
      eventually(fn ->
        assert Elsa.Fetch.search_keys(@endpoints, "event-stream", data_ingest_start()) |> Enum.to_list() |> length >= 1
      end)
    end

    test "creates raw topic for dataset", %{dataset: dataset} do
      eventually(fn ->
        {:ok, topics} = Elsa.list_topics(@endpoints)
        assert {"#{@topic_prefix}-#{dataset.id}", 1} in topics
      end)
    end
  end
end
