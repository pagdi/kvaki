defmodule Utils do
    @header """
    <html>
        <body>
        KVstore "syntax" guide:<br>
            - To read <i>value</i> by <i>key</i>: http://localhost:8000/?key<br>
            - To add/update <i>value</i> with <i>key</i>: http://localhost:8000/?key=value<br>
            <br>
            <a href="/">All values</a><br>
            <a href="/purge">Purge the storage</a><br><br>
    """
    @footer """
        </body></html>
    """

    defp pair(key, value) do
        "<i>" <> key <> "</i> = " <> value <> "<br>"
    end

    defp all() do
        data=Storage.all()
        for key <- Map.keys(data) do
            pair(key, data[key])
        end
        |> Enum.join
    end

    defp bodyFromGet(key) do
        value=Storage.get(key)
        case value do
            nil -> "Key requested: <i>" <> key <> "</i>, but no value found"
            _ -> "Key requested: " <> pair(key, value)
        end
    end

    defp bodyFromSet(key, value) do
        "Value set: " <> pair(key, value)
    end

    defp bodyFromQuery(query) do
        parts=String.split(query, "=", parts: 2)
        case length(parts) do
            1 ->
                bodyFromGet(hd(parts))
            2 ->
                key=hd(parts)
                value=hd(tl(parts))
                Storage.set(key, value)
                bodyFromSet(key, value)
        end
    end

    def page(query) do
        body=case query do
            "" -> all()
            _ -> bodyFromQuery(query)
        end
        @header <> body <> @footer
    end
end
