defmodule Silbernageldev.Repo.Migrations.UpdateWebMentionsTable do
  use Ecto.Migration

  def change do
    alter table(:web_mentions) do
      add :source_url, :string
      remove :source_id
    end 

    rename table(:web_mentions), :url, to: :target_url
  end
end
