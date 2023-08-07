import Config

config :silbernageldev,
  ecto_repos: [Silbernageldev.Repo],
  generators: [binary_id: true],
  rate_limits: %{
    general: 20,
    gpg_verification: 20
  },
  fail2ban_duration_hours: 24

config :silbernageldev,
  gemini_host: "localhost"

# Configures the endpoint
config :silbernageldev, SilbernageldevWeb.Endpoint,
  url: [host: "silbernagel.dev"],
  render_errors: [
    view: SilbernageldevWeb.ErrorHTML,
    accepts: ~w(html json),
    layout: {SilbernageldevWeb.Layouts, :root}
  ],
  pubsub_server: Silbernageldev.PubSub,
  live_view: [signing_salt: "yeNIpo46"]

# configures libmention
config :silbernageldev, :libmention,
  outgoing: [
    storage: Silbernageldev.WebMentions.WebMentionStorage
  ]

config :tailwind,
  version: "3.1.6",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :mime, :types, %{
  "application/jrd+json" => ["jrd"]
}

config :logger_json, :backend,
  metadata: :all,
  json_encoder: Jason,
  formatter: LoggerJSON.Formatters.BasicLogger

config :silbernageldev, :orbit, {
  Orbit.Capsule,
  endpoint: SilbernageldevGem.Router,
  certfile: Path.join(["priv", "tls", "localhost.pem"]),
  keyfile: Path.join(["priv", "tls", "localhost-key.pem"])
}

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :silbernageldev, Silbernageldev.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :path, :otel_span_id, :otel_trace_flags, :otel_trace_id, :post_id]

config :silbernageldev, Silbernageldev.PromEx,
  metrics_server: [
    port: System.get_env("PROM_PORT") || 9091,
    path: "/metrics",
    protocol: :http,
    pool_size: 5
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
