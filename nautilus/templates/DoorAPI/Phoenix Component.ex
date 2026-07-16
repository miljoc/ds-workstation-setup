defmodule DoorAPIWeb.ExampleComponents do
  use Phoenix.Component

  attr :title, :string, required: true

  def card(assigns) do
    ~H"""
    <section class="rounded-xl border p-4">
      <h2>{@title}</h2>
      {render_slot(@inner_block)}
    </section>
    """
  end
end
