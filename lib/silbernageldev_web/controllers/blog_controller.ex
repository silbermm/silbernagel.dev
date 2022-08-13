defmodule SilbernageldevWeb.BlogController do
  use SilbernageldevWeb, :controller

  alias Silbernageldev.Blog

  plug :put_layout, {SilbernageldevWeb.LayoutView, "blog.html"}

  def index(conn, _params) do
    render(conn, "index.html", posts: Blog.all_posts())
  end

  def show(conn, %{"id" => id}) do
    post = Blog.get_post_by_id!(id)
    render(conn, "show.html", post: Blog.get_post_by_id!(id), description: post.description)
  end
end
