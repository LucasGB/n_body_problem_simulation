defmodule NBodyProblemSimulationWeb.SimulationLive do
  use NBodyProblemSimulationWeb, :live_view

  alias NBodyProblemSimulation.Simulation
  alias NBodyProblemSimulation.SimulationServer

  @simulation_update_topic "simulation:update"
  @grid_update "grid_update"
  @tick_interval 50  # milliseconds between ticks
  @dt 0.001          # simulation time step

  @impl true
  def mount(%{"simulation_id" => simulation_id}, _session, socket) do
    if connected?(socket) do
      # Subscribe to simulation updates on a namespaced topic.
      Phoenix.PubSub.subscribe(NBodyProblemSimulation.PubSub, "#{@simulation_update_topic}:#{simulation_id}")
    end

    simulation =
      case Registry.lookup(NBodyProblemSimulation.SimulationRegistry, simulation_id) do
        [{_pid, _}] -> SimulationServer.get_state(simulation_id)
        [] -> nil
      end

    socket =
      assign(socket,
        simulation_id: simulation_id,
        simulation: simulation
      )

    {:ok, socket}
  end
  
  @impl true
  def handle_event("stop_simulation", _params, socket) do
    simulation_id = socket.assigns.simulation_id
    SimulationServer.stop_simulation(simulation_id)
    {:noreply, push_navigate(socket, to: "/")}
  end

  @impl true
  def handle_info({:simulation_update, new_simulation}, socket) do
    socket =
      socket
      |> assign(:simulation, new_simulation)

    grid_data = new_simulation.grid
    socket = Phoenix.LiveView.push_event(socket, @grid_update, %{grid: grid_data})

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <h1>Simulation: <%= @simulation_id %></h1>
      
      <%= if @simulation do %>
        <div id="simulation" phx-hook="ThreeDHook" data-simulation={Jason.encode!(@simulation.bodies)}>
          <canvas id="three-canvas" phx-update="ignore" style="width: 800px; height: 600px;"></canvas>
        </div>
        <div id="ui-container" style="display: flex; flex-direction: row; align-items: flex-start; gap: 10px;">
          <button 
            phx-click="stop_simulation"
          >
            Stop Simulation
          </button>
          <button
            id="adjust-button"
            style={"background-color: #f12; color: #fff; padding: 10px; border-radius: 5px; width: 120px; text-align: center; cursor: pointer; border: 1px solid white;"}
          >
            Auto Focus
          </button>
          <button
            id="show-grid-lines"
            style={"background-color: #2f1; color: #fff; padding: 10px; border-radius: 5px; width: 120px; text-align: center; cursor: pointer; border: 1px solid white;"}
          >
            Show Grid
          </button>
          <%= for body <- @simulation.bodies do %>
            <button
              class="focus-button"
              style={"background-color: ##{Integer.to_string(body.color, 16) |> String.pad_leading(6, "0")}; color: #fff; padding: 10px; border-radius: 5px; width: 120px; text-align: center; cursor: pointer; border: 1px solid white;"}
              data-body-id={body.id}
            >
              ID {body.id}
            </button>
          <% end %>
        </div>
      <% else %>
        <p>Simulation is not running.</p>
      <% end %>
    """
  end
end
