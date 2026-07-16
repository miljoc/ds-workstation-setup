defmodule DoorAPI.Repo.Migrations.CreateExample do
  use Ecto.Migration

  def change do
    create table(:examples) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:examples, [:name])
  end
end
