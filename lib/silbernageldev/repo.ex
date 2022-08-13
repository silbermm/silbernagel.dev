defmodule Silbernageldev.Repo do
  use Ecto.Repo,
    otp_app: :silbernageldev,
    adapter: Ecto.Adapters.SQLite3
end
