defmodule Silbernageldev.Blog do
  @moduledoc false

  alias Silbernageldev.Blog.Peek
  alias Silbernageldev.Blog.Post
  alias Silbernageldev.Repo

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:silbernageldev, "priv/content/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang, :makeup_html5, :makeup_eex]

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})
         |> then(fn posts ->
           if Mix.env() == :dev do
             posts
           else
             Enum.reject(posts, &Map.get(&1, :draft, false))
           end
         end)

  # Let's also get all tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts
  def all_tags, do: @tags

  defmodule NotFoundError, do: defexception([:message, plug_status: 404])

  def get_post_by_id!(id) do
    Enum.find(all_posts(), &(&1.id == id)) ||
      raise NotFoundError, "post with id=#{id} not found"
  end

  def get_posts_by_tag!(tag) do
    case Enum.filter(all_posts(), &(tag in &1.tags)) do
      [] -> raise NotFoundError, "posts with tag=#{tag} not found"
      posts -> posts
    end
  end

  def add_peek(post_title) do
    peek = Peek.changeset(%Peek{}, %{"post" => post_title, "count" => 49})

    to_run = fn ->
      Repo.insert(peek)
    end

    to_run.()

    Repo.replicate(to_run)
  end
end
