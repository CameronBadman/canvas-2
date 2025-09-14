defmodule Drawing.Actors.CanvasSlave do
  use GenServer

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__) 
  end

  def init(id) do
    {:ok, %{id: id}}
  end

  






end
