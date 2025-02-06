defmodule NBodyProblemSimulationWeb.SimulationLive do
  use NBodyProblemSimulationWeb, :live_view

  alias NBodyProblemSimulation.Simulation
  alias NBodyProblemSimulation.SimulationServer

  @tick_interval 50  # milliseconds between ticks
  @dt 0.001          # simulation time step

  @impl true
  @spec mount(any(), any(), Phoenix.LiveView.Socket.t()) :: {:ok, any()}
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(@tick_interval, self(), :poll_simulation)
    simulation = Simulation.initial_state()
    {:ok, assign(socket, simulation: simulation)}
  end

  @impl true
  def handle_info(:poll_simulation, socket) do
    simulation = SimulationServer.get_state()
    {:noreply, assign(socket, simulation: simulation)}
  end
  
  @impl true
  def handle_event("change_strategy", %{"strategy" => strategy}, socket) do
    # Convert string strategy name to module
    strategy_module = case strategy do
      "euler_cromer" -> NBodyProblemSimulation.Integration.EulerCromer
      _ -> NBodyProblemSimulation.Integration.EulerCromer
    end

    SimulationServer.set_strategy(strategy_module)
    {:noreply, assign(socket, strategy: strategy_module)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <h1>N-body Problem</h1>
      <div id="select-strategy" phx-update="ignore">
        <label>Choose Integration Method:</label>
        <select phx-change="change_strategy">
          <option value="euler_cromer">Euler-Cromer</option>
          <option value="velocity_verlet">Velocity Verlet</option>
          <option value="runge-kutta-4">Runge-Kutta 4</option>
        </select>
      </div>
      
      <div id="simulation" phx-hook="ThreeDHook" data-simulation={Jason.encode!(@simulation.bodies)}>
        <canvas id="three-canvas" phx-update="ignore" style="width: 800px; height: 600px;"></canvas>
      </div>

      <div id="ui-container" style="display: flex; flex-direction: row; align-items: flex-start; gap: 10px;">
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
    """
  end
end
