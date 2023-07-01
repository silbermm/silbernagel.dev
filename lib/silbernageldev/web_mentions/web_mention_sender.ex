defmodule Silbernageldev.WebMentions.WebMentionSender do
  @moduledoc """
  A process that searches content and sends webmentions
  where needed
  """
  use GenServer, restart: :temporary
  use Silbernageldev.OpenTelemetry

  require Logger

  trace_all(kind: :internal)

  @log_prefix "[WebMentionSender] |"

  def start_link(content_type), do: GenServer.start_link(__MODULE__, content_type)

  trace(kind: :internal)

  @impl true
  def init(content_type) do
    Logger.metadata(content_type: content_type)

    case content_type do
      :posts ->
        url_fn = fn post_id ->
          SilbernageldevWeb.Router.Helpers.blog_url(SilbernageldevWeb.Endpoint, :show, post_id)
        end

        pages = Silbernageldev.Blog.all_posts()
        {:ok, %{pages: pages, url_fn: url_fn, done: []}, {:continue, :send}}

      _ ->
        {:stop, :invalid_content_type}
    end
  end

  @impl true
  def handle_continue(:send, state) do
    Logger.info("#{@log_prefix} Sending")

    for page <- state.pages do
      source_url = state.url_fn.(page.id)
      Libmention.Supervisor.send(source_url, page.body)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:done, state) do
    state = %{state | done: [:done | state.done]}

    if Enum.count(state.done) == Enum.count(state.pages) do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:done, url}, state) do
    state = %{state | done: [{:done, url} | state.done]}

    if Enum.count(state.done) == Enum.count(state.pages) do
      {:stop, :normal, state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("#{@log_prefix} Shutting down")
    :ok
  end
end
