defmodule SilbernageldevWeb.Controllers.FediController do
  use SilbernageldevWeb, :controller

  def follow(conn, params) do
    [from] = Plug.Conn.get_req_header(conn, "referer")
    IO.inspect from
    IO.inspect params
    #send_resp(conn, 200, "")
    conn
    |> put_flash(:info, "Good job")
    |> redirect(external: from)
  end
end
