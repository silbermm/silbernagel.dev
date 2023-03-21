defmodule Silbernageldev.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :author, :string, default: "matt@silbernagel.dev"
      add :tags, {:array, :string}
      add :reply_to, :string
      add :draft, :boolean, default: true, null: false
      add :content, :text
      add :published_at, :utc_datetime, null: true

      timestamps()
    end
  end
end
