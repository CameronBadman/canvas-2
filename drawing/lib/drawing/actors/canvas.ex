defmodule Drawing.Actors.Canvas do
  use GenServer
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__) 
  end
  
  def init(state) do
    {:ok, state}
  end

  def handle_cast({:publish_objects, json_strings}, current_list) do
    new_state = current_list ++ json_strings

    Phoenix.PubSub.broadcast(Drawing.PubSub, "canvas_updates", {:publish_objects, json_strings})

    {:noreply, new_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  
end
