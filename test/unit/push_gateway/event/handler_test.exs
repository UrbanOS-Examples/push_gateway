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
  @assigned_dataset_id Application.get_env(:push_gateway, :assigned_dataset_id)

  setup do
    Brook.Test.clear_view_state(@instance, :datasets)

    Brook.Test.register(@instance)

    :ok
  end

  describe "receives #{dataset_update()} with the 'push' cadence" do
    setup do
      dataset = TDG.create_dataset(%{id: @assigned_dataset_id, technical: %{cadence: "continuous"}})

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

  describe "receives #{dataset_update()} with 'push' cadence but not the one it cares about" do
    setup do
      dataset = TDG.create_dataset(%{id: "not-the-push-you-are-looking-for", technical: %{cadence: "continuous"}})

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

  describe "receives #{data_ingest_start()} event" do
    setup do
      allow(
        DynamicSupervisor.start_child(any(), any()),
        return: {:ok, :good}
      )
      allow(
        DynamicSupervisor.terminate_child(any(), any()),
        return: :ok
      )

      dataset = TDG.create_dataset(%{id: @assigned_dataset_id, technical: %{cadence: "continuous"}})

      Brook.Test.send(@instance, data_ingest_start(), "testing", dataset)

      [dataset: dataset]
    end

    test "starts a dataset supervisor", %{dataset: dataset} do
      assert_called(
        DynamicSupervisor.start_child(
          PushGateway.DynamicSupervisor,
          {PushGateway.DatasetSupervisor, [dataset: dataset]}
        )
      )
    end

    test "saves the dataset to its view state", %{dataset: dataset} do
      assert {:ok, ^dataset} = Brook.ViewState.get(@instance, :datasets, dataset.id)
    end
  end

  describe "idempotentency of #{data_ingest_start()} event" do
    test "it is idmptnt" do
      allow(PushGateway.DatasetSupervisor.init(any()), return: Supervisor.init([TestHelper.dummy_child_spec()], strategy: :one_for_all), meck_options: [:passthrough])

      dataset = TDG.create_dataset(%{id: @assigned_dataset_id, technical: %{cadence: "continuous"}})

      Brook.Test.send(@instance, data_ingest_start(), "testing", dataset)

      assert %{active: 1, specs: 1, supervisors: 1, workers: 0} == DynamicSupervisor.count_children(PushGateway.DynamicSupervisor)

      Brook.Test.send(@instance, data_ingest_start(), "testing", dataset)

      assert %{active: 1, specs: 1, supervisors: 1, workers: 0} == DynamicSupervisor.count_children(PushGateway.DynamicSupervisor)
    end
  end

  describe "receives ingest start for 'push' dataset that it does not care about" do
    setup do
      allow(
        DynamicSupervisor.start_child(any(), any()),
        return: {:ok, :good}
      )

      dataset = TDG.create_dataset(%{id: "because-star-wars-get-it", technical: %{cadence: "continuous"}})

      Brook.Test.send(@instance, data_ingest_start(), "testing", dataset)

      [dataset: dataset]
    end

    test "does not start a dataset supervisor", %{dataset: dataset} do
      refute_called(
        DynamicSupervisor.start_child(
          PushGateway.DynamicSupervisor,
          {PushGateway.DatasetSupervisor, [dataset: dataset]}
        )
      )
    end

    test "does not save the dataset to its view state", %{dataset: dataset} do
      assert {:ok, nil} = Brook.ViewState.get(@instance, :datasets, dataset.id)
    end
  end
end
