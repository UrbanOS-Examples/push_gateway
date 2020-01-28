defmodule UdpSourceSocket do
  @moduledoc false
  use GenServer

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(init_args) do
    port = Keyword.get(init_args, :port, 5555)

    message_loop =
      Keyword.get(init_args, :message_loop)
      |> Enum.map(&Kitt.encode!/1)

    {:ok, socket} = :gen_udp.open(port - 1)

    :timer.send_interval(100, :push_message)

    {:ok, %{socket: socket, port: port, message_loop: message_loop}}
  end

  def handle_info(:push_message, %{socket: socket, port: port, message_loop: message_loop} = state) do
    [message | rest] = message_loop
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    :gen_udp.send(
      socket,
      {127, 0, 0, 1},
      port,
      Jason.encode!(%{"timestamp" => timestamp, "deviceSource" => "udp-source-socket", "payloadData" => message})
    )

    {:noreply, %{state | message_loop: rest ++ [message]}}
  end
end
