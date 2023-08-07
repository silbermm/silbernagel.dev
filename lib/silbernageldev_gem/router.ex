defmodule SilbernageldevGem.Router do
  use Orbit.Router

  alias SilbernageldevGem.LayoutView
  alias SilbernageldevGem.PageController

  pipe {Orbit.Controller, :push_layout}, {LayoutView, :main}

  route "/", PageController, :home
  route "/public_key", PageController, :public_key
  route "/gemlog", PageController, :gemlog
  route "/gemlog/:post_id", PageController, :gemlog_post

  route "/*path", Orbit.Static, from: "priv/static"
end
