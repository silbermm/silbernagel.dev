defmodule Silbernageldev.PromEx do
  @moduledoc false
  use PromEx, otp_app: :silbernageldev

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: SilbernageldevWeb.Router, endpoint: SilbernageldevWeb.Endpoint},
      Plugins.Ecto,
      Plugins.PhoenixLiveView
      # Add your own PromEx metrics plugins
      # Silbernageldev.Users.PromExPlugin
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "curl",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"}
      # {:prom_ex, "phoenix.json"},
      # {:prom_ex, "ecto.json"},
      # {:prom_ex, "oban.json"},
      # {:prom_ex, "phoenix_live_view.json"},
      # {:prom_ex, "absinthe.json"},
      # {:prom_ex, "broadway.json"},

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:silbernageldev, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end
