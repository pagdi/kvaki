defmodule Storage do
    def start() do
        case Task.start_link(fn -> loop(%{}) end) do
            {:ok, pid} ->
                Process.register(pid, :storage)
            _ ->
                IO.puts "Cannot start the Storage, halting"
                System.halt(:abort)
        end
        set("1", "ONE")
        set("2", "tWo")
        set("3", "Enough already!")
    end

    def set(key, value) do
        send(:storage, {:set, key, value})
    end

    def get(key) do
        send(:storage, {:get, self(), key})
        receive do
            {:get, _, value} -> value
        end
    end

    def purge() do
        send(:storage, {:purge})
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

            {:set, key, value} ->
                loop(Map.merge(map, %{key => value}))

            {:get, from, key} ->
                send(from, {:get, key, Map.get(map, key)})
                loop(map)

            {:purge} ->
                loop(%{})
        end
    end
end
