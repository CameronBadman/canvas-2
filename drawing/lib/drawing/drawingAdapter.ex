defmodule DrawingAdapter do
  @behaviour WebSock

  def init(opts) do
    {:ok, actor_pid} = Drawing.Actors.CanvasActor.start_link(:ok)
    canvas_id = opts[:canvas_id]
    state = %{
      canvas_id: canvas_id,
      actor_pid: actor_pid
    }
    Phoenix.PubSub.subscribe(Drawing.PubSub, "canvas_updates")
    {:ok, state}
  end

  def handle_in({msg, [opcode: :text]}, state) do
    
    GenServer.cast(state.actor_pid, {:message_from_client, msg})
    {:ok, state}
  end

  def handle_info({:publish_objects, json_strings}, state) do
    {:push, {:text, json_strings}, state} 
  end

  def terminate(_reason, state) do
    if state[:actor_pid] do
      GenServer.stop(state.actor_pid, :normal) 
    end
    :ok
  end

end
