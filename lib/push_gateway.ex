defmodule PushGateway do
  @moduledoc false

  use GenStage
  require Logger

  def start_link(init_args), do: GenStage.start_link(__MODULE__, init_args, name: __MODULE__)

  def init(init_args) do
    state = %{
      port: Keyword.fetch!(init_args, :port),
      active: Keyword.get(init_args, :max_batch, 100),
      socket: nil,
      queue: []
    }

    {:ok, socket} = :gen_udp.open(state.port, [:binary, active: state.active])

    {:producer, %{state | socket: socket}}
  end

  def handle_demand(demand, state) do
    :ok = :inet.setopts(state.socket, active: demand)

    {:noreply, [], %{state | active: demand}}
  end

  def handle_info({:udp, _socket, _host, _in_port, payload}, %{queue: queue, active: size} = state)
      when length(queue) + 1 >= size do
    {:noreply, Enum.reverse([payload | queue]), %{state | queue: []}}
  end

  def handle_info({:udp, _socket, _host, _in_port, payload}, state) do
    {:noreply, [], %{state | queue: [payload | state.queue]}}
  end

  def handle_info({:udp_passive, socket}, state) do
    Logger.info("Socket #{inspect(socket)} entering passive mode")

    {:noreply, [], state}
  end
end
