defmodule Silbernageldev.WebMentions.Adapters.Local do
  @moduledoc """
  A WebMention Behaviour that can be used for local development
  """

  @behaviour Silbernageldev.WebMentions.WebMentionBehaviour

  @doc """
  For local development, this will always return true
  except if the source is listed as an `invalid_source` via configuration.
  """
  @impl true
  def valid?(source, _target) do
    invalid_source_urls = Application.get_env(:silbernageldev, Silbernageldev.WebMentions)[:invalid_source_urls] || []
    invalid = source in invalid_source_urls

    !invalid
  end

end
