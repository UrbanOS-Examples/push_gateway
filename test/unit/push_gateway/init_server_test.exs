defmodule PushGateway.InitServerTest do
  use ExUnit.Case
  use Placebo

  alias SmartCity.TestDataGenerator, as: TDG

  @instance :push_gateway
  @assigned_dataset_id Application.get_env(:push_gateway, :assigned_dataset_id)

  import Brook.ViewState,
    only: [
      merge: 3
    ]

  setup do
    Brook.Test.clear_view_state(@instance, :datasets)
    Brook.Test.register(@instance)

    dataset_one = TDG.create_dataset(%{})
    dataset_two = TDG.create_dataset(%{id: @assigned_dataset_id})
    datasets = [dataset_one, dataset_two]

    Brook.Test.with_event(@instance, fn ->
      Enum.each(datasets, fn dataset ->
        merge(:datasets, dataset.id, dataset)
      end)
    end)

    [dataset_one: dataset_one, dataset_two: dataset_two]
  end

  describe "init/1" do
    test "starts a dataset supervisor for only the dataset assigned to this push gateway", %{
      dataset_one: dataset_one,
      dataset_two: dataset_two
    } do
      allow(
        DynamicSupervisor.start_child(any(), any()),
        return: {:ok, :good}
      )
      allow(
        DynamicSupervisor.terminate_child(any(), any()),
        return: :ok
      )

      PushGateway.InitServer.init([])

      refute_called(
        DynamicSupervisor.start_child(
          PushGateway.DynamicSupervisor,
          {PushGateway.DatasetSupervisor, [dataset: dataset_one]}
        )
      )

      assert_called(
        DynamicSupervisor.start_child(
          PushGateway.DynamicSupervisor,
          {PushGateway.DatasetSupervisor, [dataset: dataset_two]}
        )
      )
    end

    test "returns error tuple when a child process fails to start" do
      allow(
        DynamicSupervisor.start_child(any(), any()),
        return: {:error, :bad}
      )
      allow(
        DynamicSupervisor.terminate_child(any(), any()),
        return: :ok
      )

      assert {:error, _} = PushGateway.InitServer.init([])
    end
  end
end
