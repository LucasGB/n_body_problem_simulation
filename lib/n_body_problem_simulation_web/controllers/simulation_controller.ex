defmodule NBodyProblemSimulationWeb.SimulationController do
  use NBodyProblemSimulationWeb, :controller
  alias NBodyProblemSimulation.InitialState
  alias NBodyProblemSimulation.SimulationServer

  def show(conn, %{"simulation_id" => simulation_id}) do
    simulation_running =
      case Registry.lookup(NBodyProblemSimulation.SimulationRegistry, simulation_id) do
        [{_pid, _}] -> true
        [] -> false
      end

    available_states = InitialState.list_states()

    render(conn, :show,
      simulation_id: simulation_id,
      simulation_running: simulation_running,
      available_states: available_states
    )
  end

  @spec start_simulation(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def start_simulation(conn, %{
        "simulation_id" => simulation_id,
        "integration_method" => integration_method,
        "initial_state" => initial_state
      }) do

    strategy = case integration_method do
      "euler-cromer" -> NBodyProblemSimulation.Integration.EulerCromer
      "velocity-verlet" -> NBodyProblemSimulation.Integration.VelocityVerlet
    end

    simulation_initial_state = InitialState.load_state(initial_state)

    child_spec = {NBodyProblemSimulation.SimulationServer, {simulation_id, simulation_initial_state, strategy}}
    DynamicSupervisor.start_child(NBodyProblemSimulation.SimulationSupervisor, child_spec)

    redirect(conn, to: ~p"/#{simulation_id}")
  end

  def list_running_simulations(conn, _params) do
    running_simulations =
      Registry.select(NBodyProblemSimulation.SimulationRegistry, [{{:"$1", :_}, [], [:"$1"]}])

    render(conn, "running_simulations.html", running_simulations: running_simulations)
  end
end
