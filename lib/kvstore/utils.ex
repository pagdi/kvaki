defmodule Utils do
    @moduledoc """
    В этом модуле делается основная работа по формированию страниц.
    Люди мы бедные, но гордые - обойдёмся без шаблонизатора.
    """

    # Заголовок формируемой страницы.
    @header """
    <html>
        <body>
        KVstore "syntax" guide:<br>
            - To read <i>value</i> by <i>key</i>: http://localhost:8000/?<b>key</b><br>
            - To add/update <i>value</i> with <i>key</i>: http://localhost:8000/?<b>key=value&life</b><br>
            (where <i>life</i> is optional seconds before <i>value</i> is removed. Default is 10s.)<br>
            <br>
            <a href="/">All values</a><br>
            <a href="/purge">Purge the storage</a><br><br>
    """

    # Подвал формируемой страницы.
    @footer """
        </body></html>
    """

    # Формирование строки в таблице значений.
    def pair(key, value), do: "<i>" <> key <> "</i> = " <> value <> "<br>"

    # Формирование таблицы всех значений.
    defp all() do
        data=Storage.all()
        for key <- Map.keys(data) do # Накапливаем список строк.
            pair(key, data[key].data)
        end
        |> Enum.join # Склеиваем список во фрагмент HTML.
    end

    # Формирование тела страницы после запроса значения.
    defp bodyFromGet(key) do
        value=Storage.get(key)
        case value do
            nil -> "Key requested: <i>" <> key <> "</i>, but no value found"
            _ -> "Key requested: " <> pair(key, value)
        end
    end

    # Формирование тела страницы после установки значения.
    defp bodyFromSet(key, value), do: "Value set: " <> pair(key, value)

    # Формирование тела страницы согласно строке запроса @query.
    # Функция остро нуждается в рефакторинге, но если я зарефакторю её сразу,
    # то не смогу ненавязчиво продемонстрировать, что знаю слово "рефакторинг".
    defp bodyFromQuery(query) do
        parts=String.split(query, "=", parts: 2) # "key/=/value"
        case length(parts) do
            1 -> # Тривиальный случай: запрос по ключу.
                bodyFromGet(hd(parts))
            2 -> # Случай сложнее: установка значения.
                key=hd(parts)
                tail=hd(tl(parts))
                tailParts=String.split(tail, "&", parts: 2) # "value/&/life"
                value=hd(tailParts)
                life=case length(tailParts) do # Извлекаем время жизни в секундах.
                    1 ->
                        Storage.defaultLife()
                    2 ->
                        # Убеждаемся, что в запросе время указано корректно.
                        case Integer.parse(hd(tl(tailParts))) do
                            :error ->
                                Storage.defaultLife()
                            {integer, _} -> integer
                        end
                end
                Storage.set(key, value, life) # Наконец устанавливаем значение.
                bodyFromSet(key, value) # И формируем страницу.
        end
    end

    # Формирование полной страницы.
    def page(query) do
        body=case query do
            "" -> all()
            _ -> bodyFromQuery(query)
        end
        @header <> body <> @footer
    end
end
