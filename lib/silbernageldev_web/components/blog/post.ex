defmodule SilbernageldevWeb.Components.Blog.Post do
  use Phoenix.Component
  alias SilbernageldevWeb.Router.Helpers, as: Routes
  import Phoenix.HTML, only: [raw: 1]
  import Phoenix.HTML.Link

  def show(assigns) do
    ~H"""
    <div class="container max-w-3xl mx-auto overflow-hidden prose-pre:rounded-md prose-pre:p-4">
      <div class="h-entry max-w-3xl prose prose:slate dark:prose-invert hover:prose-a:text-orange-400">
        <!--Title-->
        <header>
          <h2 class="p-name">
            <%= link(@post.title,
              to: Routes.blog_path(SilbernageldevWeb.Endpoint, :show, @post.id),
              class: "u-url"
            ) %>
          </h2>
          <span class="dt-published">Published <time><%= @post.date %></time></span>
          <.taglist tags={@post.tags} />
        </header>

        <%= if @post.reply_to do %>
          In reply to: <a href={elem(@post.reply_to, 0)} class="u-in-reply-to"><%= elem(@post.reply_to, 1) %></a>
        <% end %>

        <article class="e-content">
          <%= raw(@post.body) %>
        </article>
      </div>
    </div>
    """
  end

  def list(assigns) do
    ~H"""
    <div class="h-feed max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flow-root">
        <ul role="list" class="-my-5 divide-y divide-gray-200">
          <%= for post <- @posts do %>
            <li class="py-5">
              <div class="relative focus-within:ring-2">
                <h3 class="text-lg font-semibold text-gray-800 dark:text-gray-200">
                  <%= live_patch(post.title,
                    to: Routes.blog_path(SilbernageldevWeb.Endpoint, :show, post),
                    class: "hover:underline focus:outline-none"
                  ) %>
                </h3>

                <p class="text-sm dark:text-slate-400">
                  Posted <time><%= post.date %></time>
                </p>

                <p class="mt-2 text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                  <%= raw(post.description) %>
                </p>
              </div>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def taglist(assigns) do
    ~H"""
    <div class="p-category text-gray-500">
      <%= for tag <- @tags do %>
        <%= live_redirect(tag,
          to: Routes.blog_tags_path(SilbernageldevWeb.Endpoint, :show, tag),
          class: "text-base md:text-sm text-green-500 no-underline hover:underline"
        ) %>
      <% end %>
    </div>
    """
  end
end
