defmodule Silbernageldev.WebMentions do
  @moduledoc """
  Handles queuing and coordinating for both sending and receiving WebMentions
  """

  alias Silbernageldev.WebMentions.WebMentionSupervisor
  alias Silbernageldev.WebMentions.WebMention


  @doc """
  Return the spec for the dynamic supervisor for web mentions
  """
  def supervisor_spec() do
    WebMentionSupervisor.child_spec([])
  end

  def capture_result(post, url, status) do
    hash = :crypto.hash(:sha256, [post.title, post.description, post.body]) |> Base.encode16

    attrs = %{
      source_id: post.id,
      source_type: :post,
      url: url,
      sha: hash,
      status: status
    }
    WebMention.changeset(attrs) 
  end

end
