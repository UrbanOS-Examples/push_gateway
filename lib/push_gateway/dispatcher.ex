defmodule PushGateway.Dispatcher do
  @moduledoc false

  use GenStage
  require Logger

  def start_link({number, init_args}) do
    name = :"#{__MODULE__}.#{number}"

    GenStage.start_link(__MODULE__, init_args, name: name)
  end

  def init(init_args) do
    producer_name = Keyword.fetch!(init_args, :producer_name)
    topic = Keyword.fetch!(init_args, :topic)
    processors = Keyword.get(init_args, :processors, 1)

    state = %{
      min: Keyword.get(init_args, :min_batch, 75),
      max: Keyword.get(init_args, :max_batch, 100)
    }

    subscription = processors(processors, state.min, state.max)

    {:consumer, %{topic: topic, producer_name: producer_name}, [subscribe_to: subscription]}
  end

  def handle_events(messages, _from, %{producer_name: producer_name, topic: topic} = state) do
    Logger.debug("Dispatching - #{Enum.count(messages)}")
    encoded_messages = Enum.map(messages, &Jason.encode!/1)
    Elsa.produce(producer_name, topic, encoded_messages, partition: 0)

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

defimpl Jason.Encoder, for: [Tuple] do
  def encode(tuple, opts) do
    Jason.Encode.list(Tuple.to_list(tuple), opts)
  end
end
