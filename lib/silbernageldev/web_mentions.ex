defmodule Silbernageldev.WebMentions do
  @moduledoc """
  Handles queuing and coordinating for both sending and receiving WebMentions
  """

  alias Silbernageldev.WebMentions.WebMentionSupervisor

  @doc """
  Return the spec for the dynamic supervisor for web mentions
  """
  def supervisor_spec() do
    WebMentionSupervisor.child_spec([])
  end
end
