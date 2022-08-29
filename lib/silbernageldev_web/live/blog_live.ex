defmodule SilbernageldevWeb.Live.BlogLive do
  use SilbernageldevWeb, :blog_live_view

  alias Silbernageldev.Blog
  alias SilbernageldevWeb.Components.Blog.Post

  @impl true
  def mount(%{"id" => blog_post_id}, _session, socket) do
    socket =
      socket
      |> assign(:post, Blog.get_post_by_id!(blog_post_id))
      |> assign_new(:posts, fn -> Blog.all_posts() end)

    {:ok, socket}
  end

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign(:post, nil)
      |> assign_new(:posts, fn -> Blog.all_posts() end)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => blog_post_id}, _url, socket) do
    {:noreply, assign(socket, :post, Blog.get_post_by_id!(blog_post_id))}
  end

  def handle_params(%{}, _url, socket) do
    {:noreply, assign(socket, :post, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= unless @post == nil do %>
        <Post.default post={@post} />
      <% else %>
        <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flow-root">
            <ul role="list" class="-my-5 divide-y divide-gray-200">
              <%= for post <- @posts do %>
                <li class="py-5">
                  <div class="relative focus-within:ring-2">
                    <h3 class="text-lg font-semibold text-gray-800 dark:text-gray-200">
                      <%= live_patch(post.title,
                        to: Routes.blog_path(@socket, :show, post),
                        class: "hover:underline focus:outline-none"
                      ) %>
                    </h3>

                    <p class="text-sm dark:text-slate-400">
                      Posted <time><%= post.date %></time>
                    </p>

                    <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                      <%= Phoenix.HTML.raw(post.description) %>
                    </p>
                  </div>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # def index(conn, _params) do
  #  render(conn, "index.html", posts: Blog.all_posts())
  # end

  # def show(conn, %{"id" => id}) do
  #  post = Blog.get_post_by_id!(id)
  #  render(conn, "show.html", post: Blog.get_post_by_id!(id), description: post.description)
  # end
end
