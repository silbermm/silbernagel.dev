defmodule SilbernageldevWeb.HomepageController do
  use SilbernageldevWeb, :controller

  plug :put_layout, {SilbernageldevWeb.LayoutView, "blog.html"}

  def index(conn, _params) do
    render(conn, "index.html")
  end
end