defmodule Silbernageldev.WebMentions.WebMentionBehaviour do
  @moduledoc """

  """

  @type url :: binary()

  @doc """
  Given a source url and a target url, validate that 
  this is a valid webmention.

  Valid means that the source url actually has the
  target url embedded o in the HTML 
  """
  @callback valid?(url(), url()) :: boolean()
end
