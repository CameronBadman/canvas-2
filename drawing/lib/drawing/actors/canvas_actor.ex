defmodule Drawing.Actors.CanvasActor do
  use GenServer

  def start_link(canvas_id) do
    GenServer.start_link(__MODULE__, canvas_id) 
  end

  def init(id) do
    {:ok, %{id: id}}
  end

  def handle_cast({:message_from_client, json_strings}, state) do
    Phoenix.PubSub.broadcast(Drawing.PubSub, "canvas_updates:#{state.id}", {:publish_objects, json_strings})
    {:noreply, state}
  end

end
