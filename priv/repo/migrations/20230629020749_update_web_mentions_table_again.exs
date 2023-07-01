defmodule Silbernageldev.Repo.Migrations.UpdateWebMentionsTableAgain do
  use Ecto.Migration

  def change do
    alter table(:web_mentions) do
      add(:webmention_endpoint, :string)
    end
  end
end
