defmodule Silbernageldev.WebMentions.WebMention do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "web_mentions" do
    field(:source_id, :string)
    field(:source_type, Ecto.Enum, values: [:post, :note])
    field(:url, :string)
    field(:sha, :string)
    field(:status, Ecto.Enum, values: [:sent, :not_found, :failed, :pending])
    field(:webmention_endpoint, :string, virtual: true)
    timestamps()
  end

  @attrs [:source_id, :source_type, :url, :status, :sha, :url]

  def changeset(mention \\ %WebMention{}, params) do
    mention
    |> cast(params, @attrs ++ [:webmention_endpoint])
    |> validate_required(@attrs)
  end
end
