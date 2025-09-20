defmodule Drawing.Actors.Canvas do
  use GenServer
  
  def start_link(canvas_id) do
    state = %{
      canvas_id: canvas_id,
      elements: []
    }
    GenServer.start_link(__MODULE__,
      state,
      name: {:via, Registry, {Drawing.CanvasRegistry, canvas_id}}
    ) 
  end
  
  def init(state) do
    Phoenix.PubSub.subscribe(Drawing.PubSub, "canvas_updates:#{state.canvas_id}")
    {:ok, state}
  end
  
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  
  def handle_info({:publish_objects, json_strings}, state) do
    IO.puts(json_strings)
    new_state = %{state | elements: [json_strings | state.elements]}
    {:noreply, new_state}
  end
end
