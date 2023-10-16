defmodule Silbernageldev.MixProject do
  use Mix.Project

  def project do
    [
      app: :silbernageldev,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [test: :test],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  def application do
    [
      mod: {Silbernageldev.Application, [Mix.env()]},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ssl_verify_fun, "~> 1.1", manager: :rebar3, override: true},
      {:atomex, "~> 0.5.1"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.6"},
      {:ecto_sqlite3, ">= 0.0.0"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.16"},
      {:floki, ">= 0.30.3"},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:gemtext_to_html, "~> 0.1.0"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:nimble_publisher, "~> 0.1.0"},
      {:makeup_elixir, ">= 0.0.0"},
      {:makeup_erlang, ">= 0.0.0"},
      {:makeup_eex, ">= 0.0.0"},
      {:makeup_html, ">= 0.0.0"},
      {:libcluster, "~> 3.3"},
      {:tailwind, "~> 0.1.6", runtime: Mix.env() == :dev},
      {:heroicons, "~> 0.5"},
      {:etag_plug, "~> 1.0"},
      {:req, "~> 0.4"},
      {:gpgmex, "~> 0.1"},
      {:libmention, "~> 0.1.4"},
      {:plug_attack, "~> 0.4.2"},
      {:logger_json, "~> 5.1"},
      {:opentelemetry_exporter, "~> 1.0"},
      {:opentelemetry, "~> 1.0"},
      {:opentelemetry_api, "~> 1.0"},
      {:opentelemetry_ecto, "~> 1.0"},
      {:opentelemetry_liveview, "~> 1.0.0-rc.4"},
      {:opentelemetry_phoenix, "~> 1.0"},
      {:opentelemetry_cowboy, "~> 0.2"},
      {:orbit, "~> 0.2.1"},
      {:prom_ex, "~> 1.8"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "tailwind default --minify", "phx.digest"]
    ]
  end
end
