defmodule Drawing.Actors.Canvas do
  use GenServer
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__) 
  end
  
  def init(state) do
    Phoenix.PubSub.subscribe(Drawing.PubSub, "canvas_updates")
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:publish_objects, json_strings}, state) do
    IO.puts(json_strings)
    new_state = [json_strings | state]
    {:noreply, new_state}
  end
  
end
