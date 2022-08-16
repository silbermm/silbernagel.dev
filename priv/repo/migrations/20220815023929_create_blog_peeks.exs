defmodule Silbernageldev.Repo.Migrations.CreateBlogPeeks do
  use Ecto.Migration

  def change do
    create table(:blog_peeks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :post, :string
      add :count, :integer

      timestamps()
    end
  end
end
