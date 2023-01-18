defmodule Silbernageldev.WebMentions.WebMentionSender do
  @moduledoc """
  A process that searches through a blog post for
  links and attempts to send a webmention
  end
  """

  use GenServer, restart: :temporary
  require Logger

  @posts Silbernageldev.Blog.all_posts()

  def start_link(post_id) do
    GenServer.start_link(__MODULE__, post_id)
  end

  @impl true
  def init(post_id) do
    post = Enum.find(@posts, fn p -> p.id == post_id end)
    {:ok, %{post: post}, {:continue, :searh_post}}
  end
  
  @impl true
  def handle_continue(:search_post, state) do
    Logger.info("[WebMentionSender] | Searching for links in #{state.post.name}")
    {:noreply, state}
  end
end
