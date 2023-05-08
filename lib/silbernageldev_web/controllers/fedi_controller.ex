defmodule SilbernageldevWeb.Controllers.FediController do
  use SilbernageldevWeb, :controller

  def follow(conn, params) do
    IO.inspect params
    send_resp(conn, 200, "")
  end
end
