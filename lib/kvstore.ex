defmodule KVstore do
    use Application

    def start(_type, _args) do
        Storage.start()

        children=[
            Plug.Adapters.Cowboy.child_spec(:http, KVstore.Router, [], port: 8000)
        ]

        Supervisor.start_link(children, strategy: :one_for_one)
    end

    def stop(_app) do
    end
end
