defmodule SilbernageldevWeb.Controllers.GPGController do
  use SilbernageldevWeb, :controller

  def download(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-disposition", "attachment; filename=\"silbernagel.asc\"")
    |> send_resp(200, Silbernageldev.GPG.get_gpg_key())
  end
end
