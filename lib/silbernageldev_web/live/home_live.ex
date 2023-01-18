defmodule SilbernageldevWeb.Live.HomeLive do
  use SilbernageldevWeb, :blog_live_view

  @impl true
  def mount(_, _, socket) do
    {:ok,
     socket
     |> assign_new(:page_title, fn -> "Home" end)
     |> assign_new(:description, fn ->
       "Software engineer with a passion for open source software built on open standards and protocols"
     end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div></div>
    """
  end
end
