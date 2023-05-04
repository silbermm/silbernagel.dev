defmodule Silbernageldev.Repo.Migrations.CreateWebMentionsTable do
  use Ecto.Migration

  def change do
    create table(:web_mentions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_id, :string
      add :source_type, :string
      add :url, :string
      add :sha, :text
      add :status, :string

      timestamps()
    end
  end
end
