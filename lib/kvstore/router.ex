defmodule KVstore.Router do
    use Plug.Router

    # По сути, бойлеры: пара стандартных штепселей для минимального приложения.
    plug :match
    plug :dispatch

    # Условия задача воспрещают создание специализированных штепселей,
    # поэтому маршрутизацию и собственно формирование отклика совместим прямо здесь.

    # Отклик на обычный запрос.
    defp contentType(conn), do: put_resp_content_type(conn, "text/html")
    # Извлечение запроса (то, что после "/?").
    defp extractQuery(conn), do: conn.query_string
    # Формирование ответа.
    defp response(conn), do: send_resp(contentType(conn), 200, Utils.page(extractQuery(conn)))

    # Отклик на обычный запрос.
    get "/", do: response(conn)

    # Отклик на запрос удаления всех элементов в хранилище.
    get "/purge" do 
        Storage.purge() # Это как раз оно - удаление.
        response(conn)
    end

    # Отклик на ошибочный запрос. Конкретную причину ошибки не анализируем, ибо безразлична.
    # По-хорошему, всё это должно выноситься в отдельные модули, но.
    match _, do: send_resp(conn, 404, "Wrong turn.")
end
