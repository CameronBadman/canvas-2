defmodule Drawing.Actors.Canvas do
  use GenServer
  
  def start_link(canvas_id) do
    IO.puts(canvas_id)
    state = %{
      canvas_id: canvas_id,
      elements: [],
      batch: []
    }
    GenServer.start_link(__MODULE__,
      state,
      name: {:via, Registry, {Drawing.CanvasRegistry, canvas_id}}
    ) 
  end
  
  def init(state) do
    schedule_flush()
    {:ok, state}
  end
  
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
  
  def handle_cast({:user_action, json_strings}, state) do
    new_state = %{state | batch: [json_strings | state.batch]}
    {:noreply, new_state}
  end

  def handle_info(:flush_batch, state) do
    case state.batch do
      [] -> 
        schedule_flush()
        {:noreply, state}
      batch_items -> 
        new_elements = batch_items ++ state.elements
        
        # Send each item individually
        Enum.each(Enum.reverse(batch_items), fn item ->
          Phoenix.PubSub.broadcast(Drawing.PubSub, "canvas_updates:#{state.canvas_id}", {:publish_objects, item})
        end)
        
        new_state = %{state | elements: new_elements, batch: []}
        schedule_flush()
        {:noreply, new_state}
    end
  end

  defp schedule_flush do
    Process.send_after(self(), :flush_batch, 2000)
  end

end
