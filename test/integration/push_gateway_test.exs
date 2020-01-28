defmodule PushGateway.Test do
  use ExUnit.Case
  use Divo

  import SmartCity.Event,
    only: [
      dataset_update: 0,
      data_ingest_start: 0
    ]

  alias SmartCity.TestDataGenerator, as: TDG
  import SmartCity.TestHelper, only: [eventually: 1, eventually: 3]

  @instance :push_gateway
  @assigned_dataset_id Application.get_env(:push_gateway, :assigned_dataset_id)
  @endpoints Application.get_env(:push_gateway, :elsa_brokers)
  @topic_prefix Application.get_env(:push_gateway, :topic_prefix)

  setup_all do
    dataset = TDG.create_dataset(%{id: @assigned_dataset_id, technical: %{cadence: "continuous"}})

    Brook.Event.send(@instance, dataset_update(), "testing", dataset)

    [dataset: dataset]
  end

  describe "receives #{dataset_update()} with the 'push' cadence" do
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

    test "passes looped messages through UDP all the way to kafka", %{dataset: dataset} do
      test_message = DSRCMessages.bsm_message()
      test_message_angle = test_message.coreData.angle

      UdpSourceSocket.start_link(message_loop: [test_message], port: 5555)
      topic = "#{@topic_prefix}-#{dataset.id}"

      eventually(
        fn ->
          assert Elsa.topic?(@endpoints, topic)

          {:ok, _, messages} = Elsa.Fetch.fetch(@endpoints, topic)

          decoded_messages =
            messages
            |> Enum.map(&Map.get(&1, :value))
            |> Enum.map(&Jason.decode!/1)
            |> Enum.map(&Map.update(&1, "messageBody", "", fn x -> Jason.decode!(x) end))

          assert [
                   %{
                     "messageType" => "BSM",
                     "timestamp" => _,
                     "sourceDevice" => "udp-source-socket",
                     "messageBody" => %{"coreData" => %{"angle" => ^test_message_angle}}
                   }
                   | _
                 ] = decoded_messages
        end,
        1000,
        30
      )
    end
  end
end
