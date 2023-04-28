defmodule Silbernageldev.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, [:dev]) do
    Silbernageldev.Instrumenter.setup()

    children = children()

    opts = [strategy: :one_for_one, name: Silbernageldev.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start(_type, _args) do
    Silbernageldev.Instrumenter.setup()
    topologies = Application.get_env(:libcluster, :topologies) || []

    children =
      children() ++
        [
          {Cluster.Supervisor, [topologies, [name: Silbernagedev.ClusterSupervisor]]},
          Silbernageldev.WebMentions.supervisor_spec()
        ]

    opts = [strategy: :one_for_one, name: Silbernageldev.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children() do
    [
      Silbernageldev.Repo,
      SilbernageldevWeb.Telemetry,
      {Phoenix.PubSub, name: Silbernageldev.PubSub},
      SilbernageldevWeb.Endpoint,
      {Silbernageldev.RepoReplication, []},
      {Task.Supervisor, name: Silbernageldev.TaskSupervisor},
      {PlugAttack.Storage.Ets,
       name: SilbernageldevWeb.Plugs.PlugAttack.storage_name(), clean_period: :timer.seconds(60)},
      SilbernageldevWeb.Plugs.Silberauth
    ]
  end

  @impl true
  def config_change(changed, _new, removed) do
    SilbernageldevWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
