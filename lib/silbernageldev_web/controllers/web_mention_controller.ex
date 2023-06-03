defmodule SilbernageldevWeb.Controllers.WebMentionController do
  use SilbernageldevWeb, :controller

  alias Silbernageldev.WebMentions
  alias Silbernageldev.Blog

  def receive(conn, %{"source" => source, "target" => target}) when source == target do
    # validtate that source and target are not the same
    send_resp(conn, 400, "Invalid Parameters")
  end

  def receive(conn, %{"source" => source, "target" => target}) do
    # validate source and target are valid urls
    # validate that target is a valid resource that accepts webmentions
    with true <- valid_url?(source),
         entity when not is_nil(entity) <- valid_target_entity(target),
         {:ok, data} <- WebMentions.queue_webmention_request(source, target) do
      conn
      |> put_status(201)
      |> json(%{id: data.id})
    else
      {:error, :already_queued} -> send_resp(conn, 429, "Already queued")
      _e -> send_resp(conn, 400, "Invalid source or target url(s)")
    end

    # WEBMENTION VERIFICATION
    # handle everything else async

    # MUST perform an HTTP GET request on source, following any HTTP redirects (and SHOULD limit the number of redirects it follows) to confirm that it actually mentions the target. The receiver SHOULD include an HTTP Accept header indicating its preference of content types that are acceptable. 

    # The source document MUST have an exact match of the target URL provided in order for it to be considered a valid Webmention.
    # return a 201 created with an optional Location header for the sender to see the progress of the webmention
  end

  defp valid_url?(url) do
    uri = URI.parse(url)
    String.starts_with?(uri.scheme, "http")
  end

  defp valid_target_entity(url) do
    configured_url = Application.get_env(:silbernageldev, SilbernageldevWeb.Endpoint)[:url][:host]

    configured_scheme =
      Application.get_env(:silbernageldev, SilbernageldevWeb.Endpoint)[:url][:scheme] || "http"

    configured_uri = configured_scheme <> "://" <> configured_url

    parsed_url = URI.parse(url)

    path = parsed_url.path

    if String.starts_with?(path, "/posts/") && String.starts_with?(url, configured_uri) do
      Blog.get_post_by_id(String.trim_leading(path, "/posts/"))
    end
  end
end
