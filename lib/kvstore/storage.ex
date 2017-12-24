defmodule Storage do
    @moduledoc """
    Модуль-обёртка для хранилища данных.
    Общение с циклом обработки фактически синхронное, но для наших целей этого достаточно.
    """

    def start(fresh) do
        # На старте пытаемся прочитать сериализованные данные.
        map=case fresh do
            false ->
                case File.read(defaultFilename()) do
                    {:ok, binary} -> :erlang.binary_to_term(binary)
                    _ -> %{} # Если файла нет, начинаем с пустого хранилища.
                end
            _ -> %{}
        end

        # Собственно запуск процесса хранилища.
        Process.register(spawn_link(Storage, :loop, [map]), defaultAtom())
    end

    # Атом-идентификатор хранилища
    def defaultAtom(), do: :storage
    # Время жизни элемента данных по умолчанию.
    def defaultLife(), do: 10
    # Имя файла для записи/чтения сериализованного хранилища.
    def defaultFilename(), do: "kv.storage"

    # Установка/обновление элемента данных: пары "ключ-значение". @life есть время жизни элемента.
    def set(key, value, life), do: send(defaultAtom(), {:set, key, value, life})
    def set(key, value), do: send(defaultAtom(), {:set, key, value, defaultLife()})

    # Удаление всех хранимых значений.
    def purge(), do: send(defaultAtom(), {:purge})

    # Запрос значения по ключу. Значение отдаётся очищенным, без меток времени.
    def get(key) do
        send(defaultAtom(), {:get, self(), key})
        receive do
            {:get, _, value} -> value
        end
    end

    # Запрос всех элементов. Элементы отдаются в сыром виде, с метками времени.
    def all() do
        send(defaultAtom(), {:all, self()})
        receive do
            {:all, map} -> map
        end
    end

    # Цикл обработки.
    def loop(map) do
        # Ecto у нас нет, поэтому на каждой итерации тупо скидываем слепок хранилища на диск.
        # Пока объём сериализованных данных <= 1/2 дискового кеша, достаточно эффективно.
        File.write!(defaultFilename(), :erlang.term_to_binary(map))

        # Выборка сообщений.
        receive do
            {:all, from} ->
                # Тривиально.
                send(from, {:all, map})
                loop(map)

            {:set, key, value, life} ->
                # При установке/обновлении элемента запоминаем время операции.
                # В данном случае коррекция времени не нужна.
                newValue=%{data: value, created: DateTime.utc_now(), life: life}
                # Можно было использовать Enum.into/2, но вдруг потребуется добавлять элементы пачками.
                loop(Map.merge(map, %{key => newValue}))

            {:get, from, key} ->
                # Тривиально.
                value=Map.get(map, key)
                data=case value do
                    nil -> nil
                    _ -> value.data
                end
                send(from, {:get, key, data})
                loop(map)

            {:purge} ->
                # Совсем тривиально.
                loop(%{})

            _ ->
                loop(map)

        after
            # Каждую секунду вызываем "сборщик мусора".
            # Крайне неэффективно, зато просто.
            1000 ->
                gc(map)
        end
    end

    # "Сборка мусора" - удаление всех зажившихся на свете элементов.
    def gc(map) do
        now=DateTime.utc_now()
        # Замыкаем текущее время.
        alive=fn(than, life) -> DateTime.diff(now, than) < life end
        # В лист собрать дешевле по тактам, чем сперва выбрать ключи, затем выдёргивать живых по ключам.
        list=for {key, value} <- Map.to_list(map), alive.(value.created, value.life), do: {key, value}
        # И снова в цикл.
        loop(listToMap(list))
    end

    # "Любовь к хвостовой рекурсии", холст, масло. Быстрее, чем chunk/2.
    def listToMap(list), do: listToMap(list, [])
    def listToMap([pair | xs], acc), do: listToMap(xs, [pair | acc])
    def listToMap(_, acc), do: Enum.into(acc, %{})
end
