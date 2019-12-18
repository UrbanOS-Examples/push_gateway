defmodule PushGateway.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    processors = Application.get_env(:push_gateway, :processors, 1)
    init_args = Application.get_all_env(:push_gateway)

    children =
      [
        {PushGateway, init_args},
        consumer_specs(PushGateway.Processor, processors, init_args),
        consumer_specs(PushGateway.Dispatcher, processors, init_args)
      ]
      |> List.flatten()

    opts = [strategy: :rest_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  defp consumer_specs(module, count, args) do
    0..(count - 1)
    |> Enum.map(&count_to_name(&1, module))
    |> Enum.map(&child_spec(&1, module, args))
  end

  defp child_spec({item, id}, module, args) do
    %{id: id, start: {module, :start_link, [{item, args}]}}
  end

  defp count_to_name(item, module), do: {item, consumer_name(module, item)}

  defp consumer_name(module, item), do: :"#{module}.#{item}"
end
