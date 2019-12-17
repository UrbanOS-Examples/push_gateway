defmodule PushGatewayTest do
  @moduledoc false

  use ExUnit.Case
  import ExUnit.CaptureLog

  setup_all do
    UdpSourceSocket.start_link(message_loop: ["a", "b", "c", "d", "e"], port: 5555)

    :ok
  end

  test "logs messages with JSON encoding" do
    log_messages =
      capture_log(fn ->
        Process.sleep(15_000)
      end)

    %{"messages" => raw_messages} = Regex.named_captures(~r/Received [0-9]+ messages: (?<messages>.*)/, log_messages)

    actual_messages = MapSet.new(Jason.decode!(raw_messages))

    expected_messages =
      MapSet.new([
        %{"message" => "a"},
        %{"message" => "b"},
        %{"message" => "c"},
        %{"message" => "d"},
        %{"message" => "e"}
      ])

    assert actual_messages == expected_messages
  end
end

defmodule UdpSourceSocket do
  use GenServer

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(init_args) do
    port = Keyword.get(init_args, :port, 5555)
    message_loop = Keyword.get(init_args, :message_loop)

    {:ok, socket} = :gen_udp.open(port - 1)

    :timer.send_interval(100, :push_message)

    {:ok, %{socket: socket, port: port, message_loop: message_loop}}
  end

  def handle_info(:push_message, %{socket: socket, port: port, message_loop: message_loop} = state) do
    [message | rest] = message_loop
    :gen_udp.send(socket, {127, 0, 0, 1}, port, Jason.encode!(%{message: message}))

    {:noreply, %{state | message_loop: rest ++ [message]}}
  end
end
