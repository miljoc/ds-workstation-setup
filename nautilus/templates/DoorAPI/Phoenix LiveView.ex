defmodule DoorAPIWeb.ExampleLive do
  use DoorAPIWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Example", loading: false)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="example-live">
      <.header>{@page_title}</.header>
      <button type="button" phx-click="refresh">Refresh</button>
    </div>
    """
  end
end
