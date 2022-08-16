defmodule Silbernageldev.Blog.Peek do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "blog_peeks" do
    field :count, :integer
    field :post, :string

    timestamps()
  end

  @doc false
  def changeset(peek, attrs) do
    peek
    |> cast(attrs, [:post, :count])
    |> validate_required([:post, :count])
  end
end
