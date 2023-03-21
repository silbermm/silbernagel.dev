defmodule Silbernageldev.Notes.Note do
  alias Ecto.Changeset
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [:id, :author, :draft, :reply_to, :tags, :content, :inserted_at, :published_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field :author, :string, default: "matt@silbernagel.dev"
    field :draft, :boolean, default: true
    field :reply_to, :string
    field :tags, {:array, :string}
    field :content, :string
    field :published_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(note \\ %__MODULE__{}, attrs) do
    note
    |> cast(attrs, [:author, :tags, :reply_to, :draft, :content, :published_at])
    |> validate_required([:content])
  end

  @doc """
  Use this when a note already exists and it needs a published_at date
  and the draft flag removed
  """
  def publish_changeset(nil) do
    %__MODULE__{}
    |> changeset(%{})
    |> Changeset.add_error(:id, "not found")
  end

  def publish_changeset(note) do
    note
    |> changeset(%{})
    |> validate_publish_at_date()
    |> unset_draft()
  end

  defp validate_publish_at_date(changeset) do
    utc_now =
      DateTime.utc_now()
      |> DateTime.truncate(:second)

    Changeset.put_change(changeset, :published_at, utc_now)
  end

  defp unset_draft(changeset), do: Changeset.put_change(changeset, :draft, false)
end
