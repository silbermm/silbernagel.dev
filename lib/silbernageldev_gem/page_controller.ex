defmodule SilbernageldevGem.PageController do
  use SilbernageldevGem, :controller

  view SilbernageldevGem.PageView

  def home(req, _params) do
    name = if req.client_cert, do: req.client_cert.common_name, else: "world"

    req
    |> assign(name: name)
    |> render()
  end
end
