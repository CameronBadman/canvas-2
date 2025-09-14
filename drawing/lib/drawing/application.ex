defmodule Drawing.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Bandit, plug: Drawing.Router, port: 4000},
      {Phoenix.PubSub, name: Drawing.PubSub},
      Drawing.Actors.Canvas,

    ]



    opts = [strategy: :one_for_one, name: Drawing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
