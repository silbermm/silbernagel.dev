defmodule Silbernageldev.Repo do
  use Ecto.Repo,
    otp_app: :silbernageldev,
    adapter: Ecto.Adapters.SQLite3

  def replicate(func) do
    for node <- Node.list() do
      GenServer.cast({Silbernageldev.RepoReplication, node}, {:replicate, func})
    end
  end
end
