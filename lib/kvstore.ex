defmodule KVstore do
    use Application

    # Формальная точка входа в приложение
    # (на самом деле, конечно, всё начинается где-то в недрах каркаса).
    def start(_type, _args) do
        Storage.start() # Хранилище само разберётся со своими потоками.

        # Можно и без списка, но вдруг нам потребуется запустить более одного потомка.
        children=[ Plug.Adapters.Cowboy.child_spec(:http, KVstore.Router, [], port: 8000) ]
        Supervisor.start_link(children, strategy: :one_for_one)
    end
end
