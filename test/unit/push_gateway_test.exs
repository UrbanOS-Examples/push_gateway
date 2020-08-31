defmodule PushGatewayTest do
  @moduledoc false

  use ExUnit.Case
  use Placebo

  import SmartCity.Event,
    only: [
      data_ingest_start: 0
    ]

  alias SmartCity.TestDataGenerator, as: TDG
  import SmartCity.TestHelper, only: [eventually: 3]

  @instance :push_gateway
  @topic_prefix Application.get_env(:push_gateway, :topic_prefix)
  @assigned_dataset_id Application.get_env(:push_gateway, :assigned_dataset_id)

  @test_bsm_message DSRCMessages.bsm_message()
  @test_srm_message DSRCMessages.srm_message()
  @test_bsm_message_destructed @test_bsm_message |> Jason.encode!() |> Jason.decode!()
  @test_srm_message_destructed @test_srm_message |> Jason.encode!() |> Jason.decode!()

  setup_all do
    UdpSourceSocket.start_link(message_loop: [@test_bsm_message, @test_srm_message], port: 5555)
    Brook.Test.clear_view_state(@instance, :datasets)
    Brook.Test.register(@instance)

    :ok
  end

  test "sends messages to kafka with JSON encoding" do
    allow(Elsa.create_topic(any(), any()), return: :ok)
    allow(Elsa.topic?(any(), any()), return: true)
    allow(Elsa.produce(any(), any(), any(), partition: 0), return: :ok)

    allow(Elsa.Supervisor.init(any()),
      return: Supervisor.init([TestHelper.dummy_child_spec()], strategy: :one_for_all),
      meck_options: [:passthrough]
    )

    dataset = TDG.create_dataset(%{id: @assigned_dataset_id, technical: %{cadence: "continuous"}})
    Brook.Test.send(@instance, data_ingest_start(), :unit, dataset)

    expected_messages = [
      %{"messageType" => "BSM", "sourceDevice" => "udp-source-socket", "messageBody" => @test_bsm_message_destructed},
      %{"messageType" => "SRM", "sourceDevice" => "udp-source-socket", "messageBody" => @test_srm_message_destructed}
    ]

    eventually(
      fn ->
        actual_messages =
          get_produced_messages("#{@topic_prefix}-#{dataset.id}")
          |> Enum.map(&SmartCity.Data.new/1)
          |> Enum.map(&elem(&1, 1))
          |> Enum.map(&Map.get(&1, :payload))
          |> strip_timestamps()
          |> Enum.uniq()
          |> Enum.sort_by(&Map.get(&1, "messageType"))

        assert expected_messages == actual_messages
      end,
      500,
      20
    )
  end

  defp get_produced_messages(topic) do
    capture(Elsa.produce(any(), topic, any(), partition: 0), 3)
  rescue
    _ -> []
  end

  defp strip_timestamps(messages) do
    Enum.map(messages, &Map.delete(&1, "timestamp"))
  end
end
