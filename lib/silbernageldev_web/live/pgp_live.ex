defmodule SilbernageldevWeb.Live.PGPLive do
  use Phoenix.LiveView

  @impl true
  def mount(_, _, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>My PGP public key</h1>
    """
  end
end
