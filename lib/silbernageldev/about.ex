defmodule Silbernageldev.About do
  @moduledoc false
  alias Silbernageldev.About.Content

  use NimblePublisher,
    build: Content,
    from: Application.app_dir(:silbernageldev, "priv/content/about/about.md"),
    as: :about,
    highlighters: [:makeup_elixir, :makeup_erlang]

  def content, do: List.first(@about)
end
