%{
  title: "Elixir, Fly, and Grafana Cloud",
  author: "Matt Silbernagel",
  tags: ~w(Elixir Telemetry Observability),
  description: "Learn how to send your Metrics, Logs and Traces to Grafana Cloud from your Elixir app hosted on Fly.io",
  draft: false
}
---

If you have an elixir app running on [Fly.io](https://fly.io/docs/elixir/getting-started/), sending your telemetry data to Grafana cloud is easy.

Lets start with Logs.

## Logs
In order to ship logs to Grafana Cloud Loki, another application, called logshipper, is required. It is all detailed [in the documentation](https://fly.io/docs/going-to-production/monitoring/exporting-logs/), but the TLDR; is:
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

Start by pulling in the open_telemetry libraries.
```elixir
# ./mix.exs
defp deps do
  [
    ...
    {:opentelemetry_exporter, "~> 1.0"},
    {:opentelemetry, "~> 1.0"},
    {:opentelemetry_api, "~> 1.0"},
    {:opentelemetry_ecto, "~> 1.0"},
    {:opentelemetry_liveview, "~> 1.0.0-rc.4"},
    {:opentelemetry_phoenix, "~> 1.0"},
    {:opentelemetry_cowboy, "~> 0.2"}
  ]
end
```

Add some configuration to `runtime.exs`
```elixir
# ./config/runtime.exs
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

Next, setup the environment variables.

* The value required for `OTLP_ENDPOINT` can be found on the Grafana Cloud Portal Tempo section, and will look something like: `https://tempo-us-central1.grafana.net/tempo` (your url may be different)
* The value for `OTEL_AUTH` is a base64 encoded value of `{username}:{api token}` which can be easily obtained using:
  ```
  echo -n 'username:password' | base64`
  ```
 (replace username and password with the actual vaules)
* And you'll need the data source name (found on the same Grafana Cloud Portal page) which will be used to set the value of `OTEL_RESOURCE_ATTRIBUTES`

All of these values can be set with one command:
```
flyctl secrets set OTLP_ENDPOINT=https://your_endpoint OTEL_RESOURCE_ATTRIBUTES=your_datasource_name OTEL_AUTH=your_base64_encoded_string
```

After setting these values and deploying the application, traces should start showing in Grafana!

## Metrics

For Metrics, I really like to use [Prometheus](https://prometheus.io/docs/introduction/overview/) and I find the easiest way to get started with Prometheus is using [prom_ex](https://hexdocs.pm/prom_ex/readme.html). PromEx provides excellent documentation and is worth reading, but a quick guide to get it working:

* Adding `:prom_ex, "~> 1.8"` to your dependencies in `mix.exs` and run `mix deps.get`
* Run the generator `mix prom_ex.gen.config --datasource curl`
* Add config in `config.exs` for the metrics server
  ```elixir
  config :your_app, YourApp.PromEx,
  metrics_server: [
    port: System.get_env("PROM_PORT") || 9091,
    path: "/metrics",
    protocol: :http,
    pool_size: 5
  ]
  ```
* Add `YourApp.PromEx` to your supervision tree in `application.ex`
  ```elixir
  def start(_type, _args) do
    children = [
      YourAppWeb.Endpoint,
      # PromEx should be started after the Endpoint, to avoid unnecessary error messages
      YourApp.PromEx,
      ...
    ]
  ```
* Lastly, uncomment any desired plugins in the generated `YourApp.PromEx` file.

With all of that, `localhost:9091/metrics` should be available when the app is running

Next, the metrics just need to be exposed so that Fly can scrape them. As [documented by Fly](https://fly.io/docs/reference/metrics/#configuration), just add the following to your fly.toml file:

```toml
[metrics]
port = 9091
path = "/metrics"
```

Finally, setup the Prometheus data source in Grafana Cloud with the following properties:
* HTTP -> URL "https://api.fly.io/prometheus/<org-slug>/" where `org_slug` is your org
* Custom HTTP Headers -> + Add Header:
  * Header: Authorization, Value: Bearer <token> where token is the result of `flyctl auth token`

You should now see all of the fly metrics and prom_ex defined metrics in Grafana!

## Wrap Up
I wrote this because I wanted to add observability to my Elixir/Phoenix apps that run on Fly and finding the information I needed was scattered throughout the docs. Hopefully others find this useful.

Happy Observing!

[](https://fed.brid.gy/)
