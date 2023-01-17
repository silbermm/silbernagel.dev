defmodule SilbernageldevWeb.Controllers.WebMentionController do
  use SilbernageldevWeb, :controller

  def receive(_params, conn) do
    send_resp(conn, :ok, "")
  end
end
