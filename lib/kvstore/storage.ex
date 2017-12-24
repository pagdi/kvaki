defmodule Storage do
    @moduledoc """
    Модуль-обёртка для хранилища данных.
    Общение с циклом обработки фактически синхронное, но для наших целей этого достаточно.
    """

    def start() do
        # На старте пытаемся прочитать сериализованные данные.
        map=case File.read(defaultFilename()) do
            {:ok, binary} -> :erlang.binary_to_term(binary)
            _ -> %{} # Если файла нет, начинаем с пустого хранилища.
        end
        # Собственно запуск процесса хранилища.
        case Task.start_link(fn -> loop(map) end) do
            {:ok, pid} ->
                Process.register(pid, :storage)
            _ ->
                IO.puts "Cannot start the Storage, halting"
                System.halt(:abort)
        end
    end

    # Время жизни элемента данных по умолчанию.
    def defaultLife(), do: 10
    # Имя файла для записи/чтения сериализованного хранилища.
    def defaultFilename(), do: "kv.storage"

    # Установка/обновление элемента данных: пары "ключ-значение". @life есть время жизни элемента.
    def set(key, value, life), do: send(:storage, {:set, key, value, life})
    def set(key, value), do: send(:storage, {:set, key, value, defaultLife()})

    # Удаление всех хранимых значений.
    def purge(), do: send(:storage, {:purge})

    # Запрос значения по ключу. Значение отдаётся очищенным, без меток времени.
    def get(key) do
        send(:storage, {:get, self(), key})
        receive do
            {:get, _, value} -> value
        end
    end

    # Запрос всех элементов. Элементы отдаются в сыром виде, с метками времени.
    def all() do
        send(:storage, {:all, self()})
        receive do
            {:all, map} -> map
        end
    end

    # Цикл обработки.
    defp loop(map) do
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
                
        after
            # Каждую секунду вызываем "сборщик мусора".
            # Крайне неэффективно, зато просто.
            1000 ->
                gc(map)
        end
    end

    # "Сборка мусора" - удаление всех зажившихся на свете элементов.
    defp gc(map) do
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
