defmodule SilbernageldevWeb.Controllers.RssController do
  use SilbernageldevWeb, :controller

  alias Silbernageldev.Blog
  alias Atomex.{Feed, Entry}

  @author "Matt Silbernagel"
  @email "matt@silbernagel.dev"

  def index(conn, _params) do
    posts = Blog.all_posts()
    feed = build_feed(posts, conn)

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(200, feed)
  end

  def build_feed(posts, conn) do
    conn
    |> Routes.blog_url(:index)
    |> Feed.new(DateTime.utc_now(), "Silbernagel Dev RSS")
    |> Feed.author(@author, email: @email)
    |> Feed.link(Routes.rss_url(conn, :index), rel: "self")
    |> Feed.entries(Enum.map(posts, &get_entry(conn, &1)))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  defp get_entry(conn, post) do
    Entry.new(
      Routes.blog_url(conn, :show, post.id),
      DateTime.new!(post.date, Time.utc_now()),
      post.title
    )
    |> Entry.link(Routes.blog_url(conn, :show, post.id))
    |> Entry.author(post.author)
    |> Entry.content(post.body, type: "text")
    |> Entry.build()
  end
end
