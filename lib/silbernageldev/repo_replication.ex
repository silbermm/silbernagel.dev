defmodule Silbernageldev.RepoReplication do
  @moduledoc """
  Run on each node to handle replicating Repo writes
  """
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:replicate, func}, state) do
    res = func.()
    {:noreply, [{func, res} | state]}
  end
end
