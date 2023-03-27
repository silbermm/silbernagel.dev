defmodule Mix.Tasks.Content do
  @moduledoc """
  Create and manage content for the site.

  This launches the TUI for dynamic site management.

  See `mix help content.new` for more granular one off management
  """

  def run(_argv) do
    {:ok, _started} = Application.ensure_all_started(:silbernageldev)
    {:ok, _started} = Application.ensure_all_started(:req)
    Mix.Tasks.Content.Store.Token.start_link()
    # authenticate and store the token in ets for access later
    url = SilbernageldevWeb.Endpoint.url() <> "/verify"

    case Mix.Tasks.GpgVerify.run(["--url", url, "matt@silbernagel.dev"]) do
      %{"token" => token} ->
        store_token(token)
        Ratatouille.run(Mix.Tasks.Content.UI, interval: 250)

      _ ->
        IO.puts("Unable to authenticate")
    end
  end

  defp store_token(token) do
    Mix.Tasks.Content.Store.Token.save_token(token)
  end
end
