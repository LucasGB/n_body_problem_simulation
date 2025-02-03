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
    <div id="simulation" phx-hook="ThreeDHook" data-simulation={ Jason.encode!(@simulation.bodies) }>
    <!-- The canvas where three.js will render the 3D scene -->
    <canvas id="three-canvas" phx-update="ignore" style="width: 800px; height: 600px;"></canvas>
    </div>
    """
  end
end
