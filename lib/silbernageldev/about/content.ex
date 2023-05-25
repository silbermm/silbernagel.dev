defmodule Silbernageldev.About.Content do
  @enforce_keys [:author, :title, :body, :description, :published]
  defstruct [:author, :title, :body, :description, :published, :draft, :updated]

  def build(_filename, attrs, body) do
    struct!(__MODULE__, [body: body] ++ Map.to_list(attrs))
  end
end
