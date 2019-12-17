defmodule PushGateway.Processor do
  @moduledoc false

  use GenStage

  def start_link({number, init_args}) do
    name = :"#{__MODULE__}.#{number}"

    GenStage.start_link(__MODULE__, init_args, name: name)
  end

  def init(init_args) do
    state = %{
      min: Keyword.get(init_args, :min_batch, 75),
      max: Keyword.get(init_args, :max_batch, 100)
    }

    subscription = [{PushGateway, min_demand: state.min, max_demand: state.max}]
    {:producer_consumer, state, subscribe_to: subscription}
  end

  def handle_events(messages, _from, state) do
    decoded_messages = Enum.map(messages, &Jason.decode!/1)

    {:noreply, decoded_messages, state}
  end
end
