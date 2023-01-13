defmodule SilbernageldevWeb.Live.BlogLive do
  use SilbernageldevWeb, :blog_live_view

  alias Silbernageldev.Blog
  alias SilbernageldevWeb.Components.Blog.Post

  @impl true
  def mount(%{"id" => blog_post_id}, _session, socket) do
    socket =
      socket
      |> assign(:post, Blog.get_post_by_id!(blog_post_id))
      |> assign(:page_title, fn %{post: post} -> post.title end)
      |> assign(:description, fn %{post: post} -> post.description end)
      |> assign_new(:posts, fn -> Blog.all_posts() end)

    {:ok, socket}
  end

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign(:post, nil)
      |> assign(:page_title, fn -> "Blog Posts" end)
      |> assign_new(:posts, fn -> Blog.all_posts() end)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => blog_post_id}, _url, socket) do
    {:noreply,
     socket
     |> assign(:post, Blog.get_post_by_id!(blog_post_id))
     |> assign(:page_title, fn %{post: post} -> post.title end)
     |> assign(:description, fn %{post: post} -> post.description end)}
  end

  def handle_params(%{}, _url, socket) do
    {:noreply,
     socket
     |> assign(:post, nil)
     |> assign(:page_title, fn -> "Blog Posts" end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= unless @post == nil do %>
        <Post.show post={@post} />
      <% else %>
        <Post.list posts={@posts} />
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
