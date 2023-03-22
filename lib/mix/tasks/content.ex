defmodule Mix.Tasks.Content do
  @moduledoc """
  Create and manage content for the site.

  This launches the TUI for dynamic site management.

  See `mix help content.new` for more granular one off management
  """

  def run(_argv) do
    Ratatouille.run(Mix.Tasks.Content.UI, interval: 250)
  end
end
