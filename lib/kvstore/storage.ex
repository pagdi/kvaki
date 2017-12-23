defmodule Storage do
    def start() do
        case Task.start_link(fn -> loop(%{}) end) do
            {:ok, pid} ->
                Process.register(pid, :storage)
            _ ->
                IO.puts "Cannot start the Storage, halting"
                System.halt(:abort)
        end
        set("1", "ONE", 10)
        set("2", "tWo", 20)
        set("3", "Enough already!", 30)
    end

    def defaultLife(), do: 10

    def set(key, value, life), do: send(:storage, {:set, key, value, life})
    def set(key, value), do: send(:storage, {:set, key, value, defaultLife()})
    def purge(), do: send(:storage, {:purge})

    def get(key) do
        send(:storage, {:get, self(), key})
        receive do
            {:get, _, value} -> value
        end
    end

    def all() do
        send(:storage, {:all, self()})
        receive do
            {:all, map} -> map
        end
    end

    defp loop(map) do
        receive do
            {:all, from} ->
                send(from, {:all, map})
                loop(map)

            {:set, key, value, life} ->
                newValue=%{data: value, created: DateTime.utc_now(), life: life}
                loop(Map.merge(map, %{key => newValue}))

            {:get, from, key} ->
                value=Map.get(map, key)
                data=case value do
                    nil -> nil
                    _ -> value.data
                end
                send(from, {:get, key, data})
#                send(from, {:get, key, Map.get(map, key).data})
                loop(map)

            {:purge} ->
                loop(%{})
        end
    end
end
