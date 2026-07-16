defmodule MyAppWeb.ExampleLive do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Example")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>{@page_title}</h1>
    </div>
    """
  end
end
