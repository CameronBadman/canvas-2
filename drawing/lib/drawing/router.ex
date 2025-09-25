defmodule Drawing.Router do
  use Plug.Router
  
  plug Plug.Logger
  plug :match
  plug :validate_canvas_id
  plug :dispatch
  


  get "/test_conn" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, 
    """
    <script>
    sock = new WebSocket("ws://localhost:4000/123456789")
    sock.addEventListener("message", console.log)
    sock.addEventListener("open", () => sock.send("ping"))
    </script>
    <p>Check your browser console for WebSocket messages!</p>
    """)
  end

  get "/ws/stats/:id" do
    id = conn.path_params["id"]
    send_resp(conn, 200, "stats on #{id}")
  end

  get "/ws/create/:id" do
    id = conn.path_params["id"]
    send_resp(conn, 200, "create canvas #{id}")
  end


  # NOTE TO Self put at bottom always
  get "/ws/:id" do
    id = conn.path_params["id"]
    conn
    |> WebSockAdapter.upgrade(DrawingAdapter, %{canvas_id: id}, timeout: 60_000)
    |> halt()
  end

  match _ do
    send_resp(conn, 404, "world1")
  end
  
  # this activates on any path that fits match using :plug
  defp validate_canvas_id(conn, _opts) do 
    case conn.path_params do
      %{"id" => id} ->
        if Regex.match?(~r/^[a-zA-Z0-9]{9}$/, id) do
          conn
        else
          conn
          |> send_resp(400, "incorrect")
          |> halt()
        end
      _ -> 
        conn
    end
  end
end
