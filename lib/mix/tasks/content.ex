defmodule Mix.Tasks.Content do
  @moduledoc """
  Create and manage content for the site.

  This launches the TUI for dynamic site management.

  See `mix help content.new` for more granular one off management
  """

  def run(argv) do
    # {:ok, _started} = Application.ensure_all_started(:silbernageldev)
    {:ok, _started} = Application.ensure_all_started(:req)

    url =
      case OptionParser.parse(argv, strict: [url: :string]) do
        {opts, _, _} ->
          Keyword.get(opts, :url, "http://localhost:4000")

        _ ->
          "http://localhost:4000"
      end

    Mix.Tasks.Content.Store.start_link()

    case Mix.Tasks.GpgVerify.run(["--url", url <> "/verify", "matt@silbernagel.dev"]) do
      %{"token" => token} ->
        store_token(token)
        store_url(url)
        Ratatouille.run(Mix.Tasks.Content.UI, interval: 250)

      _ ->
        IO.puts("Unable to authenticate")
    end
  end

  defp store_token(token) do
    Mix.Tasks.Content.Store.save_token(token)
  end

  defp store_url(url) do
    Mix.Tasks.Content.Store.save_url(url)
  end
end
