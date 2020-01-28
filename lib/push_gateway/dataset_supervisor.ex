defmodule PushGateway.DatasetSupervisor do
  @moduledoc false
  use Supervisor
  use Retry

  def name(id), do: :"#{id}_supervisor"

  def ensure_started(start_options) do
    dataset = Keyword.fetch!(start_options, :dataset)
    :ok = ensure_stopped(dataset.id)

    DynamicSupervisor.start_child(PushGateway.DynamicSupervisor, {__MODULE__, start_options})
  end

  def ensure_stopped(dataset_id) do
    name = name(dataset_id)

    case Process.whereis(name) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(PushGateway.DynamicSupervisor, pid)
    end
  end

  def start_link(opts) do
    dataset = Keyword.fetch!(opts, :dataset)
    Supervisor.start_link(__MODULE__, opts, name: name(dataset.id))
  end

  def init(opts) do
    dataset = Keyword.fetch!(opts, :dataset)
    processors = Application.get_env(:push_gateway, :processors, 1)
    init_args = Application.get_all_env(:push_gateway)

    topic = topic(dataset)
    producer_name = :"#{topic}_producer"
    endpoints = endpoints()

    Elsa.create_topic(endpoints, topic)
    wait_for_condition!(fn -> Elsa.topic?(endpoints, topic) end)

    children =
      [
        {Elsa.Supervisor, [endpoints: endpoints, connection: producer_name, producer: [topic: topic]]},
        {PushGateway, init_args},
        consumer_specs(PushGateway.Processor, processors, init_args),
        consumer_specs(PushGateway.Dispatcher, processors, [init_args] ++ [topic: topic, producer_name: producer_name])
      ]
      |> List.flatten()

    Supervisor.init(children, strategy: :one_for_all)
  end

  def child_spec(args) do
    dataset = Keyword.fetch!(args, :dataset)

    super(args)
    |> Map.put(:id, name(dataset.id))
  end

  defp consumer_specs(module, count, args) do
    0..(count - 1)
    |> Enum.map(&count_to_name(&1, module))
    |> Enum.map(&genstage_child_spec(&1, module, args))
  end

  defp genstage_child_spec({item, id}, module, args) do
    %{id: id, start: {module, :start_link, [{item, args}]}}
  end

  defp count_to_name(item, module), do: {item, consumer_name(module, item)}

  defp consumer_name(module, item), do: :"#{module}.#{item}"

  defp endpoints() do
    Application.get_env(:push_gateway, :elsa_brokers)
  end

  defp topic(dataset) do
    "#{topic_prefix()}-#{dataset.id}"
  end

  defp topic_prefix() do
    Application.get_env(:push_gateway, :topic_prefix)
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
end
