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
    {:ok, %{post: post, source_url: source_url, links: []}, {:continue, :search_post}}
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
    links =
      Enum.map(state.links, fn link ->
        %{link => discover(link, state.post)}
      end)

    {:noreply, %{state | links: links}, {:continue, :notify}}
  end

  def handle_continue(:notify, state) do
    for links <- state.links do
      for {link, targets} <- links do
        send_webmentions_for(state.post, link, targets, state.source_url)
      end
    end

    {:stop, :normal, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Logger.info("#{@log_prefix} Shutting down")
    :ok
  end

  trace(kind: :internal)

  defp send_webmentions_for(post, link, targets, source_url) do
    trace_attrs(link: link, targets: targets)

    for target <- targets do
      case Req.post(target, form: [source: source_url, target: link]) do
        {:ok, %Req.Response{status: status, headers: _headers, body: _body}}
        when status >= 200 and status <= 300 ->
          Logger.info("#{@log_prefix} SUCCESS")
          _ = WebMentions.capture_result(post, link, :sent)
          :ok

        {:ok, %Req.Response{status: status, body: body}} ->
          Logger.error("#{@log_prefix} Invalid request -- #{status}")
          Logger.error("#{@log_prefix} #{inspect(body)}")
          _ = WebMentions.capture_result(post, link, :failed)
          :error

        {:error, err} ->
          Logger.error("#{@log_prefix} #{inspect(err)}")
          _ = WebMentions.capture_result(post, link, :failed)
          :error
      end
    end
  end

  defp discover(link, post) do
    Logger.info("#{@log_prefix} discovering webmentions at #{link}")

    case WebMentions.check_webmention_result(post, link) do
      :empty ->
        Logger.info("#{@log_prefix} webmention for #{link} has not been attempted yet")
        do_discovery(post, link)

      :complete ->
        Logger.info("#{@log_prefix} webmention for #{link} does not need to be sent again")
        []

      :update ->
        Logger.warn(
          "#{@log_prefix} post has changed and we've sent a success before for #{link} - should send an update"
        )

        []
    end
  end

  defp do_discovery(post, link) do
    case Req.get(link, user_agent: "Webmention-Discovery") do
      {:ok, %Req.Response{status: 200, headers: _headers, body: body}} ->
        case find_webmention_links(body, link) do
          [] ->
            _ = WebMentions.capture_result(post, link, :not_found)
            []

          links ->
            links
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.error("#{@log_prefix} Invalid request -- #{status}")
        Logger.error("#{@log_prefix} #{inspect(body)}")
        _ = WebMentions.capture_result(post, link, :failed)
        []

      {:error, err} ->
        Logger.error("#{@log_prefix} #{inspect(err)}")
        _ = WebMentions.capture_result(post, link, :failed)
        []
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
        |> Enum.map(fn l ->
          if String.starts_with?(l, "/") do
            orig_link <> l
          else
            l
          end
        end)

      {:error, reason} ->
        Logger.warn("#{@log_prefix} Unable to parse html -- #{reason}")
        []
    end
  end

  defp find_hrefs({"href", link}), do: link
  defp find_hrefs(_), do: nil
end
