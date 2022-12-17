defmodule SilbernageldevWeb.Controllers.GPGController do
  use SilbernageldevWeb, :controller

  def download(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("content-disposition", "attachment; filename=\"silbernagel.asc\"")
    |> send_resp(200, Silbernageldev.GPG.get_gpg_key())
  end

  def policy(conn, _params) do
    send_resp(conn, 200, "")
  end

  def binary_key(conn, %{"localpart" => "d6tq6t4iirtg3qpyw1nyzsr5nsfcqrht"}) do
    file = Application.app_dir(:silbernageldev, "/priv/static/silbernagel.pub")

    conn
    |> put_resp_content_type("application/octet-stream")
    |> send_resp(200, File.read!(file))
  end

  def binary_key(conn, _) do
    send_resp(conn, 404, "not found")
  end
end
