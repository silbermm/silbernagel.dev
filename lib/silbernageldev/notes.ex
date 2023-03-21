defmodule Silbernageldev.Notes do
  @moduledoc """
  This is what builds my [notes](https://indieweb.org/note)
  """

  import Ecto.Query

  alias Ecto.Changeset
  alias Silbernageldev.Notes.Note
  alias Silbernageldev.Repo

  @doc """
  Create a new note

  If draft is false, then we are NOT creating this as a draft,
  and we'll want to also send webmentions after creating the
  note (if there are links and/or a reply_to set
  """
  @spec create(map()) :: {:ok, Note.t()} | {:error, Changeset.t()}
  def create(%{"draft" => false} = params) do
    # create the note
    params
    |> Note.changeset()
    |> Repo.insert()
    |> maybe_send_webmentions()
  end

  def create(params) do
    params
    |> Note.changeset()
    |> Repo.insert()
  end

  @doc """
  Get all notes with optional limit, offset and draft status
  """
  @spec all(Keyword.t()) :: [Note.t()]
  def all(opts \\ []) do
    limit = Keyword.get(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)
    draft = Keyword.get(opts, :draft)

    query = from(n in Note)
    query = maybe_with_draft(query, draft)
    query = maybe_with_limit(query, limit, offset)

    Repo.all(query)
  end

  def get(note_id) do
    Repo.get(Note, note_id)
  end

  @spec publish(binary()) :: {:ok, Note.t()} | {:error, Changeset.t()}
  def publish(note_id) do
    note_id
    |> get()
    |> Note.publish_changeset()
    |> Repo.update()
  end

  defp maybe_with_limit(query, nil, _), do: query

  defp maybe_with_limit(query, limit, offset),
    do: from(q in query, limit: ^limit, offset: ^offset)

  defp maybe_with_draft(query, nil), do: query

  defp maybe_with_draft(query, draft) when is_boolean(draft),
    do: from(q in query, where: q.draft == ^draft)

  defp maybe_with_draft(query, _draft), do: query

  defp maybe_send_webmentions({:ok, _note} = res) do
    # @TODO 
    res
  end

  defp maybe_send_webmentions({:error, _changeset} = res) do
    # @TODO 
    res
  end
end
