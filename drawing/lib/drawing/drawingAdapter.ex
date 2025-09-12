defmodule DrawingAdapter do
  @behaviour WebSock

  def init(opts) do
    canvas_id = opts[:canvas_id]
    state = %{
      canvas_id: canvas_id
    }
    {:ok, state}
  end

  def handle_in({msg, [opcode: :text]}, state) do
    IO.puts("Echo: #{msg}")
    {:reply, :ok, {:text, "Echo: #{msg}"}, state}
  end

  def handle_info({:broadcast, message}, state) do
    {:push, {:text, message}, state} 
  end

end
