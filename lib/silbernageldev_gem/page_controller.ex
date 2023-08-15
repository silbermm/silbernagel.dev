defmodule SilbernageldevGem.PageController do
  alias Silbernageldev.Blog
  use SilbernageldevGem, :controller

  view(SilbernageldevGem.PageView)

  import Orbit.Gemtext

  def home(req, _params) do
    name = if req.client_cert, do: req.client_cert.common_name, else: "world"
    base_url = "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"

    req
    |> assign(name: name, base_url: base_url)
    |> render()
  end

  def gemlog(req, _params) do
    base_url = "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"
    posts = Blog.all_posts()

    req
    |> assign(posts: posts, base_url: base_url)
    |> render()
  end

  def gemlog_post(req, %{"post_id" => post_id}) do
    base_url = "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"
    post = Blog.get_post_by_id!(post_id)

    req
    |> assign(post: post, base_url: base_url)
    |> render()
  end

  def public_key(req, _params) do
    base_url = "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"
    # response = _public_key(base_url: base_url)
    # gmi(req, response)

    req
    |> assign(base_url: base_url)
    |> render()
  end

  defp post(assigns) do
    ~G"""
    # <%= @post.title %>
    <%= @post.gemtext %>

    => <%= @base_url %>/ ⬅ Back
    """
  end
end
