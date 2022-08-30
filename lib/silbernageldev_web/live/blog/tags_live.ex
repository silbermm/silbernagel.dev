defmodule SilbernageldevWeb.Live.Blog.TagsLive do
  use SilbernageldevWeb, :blog_live_view

  alias Silbernageldev.Blog
  alias SilbernageldevWeb.Components.Blog.Post

  require Logger

  @impl true
  def mount(%{"tag_name" => tag_name}, _session, socket) do
    Logger.debug("searching for posts with #{tag_name}")
    socket = assign_new(socket, :posts, fn -> Blog.get_posts_by_tag!(tag_name) end)
    {:ok, assign(socket, tag_name: tag_name, tags: [])}
  end

  def mount(_, _session, socket) do
    socket = assign_new(socket, :tags, fn -> Blog.all_tags() end)
    {:ok, assign(socket, tag_name: nil, posts: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @posts !== nil do %>
      <div class="max-w-3xl mx-auto px-4 pb-6 sm:px-6 lg:px-8">
        <div class="flow-root">
          <h3 class="text-xl font-semibold text-gray-800 dark:text-gray-200">
            Posts tagged with <span class="text-green-500 italic"><%= @tag_name %></span>
          </h3>
        </div>
      </div>
      <Post.list posts={@posts} />
    <% else %>
      <div class="max-w-3xl mx-auto px-4 pb-6 sm:px-6 lg:px-8">
        <div class="flow-root">
          <h3 class="text-xl font-semibold pb-6 text-gray-800 dark:text-gray-200">
            All Tags
          </h3>
          <Post.taglist tags={@tags} />
        </div>
      </div>
    <% end %>
    """
  end
end
