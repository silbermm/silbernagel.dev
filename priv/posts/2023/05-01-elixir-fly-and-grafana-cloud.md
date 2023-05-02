%{
  title: "Elixir, Fly, and Grafana Cloud",
  author: "Matt Silbernagel",
  tags: ~w(Elixir Telemetry),
  description: "",
  draft: true
}
---

If you have an elixir app running on [Fly.io](https://fly.io/docs/elixir/getting-started/), sending your telemetry data to Grafana cloud is easy.

Lets start with Logs.

## Logs
In order to ship logs to Grafana Cloud Loki, we need to deploy another application to your Fly account. It is all detailed [in the documentation](https://fly.io/docs/going-to-production/monitoring/exporting-logs/), but the TLDR; is:
* Create a new directory 
  ```
  mkdir logshipper
  ```
* Create a new app, but don't launch yet
  ```
  fly launch --no-deploy --image ghcr.io/superfly/fly-log-shipper:latest`
  ```
* Configure your org and access token
  ```
  fly secrets set ORG=personal
  fly secrets set ACCESS_TOKEN=$(fly auth token)
  ```
* Configure your Loki credentials. These can be found in the Grafana Cloud Portal, Loki section. You may have to generate an API key, but all the data should be there for you to use here.
  ```
  fly secrets set LOKI_URL=
  fly secrets set LOKI_USERNAME=
  fly secrets set LOKI_PASSWORD=
  ```
* Add this to the newly generated fly.toml file:
```
[[services]]
  http_checks = []
  internal_port = 8686
```
* Deploy `flyctl deploy`

Once deployed, this should start sending all the logs from all your fly apps in the configured organization to Grafana Cloud.

More configuration options for the logshipper app can be found in the [github repo](https://github.com/superfly/fly-log-shipper#provider-configuration)

Lastly, I'd recommend shipping your logs in JSON format using something similar to [logger_json](https://hex.pm/packages/logger_json). 

## Traces
Traces are fairly easy to send to Grafana Cloud Tempo.

Start by installing the open_telemetry libraries in mix.exs
```elixir
{:opentelemetry_exporter, "~> 1.0"},
{:opentelemetry, "~> 1.0"},
{:opentelemetry_api, "~> 1.0"},
{:opentelemetry_ecto, "~> 1.0"},
{:opentelemetry_liveview, "~> 1.0.0-rc.4"},
{:opentelemetry_phoenix, "~> 1.0"},
{:opentelemetry_cowboy, "~> 0.2"}
```

Add some configuration to `runtime.exs`
```elixir
if config_env() == :prod do
  otel_auth = System.get_env("OTEL_AUTH") ||
    raise """
    OTEL_AUTH is a required variable
    """

  config :opentelemetry_exporter,
    otlp_protocol: :grpc,
    otlp_traces_endpoint: System.fetch_env!("OTLP_ENDPOINT"),
    otlp_headers: [{"Authorization", "Basic #{otel_auth}"}]
end
```

Next, we need to get some secrets setup

* The `OTLP_ENDPOINT` can be found on the Grafana Cloud Portal Tempo section, and will look something like: `https://tempo-us-central1.grafana.net/tempo` (your url may be different)
* The `OTEL_AUTH` is a base64 encoded value of your username and api token. You can run 
  ```
  echo -n 'username password' | base64`
  ```
 (replacing username and password with the actual vaules) to get the value you need.
* And you'll need the data source name (found on the same page) which we'll use to set `OTEL_RESOURCE_ATTRIBUTES`

You can set these values all at once with:
```
flyctl secrets set OTLP_ENDPOINT=https://your_endpoint OTEL_RESOURCE_ATTRIBUTES=your_datasource_name OTEL_AUTH=your_base64_encoded_string
```

After those are set, deploy your app and you start seeing traces appear in Tempo!

## Metrics

For Metrics, I really like to use [Prometheus](https://prometheus.io/docs/introduction/overview/)

