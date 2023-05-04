defmodule Silbernageldev.WebMentions do
  @moduledoc """
  Handles queuing and coordinating for both sending and receiving WebMentions
  """
  import Ecto.Query

  use Silbernageldev.OpenTelemetry

  alias Silbernageldev.Repo
  alias Silbernageldev.WebMentions.WebMentionSupervisor
  alias Silbernageldev.WebMentions.WebMention

  require Logger

  trace_all(kind: :internal)

  @doc """
  Return the spec for the dynamic supervisor for web mentions
  """
  def supervisor_spec() do
    WebMentionSupervisor.child_spec([])
  end

  @doc """
  Capture the result of a webmention discovery/request
  """
  def capture_result(post, url, status) do
    hash = hash_post(post)

    trace_attrs(hash: hash, post_id: post.id)

    attrs = %{
      source_id: post.id,
      source_type: :post,
      url: url,
      sha: hash,
      status: status
    }

    attrs
    |> WebMention.changeset()
    |> Repo.insert()
  end

  @doc """
  Checks the database if the link for the post has already been sent.

  If the record exists, check the hash of content to see if the post
  has been updated.

  If the post has been updated and the last webmention result was a
  success, a new webmention should be sent.
  """
  def check_webmention_result(post, url) do
    WebMention
    |> where([wm], wm.url == ^url)
    |> where([wm], wm.source_id == ^post.id)
    |> Repo.one()
    |> case do
      nil -> :empty
      web_mention_result -> determine_status(post, web_mention_result)
    end
  end

  trace(kind: :internal)

  defp determine_status(post, web_mention_result) do
    hash = hash_post(post)
    Logger.info("db hash = #{web_mention_result.sha}")
    Logger.info("current post hash = #{hash}")

    trace_attrs(hash: hash, post_id: post.id)

    if hash != web_mention_result.sha && web_mention_result.status == :sent do
      :update
    else
      :complete
    end
  end

  def hash_post(post) do
    :crypto.hash(:sha256, [post.title, post.description, post.body]) |> Base.encode16()
  end
end
