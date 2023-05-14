defmodule SilbernageldevWeb.Plugs.PlugAttack do
  @moduledoc """
  Protects us from various abusive requests, including credential stuffing
  """

  use PlugAttack
  use Silbernageldev.OpenTelemetry

  trace_all(kind: :internal)

  @storage_name SilbernageldevWeb.PlugAttack.Storage
  def storage_name, do: @storage_name

  # We do _not_ create an allowlist rule for localhost in dev.
  # If our rate limiting rules are restrictive, we want our internal devs
  # to feel the pain so we can fix it.
  if Mix.env() == :test do
    rule "allow local", conn do
      allow(conn.remote_ip == {127, 0, 0, 1})
    end
  end

  rule "throttle gpg verifications", conn do
    if verification_request?(conn) do
      fail2ban({:login, conn.remote_ip}, fail2ban_limit_per_minute(:gpg_verification))
    end
  end

  rule "throttle webmentions", conn do
    if conn.request_path == "/webmention" do
      fail2ban({:login, conn.remote_ip}, fail2ban_limit_per_minute(:webmentions))
    end
  end

  # The most general rule must come last, otherwise it will prevent matching other rules
  rule "throttle generic requests by ip", conn do
    throttle({:ip, conn.remote_ip}, limit_per_minute(:general))
  end

  defp verification_request?(conn) do
    conn.request_path == "/verify"
  end

  defp fail2ban_limit_per_minute(rate_limit_type) do
    [{:ban_for, ban_duration_timeout()} | limit_per_minute(rate_limit_type)]
  end

  defp limit_per_minute(rate_limit_type) do
    rate_limits = Application.fetch_env!(:silbernageldev, :rate_limits)

    [
      period: :timer.seconds(60),
      limit: Access.fetch!(rate_limits, rate_limit_type),
      storage: {PlugAttack.Storage.Ets, @storage_name}
    ]
  end

  defp ban_duration_timeout do
    Application.fetch_env!(:silbernageldev, :fail2ban_duration_hours)
    |> :timer.hours()
  end
end
