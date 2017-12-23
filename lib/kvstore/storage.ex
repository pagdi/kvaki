defmodule Storage do
    def start() do
        map=:erlang.binary_to_term(File.read!(defaultFilename()))
        case Task.start_link(fn -> loop(map) end) do
            {:ok, pid} ->
                Process.register(pid, :storage)
            _ ->
                IO.puts "Cannot start the Storage, halting"
                System.halt(:abort)
        end
    end

    def defaultLife(), do: 10
    def defaultFilename(), do: "kv.storage"

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
        File.write!(defaultFilename(), :erlang.term_to_binary(map))
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
                loop(map)

            {:purge} ->
                loop(%{})
                
        after
            1000 ->
                gc(map)
        end
    end

    defp gc(map) do
        now=DateTime.utc_now()
        alive=fn(than, life) -> DateTime.diff(now, than) < life end
        list=for {key, value} <- Map.to_list(map), alive.(value.created, value.life), do: {key, value}
        loop(listToMap(list))
    end

    def listToMap(list), do: listToMap(list, [])
    def listToMap([pair | xs], acc), do: listToMap(xs, [pair | acc])
    def listToMap(_, acc), do: Enum.into(acc, %{})
end
