defmodule SilbernageldevWeb.Live.AboutLive do
  use SilbernageldevWeb, :blog_live_view

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "About")
      |> assign_new(:description, fn -> "Who am I and what is this site about" end)
      |> assign_new(:url, fn -> ~p"/about" end)
      |> assign_new(:content, fn -> Silbernageldev.About.content() end)

    {:ok, socket}
  end

  @impl true
  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container max-w-3xl mx-auto overflow-hidden prose-pre:rounded-md prose-pre:p-4">
      <div class="h-entry max-w-3xl prose prose:slate dark:prose-invert hover:prose-a:text-orange-400">
        <!--Title-->
        <header>
          <h2 class="p-name">
            <.link navigate={~p"/about"} class="u-url">
              <%= @content.title %>
            </.link>
          </h2>
          <div class="u-author h-card hidden">
            <img src={~p"/images/avatar.jpg"} class="u-photo" width="40" />
            <a href={~p"/"} class="u-url p-name">
              Matt Silbernagel
            </a>
          </div>
        </header>

        <article class="e-content">
          <%= raw(@content.body) %>
        </article>
      </div>
    </div>
    """
  end
end
