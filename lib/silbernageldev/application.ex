defmodule Silbernageldev.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      Silbernageldev.Repo,
      SilbernageldevWeb.Telemetry,
      {Phoenix.PubSub, name: Silbernageldev.PubSub},
      SilbernageldevWeb.Endpoint,
      {Cluster.Supervisor, [topologies, [name: Silbernagedev.ClusterSupervisor]]},
      {Silbernageldev.RepoReplication, []}
    ]

    opts = [strategy: :one_for_one, name: Silbernageldev.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SilbernageldevWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
