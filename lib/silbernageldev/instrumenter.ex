defmodule Silbernageldev.Instrumenter do
  @moduledoc """
  Handle the telemetry events from the system
  """
  require Logger

  def setup do
    events = [
      [:phoenix, :router_dispatch, :exception],
      [:phoenix, :router_dispatch, :stop]
    ]

    :telemetry.attach_many(
      "telemetry-instrumenter",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(
        [:phoenix, :router_dispatch, :stop],
        _measurment,
        metadata,
        _config
      ) do
    Logger.info("route processed", path: metadata.route)
  end

  def handle_event(
        [:phoenix, :router_dispatch, :exception],
        _measurment,
        metadata,
        _config
      ) do
    Logger.info("route not processed", path: metadata.route)
  end
end
