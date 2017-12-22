defmodule KVstore.Mixfile do
    use Mix.Project

    def project do
        [app: :kvstore,
        version: "0.1.0",
        elixir: "~> 1.3",
        build_embedded: Mix.env == :prod,
        start_permanent: Mix.env == :prod,
        deps: deps()]
    end

    def application do
        [
            applications: [:logger, :cowboy, :plug],
            mod: {KVstore, []}
        ]
    end

    defp deps do
        [
            {:plug, "~> 1.3.3"},
            {:cowboy, "~> 1.1.2"}
        ]
    end
end
