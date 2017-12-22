defmodule KVstore.Router do
    use Plug.Router

    plug :match
    plug :dispatch

    defp contentType(conn), do: put_resp_content_type(conn, "text/html")
    defp extractQuery(conn), do: conn.query_string
    defp response(conn), do: send_resp(contentType(conn), 200, Utils.page(extractQuery(conn)))

    get "/", do: response(conn)
    get "/purge" do
        Storage.purge()
        response(conn)
    end

    match _, do: send_resp(conn, 404, "Wrong turn.")
end
