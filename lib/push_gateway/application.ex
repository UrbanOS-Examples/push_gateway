defmodule PushGateway.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children =
      [
        {Brook, Application.get_env(:push_gateway, :brook)},
        {DynamicSupervisor, strategy: :one_for_one, name: PushGateway.DynamicSupervisor},
        PushGateway.InitServer
      ]
      |> List.flatten()

    opts = [strategy: :rest_for_one, name: PushGateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
