defmodule Mix.Tasks.Content.State do
  @moduledoc """
  Holds the state of the UI

  Provides helper functions for changing the state
  """

  defstruct [:title, :token, :url, :notes]
end
