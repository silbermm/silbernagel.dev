defmodule SilbernageldevGem.Router do
  use Orbit.Router

  alias SilbernageldevGem.LayoutView
  alias SilbernageldevGem.PageController

  pipe {Orbit.Controller, :push_layout}, {LayoutView, :main}

  route "/static/*path", Orbit.Static, from: "priv/static"

  route "/", PageController, :home
end
