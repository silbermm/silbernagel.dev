defmodule Silbernageldev.Repo.Migrations.UpdateWebMentionsTableEndpoing do
  use Ecto.Migration

  def change do
    rename table(:web_mentions), :webmention_endpoint, to: :endpoint
  end
end
