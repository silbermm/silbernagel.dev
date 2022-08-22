defmodule SilbernageldevWeb.LayoutView do
  use SilbernageldevWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def nav_link_classes(conn, active_path) do
    if Phoenix.Controller.current_path(conn) == active_path do
      "inline-block py-2 px-4 text-gray-900 font-bold no-underline"
    else
      "inline-block text-gray-600 no-underline hover:text-gray-900 hover:text-underline py-2 px-4"
    end
  end
end
