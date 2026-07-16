defmodule DoorAPI.Examples do
  @moduledoc "The Examples context."

  alias DoorAPI.Repo
  alias DoorAPI.Example

  def list_examples do
    Repo.all(Example)
  end
end
