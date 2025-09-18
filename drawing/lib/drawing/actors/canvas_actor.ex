defmodule Drawing.Actors.CanvasActor do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}) 
  end

  def init(id) do
    {:ok, %{id: id}}
  end

  def handle_cast({:message_from_client, json_strings}, state) do
    Phoenix.PubSub.broadcast(Drawing.PubSub, "canvas_updates", {:publish_objects, json_strings})
    {:noreply, state}
  end

end
