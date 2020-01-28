defmodule PushGateway.Processor do
  @moduledoc false

  use GenStage
  require Logger

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
    Logger.debug("Processing - #{Enum.count(messages)}")

    decoded_messages =
      messages
      |> Enum.map(&Jason.decode!/1)
      |> Enum.map(&decode_message_payload/1)
      |> Enum.map(&wrap_message_body/1)

    {:noreply, decoded_messages, state}
  end

  def decode_message_payload(message) do
    Map.update(message, "payloadData", %{}, &Kitt.decode!/1)
  end

  def wrap_message_body(%{"timestamp" => timestamp, "payloadData" => %{__struct__: message_type} = message}) do
    %{
      messageType: String.replace(Atom.to_string(message_type), "Elixir.Kitt.Message.", ""),
      messageBody: Jason.encode!(message),
      timestamp: DateTime.from_unix!(timestamp, :millisecond)
    }
  end
end
