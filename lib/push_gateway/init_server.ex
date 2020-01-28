defmodule PushGateway.InitServer do
  @moduledoc false

  use GenServer

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(_opts) do
    case Brook.get(:push_gateway, :datasets, assigned_dataset_id()) do
      {:ok, nil} ->
        :ignore

      {:ok, dataset} ->
        PushGateway.DatasetSupervisor.ensure_started([dataset: dataset])
    end
  end

  defp assigned_dataset_id() do
    Application.get_env(:push_gateway, :assigned_dataset_id)
  end
end
