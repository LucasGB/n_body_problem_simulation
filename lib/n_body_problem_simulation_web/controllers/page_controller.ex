defmodule NBodyProblemSimulationWeb.PageController do
  use NBodyProblemSimulationWeb, :controller
  alias NBodyProblemSimulation.InitialState

  def index(conn, _params) do
    available_states = InitialState.list_states()
    render(conn, "index.html", available_states: available_states)
  end

  def create_simulation(conn, %{
        "simulation_id" => simulation_id,
        "integration_method" => integration_method,
        "initial_state" => initial_state
      }) do

    strategy = case integration_method do
      "euler_cromer" -> NBodyProblemSimulation.Integration.EulerCromer
      "velocity_verlet" -> NBodyProblemSimulation.Integration.VelocityVerlet
      _ -> NBodyProblemSimulation.Integration.EulerCromer
    end

    simulation_initial_state = InitialState.load_state(initial_state)

    child_spec = {NBodyProblemSimulation.SimulationServer,
                  {simulation_id, simulation_initial_state, strategy}}

    DynamicSupervisor.start_child(NBodyProblemSimulation.SimulationSupervisor, child_spec)

    redirect(conn, to: ~p"/#{simulation_id}")
  end
end
