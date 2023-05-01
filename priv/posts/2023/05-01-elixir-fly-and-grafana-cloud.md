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
  mkdir logshipper`
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
Traces are fairly easy to send to Grafana Cloud Tempo as well.



## Metrics
