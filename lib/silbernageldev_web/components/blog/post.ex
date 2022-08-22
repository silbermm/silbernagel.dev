defmodule SilbernageldevWeb.Components.Blog.Post do
  use Phoenix.Component

  import Phoenix.HTML, only: [raw: 1]

  def default(assigns) do
    ~H"""
    <div class="container max-w-3xl mx-auto overflow-hidden prose-pre:rounded-md prose-pre:p-4">
      <div class="w-full prose prose:slate dark:prose-invert hover:prose-a:text-orange-400">
        <!--Title-->
        <header>
          <h2> <%= @post.title %> </h2>
          <span>Published <time><%= @post.date %></time></span>
          <.taglist tags={@post.tags} /> 
        </header>

        <article>
        <%= raw @post.body %>
        </article>
      </div>

    </div>
    """
  end

  defp taglist(assigns) do
    ~H"""
    <div class="text-gray-500">
      <%= for tag <- @tags do %>
        <a href="#" class="text-base md:text-sm text-green-500 no-underline hover:underline"> <%= tag %> </a>  
      <% end %>
    </div>
    """
  end
end
