defmodule DoorAPI.Example do
  use Ecto.Schema
  import Ecto.Changeset

  schema "examples" do
    field :name, :string
    timestamps(type: :utc_datetime_usec)
  end

  @required_fields ~w(name)a

  def changeset(example, attrs) do
    example
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
