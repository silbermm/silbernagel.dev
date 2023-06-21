defmodule Silbernageldev.WebMentions.SenderSupervisor do
  @moduledoc false
  use DynamicSupervisor

  alias Silbernageldev.Blog
  alias Silbernageldev.WebMentions.WebMentionSender

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # as part of starting the WebMentionSupervisor, we also
    # start the task of sending web mentions for all articles
    # already written via Tasks
    send_web_mentions()
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def send_web_mentions() do
    Enum.map(Blog.all_posts(), &send_web_mentions_for/1)
  end

  defp send_web_mentions_for(post) do
    Task.Supervisor.start_child(Silbernageldev.TaskSupervisor, fn ->
      WebMentionSender.start_link(post)
    end)
  end
end
