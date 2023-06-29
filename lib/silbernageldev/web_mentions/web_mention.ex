defmodule Silbernageldev.WebMentions.WebMention do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @type t :: %{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "web_mentions" do
    field(:source_url, :string)
    field(:target_url, :string)
    field(:sha, :string)
    field(:status, Ecto.Enum, values: [:sent, :not_found, :failed, :pending])
    field(:endpoint, :string)
    timestamps()
  end

  @attrs [:source_url, :target_url, :status, :sha, :endpoint]
  @required [:source_url, :target_url, :status, :sha]

  def changeset(mention \\ %WebMention{}, params) do
    mention
    |> cast(params, @attrs)
    |> validate_required(@required)
  end
end
