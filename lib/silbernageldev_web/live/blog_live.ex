defmodule SilbernageldevWeb.Live.BlogLive do
  use SilbernageldevWeb, :blog_live_view

  alias SilbernageldevWeb.Components.Comments
  alias Silbernageldev.Blog
  alias SilbernageldevWeb.Components.Blog.Post

  @impl true
  def mount(%{"id" => blog_post_id}, _session, socket) do
    socket =
      socket
      |> assign_new(:post, fn -> Blog.get_post_by_id!(blog_post_id) end)
      |> assign_new(:page_title, fn %{post: post} -> post.title end)
      |> assign_new(:description, fn %{post: post} -> post.description end)
      |> assign_new(:url, fn %{post: post} -> ~p"/posts/#{post.id}" end)
      |> assign_new(:posts, fn -> Blog.all_posts() end)

    {:ok, socket}
  end

  @impl true
  def mount(_, _session, socket) do
    socket =
      socket
      |> assign(:post, nil)
      |> assign(:page_title, "Blog Posts")
      |> assign_new(:posts, fn -> Blog.all_posts() end)
      |> assign_new(:description, fn -> "Blog Posts" end)
      |> assign_new(:url, fn -> ~p"/posts" end)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => blog_post_id}, _url, socket) do
    post = Blog.get_post_by_id!(blog_post_id)

    {:noreply,
     socket
     |> assign(:post, post)
     |> assign(:page_title, post.title)
     |> assign(:description, post.description)}
  end

  def handle_params(%{}, _url, socket) do
    {:noreply,
     socket
     |> assign(:post, nil)
     |> assign(:page_title, "Blog Posts")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= unless @post == nil do %>
        <Post.show post={@post} />
        <Comments.info />
      <% else %>
        <Post.list posts={@posts} />
      <% end %>
    </div>
    """
  end
end
