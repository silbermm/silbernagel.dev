defmodule SilbernageldevWeb.Controllers.WebMentionController do
  use SilbernageldevWeb, :controller

  def receive(conn, %{"source" => source, "target" => target}) when source == target do
    # validtate that source and target are not the same
    send_resp(conn, 400, "Invalid Parameters")
  end

  def receive(conn, %{"source" => source, "target" => target}) do
    # validate source and target are valid urls
    # validate that target is a valid resource that accepts webmentions
    with true <- valid_url?(source),
         true <- valid_url?(target),
         true <- target_accepts_webmentions(target) do
      send_resp(conn, :ok, "")
    else
      _e -> send_resp(conn, 400, "Invalid source or target url(s)")
    end

    # WEBMENTION VERIFICATION
    # handle everything else async

    # MUST perform an HTTP GET request on source, following any HTTP redirects (and SHOULD limit the number of redirects it follows) to confirm that it actually mentions the target. The receiver SHOULD include an HTTP Accept header indicating its preference of content types that are acceptable. 

    # The source document MUST have an exact match of the target URL provided in order for it to be considered a valid Webmention.

    # return a 201 created with an optional Location header for the sender to see the progress o the webmention
  end

  defp valid_url?(url) do
    uri = URI.parse(url)
    String.starts_with?(uri.scheme, "http") && uri.host =~ "."
  end

  defp target_accepts_webmentions(target) do
    # currently only posts support webmentions
    # check if target is a valid post
    true
  end
end
