defmodule PushGateway.Dispatcher do
  @moduledoc false

  require Logger
  use GenStage

  def start_link({number, init_args}) do
    name = :"#{__MODULE__}.#{number}"

    GenStage.start_link(__MODULE__, init_args, name: name)
  end

  def init(init_args) do
    processors = Keyword.get(init_args, :processors, 1)

    state = %{
      min: Keyword.get(init_args, :min_batch, 75),
      max: Keyword.get(init_args, :max_batch, 100)
    }

    subscription = processors(processors, state.min, state.max)

    {:consumer, %{}, subscribe_to: subscription}
  end

  def handle_events(messages, _from, state) do
    count = Enum.count(messages)
    Logger.info("Received #{count} messages: #{Jason.encode!(messages)}")

    {:noreply, [], state}
  end

  defp processors(count, min, max) do
    0..(count - 1)
    |> Enum.map(&subscriptions(&1, min, max))
  end

  defp subscriptions(item, min, max) do
    {processor_name(item), min_demand: min, max_demand: max}
  end

  defp processor_name(item), do: :"Elixir.PushGateway.Processor.#{item}"
end
