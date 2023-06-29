defmodule Silbernageldev.WebMentions.WebMentionStorage do
  @behaviour Libmention.StorageApi

  import Ecto.Query
  alias Silbernageldev.Repo
  alias Silbernageldev.WebMentions.WebMention

  # %{
  #   source_url: String.t(),
  #   target_url: String.t(),
  #   endpoint: String.t(),
  #   status: :sent | :not_found | :failed | :pending,
  #   sha: String.t()
  # }

  @impl true
  def update(entity) do
    existing_mention = get(entity)
    changeset = WebMention.changeset(existing_mention, entity)
    Repo.update(changeset)
  end

  @impl true
  def save(entity) do
    changeset = WebMention.changeset(entity)
    Repo.insert(changeset)
  end

  @impl true
  def get(entity) do
    WebMention
    |> where([wm], wm.source_url == ^entity.source_url)
    |> where([wm], wm.target_url == ^entity.target_url)
    |> Repo.one()
  end

  @impl true
  def exists?(entity) do
    WebMention
    |> where([wm], wm.source_url == ^entity.source_url)
    |> where([wm], wm.target_url == ^entity.target_url)
    |> Repo.exists?()
  end
end
