defmodule Drawing.Actors.CanvasSupervisor do
  def get_or_start_canvas_actor(canvas_id) do
    case Registry.lookup(Drawing.CanvasRegistry, canvas_id) do
      [{pid, _}] -> 
        {:ok, pid}
      [] -> 
        case DynamicSupervisor.start_child(
          Drawing.CanvasSupervisor, 
          {Drawing.Actors.Canvas, canvas_id}  
        ) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}  # Handle race condition
          error -> error
        end
    end
  end
end
