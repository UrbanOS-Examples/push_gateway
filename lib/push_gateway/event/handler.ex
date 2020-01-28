defmodule PushGateway.Event.Handler do
  @moduledoc false
  use Brook.Event.Handler

  import SmartCity.Event,
    only: [
      dataset_update: 0,
      data_ingest_start: 0
    ]

  import Brook.ViewState,
    only: [
      merge: 3
    ]

  @instance :push_gateway

  def handle_event(%Brook.Event{
        type: dataset_update(),
        data: %SmartCity.Dataset{technical: %{cadence: "continuous"}} = dataset
      }) do
    if dataset.id == assigned_dataset_id() do
      :ok = Brook.Event.send(@instance, data_ingest_start(), :push_gateway, dataset)
      :ok = Brook.Event.send(@instance, "data:receive:start", :push_gateway, dataset)
    end

    :discard
  end

  def handle_event(%Brook.Event{
        type: data_ingest_start(),
        data: %SmartCity.Dataset{technical: %{cadence: "continuous"}} = dataset
      }) do
    if dataset.id == assigned_dataset_id() do
      {:ok, _} = PushGateway.DatasetSupervisor.ensure_started([dataset: dataset])

      merge(:datasets, dataset.id, dataset)
    else
      :discard
    end
  end

  defp assigned_dataset_id() do
    Application.get_env(:push_gateway, :assigned_dataset_id)
  end
end
