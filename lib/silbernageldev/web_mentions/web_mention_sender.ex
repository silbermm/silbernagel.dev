defmodule Silbernageldev.WebMentions.WebMentionSender do
  @moduledoc """
  A process that searches through a blog post for
  links and attempts to send a webmention
  end
  """
  alias Silbernageldev.WebMentions

  use GenServer, restart: :temporary
  use Silbernageldev.OpenTelemetry

  require Logger

  trace_all(kind: :internal)

  @log_prefix "[WebMentionSender] |"

  def start_link(post), do: GenServer.start_link(__MODULE__, post)

  trace(kind: :internal)

  @impl true
  def init(post) do
    Logger.metadata(post_id: post.id)

    source_url =
      SilbernageldevWeb.Router.Helpers.blog_url(
        SilbernageldevWeb.Endpoint,
        :show,
        post.id
      )

    trace_attrs(source_url: source_url)

    {:ok, %{post: post, source_url: source_url, links: [], web_mentions: []},
     {:continue, :search_post}}
  end

  @impl true
  def handle_continue(:search_post, state) do
    Logger.info("#{@log_prefix} Searching for links in #{state.post.title}")
    {:ok, document} = Floki.parse_document(state.post.body)

    links =
      document
      |> Floki.find(~S{a[href^="https"]})
      |> Enum.flat_map(fn {_, links, _} -> Enum.map(links, &find_hrefs/1) end)
      |> Enum.reject(&is_nil(&1))
      |> Enum.uniq()

    Logger.info("#{@log_prefix} Links found: #{inspect(links)}")
    trace_attrs(links: links)

    {:noreply, %{state | links: links}, {:continue, :discovery}}
  end

  def handle_continue(:discovery, state) do
    web_mentions =
      for link <- state.links, reduce: [] do
        acc ->
          case WebMentions.check_webmention_result(state.post, link) do
            nil ->
              acc

            mention ->
              mention =
                case discover(link) do
                  :not_found ->
                    WebMentions.change(mention, %{status: :not_found})

                  :failed ->
                    WebMentions.change(mention, %{status: :failed})

                  endpoint ->
                    WebMentions.change(mention, %{
                      status: :pending,
                      webmention_endpoint: endpoint
                    })
                end

              [mention | acc]
          end
      end

    {:noreply, %{state | web_mentions: web_mentions}, {:continue, :notify}}
  end

  def handle_continue(:notify, state) do
    changes =
      for mention_changeset <- state.web_mentions do
        if WebMentions.is_pending?(mention_changeset) do
          WebMentions.send_webmention_for(mention_changeset, state.source_url)
        else
          mention_changeset
        end
      end

    {:noreply, %{state | web_mentions: changes}, {:continue, :persist}}
  end

  def handle_continue(:persist, state) do
    for mention <- state.web_mentions do
      WebMentions.capture_result(mention)
    end

    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("#{@log_prefix} Shutting down")
    :ok
  end

  defp discover(link) do
    Logger.info("#{@log_prefix} discovering webmentions at #{link}")

    case Req.get(link, user_agent: "Webmention-Discovery") do
      {:ok, %Req.Response{status: 200, headers: _headers, body: body}} ->
        case find_webmention_links(body, link) do
          [] ->
            :not_found

          [link | _] ->
            link
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("#{@log_prefix} Invalid request -- #{status}")
        Logger.error("#{@log_prefix} #{inspect(body)}")
        :failed

      {:error, err} ->
        Logger.error("#{@log_prefix} #{inspect(err)}")
        :failed
    end
  end

  defp find_webmention_links(body, orig_link) do
    case Floki.parse_document(body) do
      {:ok, document} ->
        links_with_webmention = Floki.find(document, ~S{link[rel="webmention"]})
        a_with_webmention = Floki.find(document, ~S{a[rel="webmention"]})

        links_with_webmention
        |> Enum.concat(a_with_webmention)
        |> Floki.attribute("href")
        |> Enum.map(fn
          "/" <> rest -> orig_link <> "/" <> rest
          link -> link
        end)

      {:error, reason} ->
        Logger.warn("#{@log_prefix} Unable to parse html -- #{reason}")
        []
    end
  end

  defp find_hrefs({"href", link}), do: link
  defp find_hrefs(_), do: nil
end
