defmodule Silbernageldev.WebMentions do
  @moduledoc """
  Handles queuing and coordinating for both sending and receiving WebMentions
  """
  import Ecto.Query

  use Silbernageldev.OpenTelemetry

  alias Silbernageldev.Blog.Post
  alias Silbernageldev.Repo
  alias Silbernageldev.WebMentions.WebMention
  alias Silbernageldev.WebMentions.Queue

  require Logger

  @log_prefix "[WebMentions] | "

  trace_all(kind: :internal)

  def change(changeset, params) do
    Ecto.Changeset.change(changeset, params)
  end

  def is_pending?(changeset) do
    status = Ecto.Changeset.get_field(changeset, :status)
    status == :pending
  end

  def send_webmention_for(changeset, source_url) do
    target = Ecto.Changeset.get_field(changeset, :webmention_endpoint)
    url = Ecto.Changeset.get_field(changeset, :url)

    Logger.info("#{@log_prefix} sending web mention for #{url} and #{source_url} #{target} ")

    case Req.post(target, form: [source: source_url, target: url]) do
      {:ok, %Req.Response{status: status, headers: _headers, body: _body}}
      when status >= 200 and status <= 300 ->
        Logger.info("#{@log_prefix} SUCCESS")
        Ecto.Changeset.change(changeset, %{status: :sent})

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("#{@log_prefix} Invalid request -- #{status}")
        Logger.error("#{@log_prefix} #{inspect(body)}")
        Ecto.Changeset.change(changeset, %{status: :failed})

      {:error, err} ->
        Logger.error("#{@log_prefix} #{inspect(err)}")
        Ecto.Changeset.change(changeset, %{status: :failed})
    end
  end

  @doc """
  Capture the result of a webmention discovery/request
  """
  def capture_result(changeset) do
    Repo.insert_or_update(changeset)
  end

  @doc """
  Checks the database if the link for the post has already been sent.

  If the record exists, check the hash of content to see if the post
  has been updated.

  If the post has been updated and the last webmention result was a
  success, a new webmention should be sent.
  """
  @spec check_webmention_result(Post.t(), binary()) :: WebMention.t() | nil
  def check_webmention_result(post, url) do
    WebMention
    |> where([wm], wm.url == ^url)
    |> where([wm], wm.source_id == ^post.id)
    |> Repo.one()
    |> case do
      nil ->
        WebMention.changeset(%{
          source_id: post.id,
          source_type: :post,
          sha: hash_post(post),
          url: url
        })

      web_mention_result ->
        maybe_build_changeset(post, web_mention_result)
    end
  end

  trace(kind: :internal)

  defp maybe_build_changeset(post, web_mention_result) do
    hash = hash_post(post)
    Logger.info("db hash = #{web_mention_result.sha}")
    Logger.info("current post hash = #{hash}")

    trace_attrs(hash: hash, post_id: post.id)

    if hash != web_mention_result.sha && web_mention_result.status == :sent do
      WebMention.changeset(web_mention_result, %{sha: hash})
    else
      nil
    end
  end

  @doc """
  Given a post, builds a hash of the title, description and body
  """
  def hash_post(post) do
    :crypto.hash(:sha512, [post.title, post.description, post.body]) |> Base.encode64()
  end

  @doc """
  Given a source and target URL queue the request
  """
  @spec queue_webmention_request(binary(), binary()) :: {:ok, map()}
  def queue_webmention_request(source, target), do: Queue.add(source, target)

  def valid?(source, target) do
    adapter = Application.get_env(:silbernageldev, WebMentions)[:adapter]
    adapter.valid?(source, target)
  end
end
