defmodule DoorAPI.Clients.Example do
  @moduledoc false

  require Logger

  @spec request(keyword()) :: {:ok, term()} | {:error, term()}
  def request(opts \\ []) do
    Logger.debug("Example API request", options: inspect(opts))
    {:error, :not_implemented}
  end
end
