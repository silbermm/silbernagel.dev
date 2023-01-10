defmodule SilbernageldevWeb.Live.HomeLive do
  use SilbernageldevWeb, :blog_live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen"></div>
    """
  end
end
