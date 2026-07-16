defmodule DoorAPI.Devices.ExampleHandler do
  @moduledoc false

  require Logger

  @spec handle(map()) :: :ok | {:error, term()}
  def handle(payload) when is_map(payload) do
    Logger.metadata(component: __MODULE__)
    Logger.debug("Handling device payload")
    :ok
  end
end
