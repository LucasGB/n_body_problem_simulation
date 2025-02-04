defmodule NBodyProblemSimulationWeb.SimulationLive do
  # use Phoenix.LiveView
  use NBodyProblemSimulationWeb, :live_view

  alias NBodyProblemSimulation.Simulation

  @tick_interval 50  # milliseconds between ticks
  @dt 0.05           # simulation time step

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(@tick_interval, self(), :tick)
    simulation = Simulation.initial_state()
    {:ok, assign(socket, simulation: simulation)}
  end

  @impl true
  def handle_info(:tick, socket) do
    simulation = Simulation.update(socket.assigns.simulation, dt: @dt)
    {:noreply, assign(socket, simulation: simulation)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <h1>N-body Problem</h1>

      <div id="simulation" phx-hook="ThreeDHook" data-simulation={Jason.encode!(@simulation.bodies)}>
        <canvas id="three-canvas" phx-update="ignore" style="width: 800px; height: 600px;"></canvas>
      </div>

      <div id="ui-container" style="display: flex; flex-direction: row; align-items: flex-start; gap: 10px;">
        <%= for body <- @simulation.bodies do %>
          <button 
            class="focus-button"
            style={"background-color: #{body.color}; color: #fff; padding: 10px; border-radius: 5px; width: 120px; text-align: center; cursor: pointer; border: 1px solid white;"}
            data-body-id={body.id}
          >
            ID {body.id}
          </button>
        <% end %>
      </div>
    """
  end
end
