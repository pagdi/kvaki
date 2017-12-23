defmodule Utils do
    @header """
    <html>
        <body>
        KVstore "syntax" guide:<br>
            - To read <i>value</i> by <i>key</i>: http://localhost:8000/?key<br>
            - To add/update <i>value</i> with <i>key</i>: http://localhost:8000/?key=value&life<br>
            (where <i>life</i> is seconds before <i>value</i> is removed. Default is 10s.)<br>
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
            pair(key, data[key].data)
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
                tail=hd(tl(parts))
                tailParts=String.split(tail, "&", parts: 2)
                value=hd(tailParts)
                life=case length(tailParts) do
                    1 ->
                        Storage.defaultLife()
                    2 ->
                        case Integer.parse(hd(tl(tailParts))) do
                            :error ->
                                Storage.defaultLife()
                            {integer, _} -> integer
                        end
                end
                Storage.set(key, value, life)
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
