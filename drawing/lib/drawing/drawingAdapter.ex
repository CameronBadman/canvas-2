defmodule DrawingAdapter do
  @behaviour WebSock
  
  def init(opts) do
    canvas_id = opts[:canvas_id]
    
    {:ok, canvas_pid} = Drawing.Actors.CanvasSupervisor.get_or_start_canvas_actor(canvas_id)

    state = %{
      canvas_id: canvas_id,
      canvas_pid: canvas_pid
    }

    Phoenix.PubSub.subscribe(Drawing.PubSub, "canvas_updates:#{canvas_id}")
    
    canvas_state = GenServer.call(canvas_pid, :get_state)    
    case canvas_state.elements do
      [] -> :ok
      elements -> 
      Enum.each(elements, fn element ->
        send(self(), {:publish_objects, element})
        end)
    end 

    {:ok, state}
  end
  
  def handle_in({json_strings, [opcode: :text]}, state) do
    GenServer.cast(state.canvas_pid, {:user_action, json_strings})
    {:ok, state}
  end
  
  def handle_info({:publish_objects, json_strings}, state) do
    {:push, {:text, json_strings}, state} 
  end
  
  def terminate(_reason, _state) do
    :ok
  end
end
