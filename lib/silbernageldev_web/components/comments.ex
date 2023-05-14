defmodule SilbernageldevWeb.Components.Comments do
  use SilbernageldevWeb, :component

  def info(assigns) do
    ~H"""
    <div class="text-gray-500">
      <button> <Heroicons.chevron_right mini class="h-4 w-4 inline" /> Learn how to respond, comment, like/favorite and repost </button>
    </div>
    """
  end

  def show(assigns) do
    ~H"""

    """
  end
end
