defmodule DoorAPI.Integrations.Example do
  @moduledoc """
  Integration boundary for Example.
  """

  require Logger

  @spec execute(map()) :: {:ok, term()} | {:error, term()}
  def execute(params) when is_map(params) do
    Logger.debug("Executing Example integration")
    {:ok, params}
  end
end
