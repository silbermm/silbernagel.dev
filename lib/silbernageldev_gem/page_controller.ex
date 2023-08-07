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
    response = list_posts(base_url: base_url, posts: posts)
    gmi(req, response)
  end

  def gemlog_post(req, %{"post_id" => post_id}) do
    base_url = "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"
    post = Blog.get_post_by_id!(post_id)
    response = post(post: post, base_url: base_url)
    gmi(req, response)
  end

  def public_key(req, _params) do
    base_url = "gemini://#{Application.get_env(:silbernageldev, :gemini_host)}"
    response = _public_key(base_url: base_url)
    gmi(req, response)
  end

  defp _public_key(assigns) do
    ~G"""
    # ahappydeath's Public Key

    => <%= @base_url %>/ ⬅ Back

    ```
    -----BEGIN PGP PUBLIC KEY BLOCK-----

    mQINBGDFEK4BEACktdBDgIKkaHK66Hx6kQkxOEbXN46VlscmkI976l+7gw1XVNPH
    ExlB1Z/ftLmP8WG1pUClbKmddE/nyK0cc6iHWPKqxJ9uGl9XZF4rpsmNMV7VPB7L
    gZ3LsSlHkYVWYNGB1CFdTnzaSkh3SzUJJPrAQUwpoJmtjLSRirx3a3/+LAW9iIS7
    bub42YEtLfKop56PWrC1gPwj/iuQ7IxBUq3bNv6JijzttpAElJnmcVdwluq5VRBT
    jgHJvS5ei53MRNegHWnUeddoT0Hd5VYB5UnEExuR4hvjNLK/RHBO6ohoU5Vx7z4a
    LAjIed1YgScODp3IOzzn4zQ2eq18V4zSRATVV7uNjzs/1zeiJbppSWYyooq08xRr
    ZfUDR7H29JX+OuGejWs2/0cQp4ChL7QsfYsKwSR3WYLeIeidy2OWPxYoTuCv4YuD
    EWeNo9xLSZnVAoxQbN/RvO30bMimHEUWdO1l3GZnM+WFV0kKI89xwFeiLBq7ghBE
    nXSpZOcvwQD5g4/c3RtUGcTLMup0k7uTwoUNprOu+82WIQc0bPZD9R9ip2PrxjjW
    gN7PFPuoG03uaJ5x9eaTUb5q5Sbwu9ykvocvxvPHiQUnfIa9UA5mamN+uXgWVrXZ
    2v6XAXXXRCEUlUIM+d9cPYSp/gVpp4qoC0UpFQcOVPHsz/oaxuZf7ADa9QARAQAB
    tDVNYXR0IFNpbGJlcm5hZ2VsIChXb3JrKSA8bWF0dC5zaWxiZXJuYWdlbEBnZXR0
    aHJ1LmlvPokCTgQTAQoAOBYhBIDI965k5YlEn7CgOXTbZwhCLdM7BQJkFjp1AhsD
    BQsJCAcCBhUKCQgLAgQWAgMBAh4BAheAAAoJEHTbZwhCLdM7CKQP/RaOp+zMMSqF
    RAyytKEsJhCFZVy3cCwca5n9kBlGY047dc0D0HgckRbCN+fvPS+4t5dQo4+c1EJ8
    Qc9+kGbRmziBjmNgftp3iBr0ocKaa7he3hSrLNS1oyemj21iWLXrtFf7OgYy3tQR
    dUwjbHXLWcbTT7bzXV9aDIv/NsdrmCe7kTyUQ9DHPEmnpl86OiYRCD6mMnBKhk5U
    if4MjAldENT7EXKtQKSsI07x3gBpG+njBGa6HgIVSOgqhYTXTuXKjpNlBTiNizWQ
    gJXrDCAFeHBBdUabdnYAZYHN2fKyicWCrjgCPMyj6kzOleYK8ACjJQoLtApL1yup
    3gpoPw86fzd5UyAtFZd/RcwZbF9Ivbpjt0OZouxxCe9zw8G5cSKSCoF35NPovJ37
    d/SqREW24iyxCEvYTzpx95abVB6ig/36AUJAwElcRal6SYfbg/Dqlc7gzQ7lzUKh
    FV55HuZe633IDDJMUla14GxRMYFjQMNlzR64AKRSzw8JHzx+qgxikQFclGFvQ0Lq
    dx26J32xsccKX8C7qGgcMl78FJFXvfRPQYqtd+XNxVfoswmgPAYkNG9xkIoyIqxT
    vQNECrl6ww7gqZlq9EhclVz1wVIcludBW3zHfLMZg5uSIrRjZXuXg4DY6Khsmd9/
    wWRWfYV3EMcfrBmqLA60uYmr/FHTD3ujtCdNYXR0IFNpbGJlcm5hZ2VsIDxtYXR0
    QHNpbGJlcm5hZ2VsLmRldj6JA5UEEwEIAX8CGwMFCwkIBwIGFQoJCAsCBBYCAwEC
    HgECF4A6FIAAAAAAEAAhcHJvb2ZAYXJpYWRuZS5pZGh0dHBzOi8vbGljaGVzcy5v
    cmcvQC9haGFwcHlkZWF0aFoUgAAAAAAQAEFwcm9vZkBhcmlhZG5lLmlkaHR0cHM6
    Ly9naXN0LmdpdGh1Yi5jb20vc2lsYmVybW0vOTgxN2QxMGIxYzUyMDM4MGE3YTUy
    YTk1N2EzYmVlZmM1FIAAAAAAEAAccHJvb2ZAYXJpYWRuZS5pZGRuczpzaWxiZXJu
    YWdlbC5kZXY/dHlwZT1UWFQ+FIAAAAAAEAAlcHJvb2ZAYXJpYWRuZS5pZGh0dHBz
    Oi8vZnJlZXJhZGljYWwuem9uZS9AYWhhcHB5ZGVhdGg4FIAAAAAAEAAfcHJvb2ZA
    YXJpYWRuZS5pZGh0dHBzOi8vbG9ic3RlLnJzL3UvYWhhcHB5ZGVhdGgWIQSAyPeu
    ZOWJRJ+woDl022cIQi3TOwUCZBY+ngIZAQAKCRB022cIQi3TO2z0D/9pwnjFwkiJ
    ecwTJ6QQfluaEUavWJhbXNZ1zB3FoL0xRkyJIYfS9rG4fB9IQfO1DwuvcX3ux9Oo
    Gk7JwNo6lC92zYYIktvIUPmc0yP+ttMsXRa8JoAtv3MZ8Kti1GdCMbKBynjJjwud
    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
    uu+EJTPSaBSUYgF0Cqvsgwhe
    =qLKS
    -----END PGP PUBLIC KEY BLOCK-----
    ```
    """
  end

  defp list_posts(assigns) do
    ~G"""
    # ahappydeath's Gemlog

    <%= for post <- @posts do %>
    => <%= @base_url %>/gemlog/<%= post.id %> 🗒<%= post.title %>
    <%= post.description %>
    <%= Calendar.strftime(post.date, "%a, %B %d %Y") %>
    <% end %>

    => <%= @base_url %>/ ⬅ Back
    """
  end

  defp post(assigns) do
    ~G"""
    # <%= @post.title %>
    <%= @post.gemtext %>

    => <%= @base_url %>/ ⬅ Back
    """
  end
end
