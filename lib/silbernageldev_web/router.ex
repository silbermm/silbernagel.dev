defmodule SilbernageldevWeb.Router do
  use SilbernageldevWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {SilbernageldevWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :webfinger do
    plug(:accepts, ["jrd", "json"])
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", SilbernageldevWeb.Live do
    pipe_through(:browser)

    live("/posts", BlogLive, :index)
    live("/posts/:id", BlogLive, :show)

    live("/tags", Blog.TagsLive, :index)
    live("/tags/:tag_name", Blog.TagsLive, :show)

    live("/gpg", GPGLive, :index)

    live("/", HomeLive, :index)
  end

  scope "/.well-known/webfinger", SilbernageldevWeb.Controllers do
    pipe_through(:webfinger)
    get("/", WebFingerController, :finger)
  end

  scope "/.well-known/openpgpkey", SilbernageldevWeb.Controllers do
    pipe_through(:browser)
    get("/policy", GPGController, :policy)
    get("/hu/:localpart", GPGController, :binary_key)
  end

  scope "/", SilbernageldevWeb.Controllers do
    pipe_through(:browser)

    get("/gpg/download", GPGController, :download)
  end

  # Other scopes may use custom stacks.
  # scope "/api", SilbernageldevWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: SilbernageldevWeb.Telemetry)
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
