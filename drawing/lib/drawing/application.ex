defmodule Drawing.Application do
  @moduledoc false
  use Application
  
  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Drawing.Router, port: 4000},
      {Phoenix.PubSub, name: Drawing.PubSub},
      {Registry, keys: :unique, name: Drawing.CanvasRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Drawing.CanvasSupervisor}
    ]
    opts = [strategy: :one_for_one, name: Drawing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
