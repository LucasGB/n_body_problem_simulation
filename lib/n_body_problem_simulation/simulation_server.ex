defmodule NBodyProblemSimulation.SimulationServer do
  @moduledoc """
  A GenServer that holds the simulation state and updates it sequentially
  using the selected integration strategy.
  """
  
  use GenServer
  alias NBodyProblemSimulation.Simulation

  @pubsub_topic "simulation:update"
  @tick_interval 50   # milliseconds between updates
  @dt 0.001           # simulation time step

  #  child spec efinition so this module can be started by a supervisor
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      type: :worker,
      restart: :permanent
    }
  end
  
  def via_tuple(simulation_id),
    do: {:via, Registry, {NBodyProblemSimulation.SimulationRegistry, simulation_id}}

  def start_link({simulation_id, initial_simulation, strategy}) do
    GenServer.start_link(__MODULE__, {initial_simulation, strategy, simulation_id, true}, name: via_tuple(simulation_id))
  end

  def get_state(simulation_id) do
    GenServer.call(via_tuple(simulation_id), :get_state, 10_000)
  end

  def set_strategy(simulation_id, strategy) do
    GenServer.cast(via_tuple(simulation_id), {:set_strategy, strategy})
  end
  
  def stop_simulation(simulation_id) do
    case Registry.lookup(NBodyProblemSimulation.SimulationRegistry, simulation_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(NBodyProblemSimulation.SimulationSupervisor, pid)
      [] -> :ok
    end
  end
  
  def toggle_grid(simulation_id) do
    GenServer.cast(via_tuple(simulation_id), :toggle_grid)
  end

  # GenServer Callbacks

  @impl true
  def init({initial_simulation, strategy, simulation_id, grid_enabled}) do
    :timer.send_interval(@tick_interval, :tick)
    {:ok, %{simulation: initial_simulation, strategy: strategy, id: simulation_id, grid_enabled: grid_enabled}}
  end

  @impl true
  def handle_info(:tick, %{simulation: simulation, strategy: strategy, id: simulation_id, grid_enabled: grid_enabled} = state) do
    new_simulation = Simulation.update(simulation, dt: @dt, strategy: strategy, grid_enabled: grid_enabled)
    
    if new_simulation != simulation do
      new_simulation = if grid_enabled do
          new_simulation
        else
          %{new_simulation | grid: nil}
      end
      Phoenix.PubSub.broadcast(
        NBodyProblemSimulation.PubSub,
        "#{@pubsub_topic}:#{simulation_id}",
        {:simulation_update, new_simulation}
      )
    end
    
    {:noreply, %{state | simulation: new_simulation}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.simulation, state}
  end

  @impl true
  def handle_cast({:set_strategy, new_strategy}, state) do
    {:noreply, %{state | strategy: new_strategy}}
  end 
  
  @impl true
  def handle_cast(:toggle_grid, state) do
    new_state = Map.update!(state, :grid_enabled, &(!&1))
  
    new_simulation =
      if new_state.grid_enabled do
        new_state.simulation
      else
        %{new_state.simulation | grid: nil}
      end

    Phoenix.PubSub.broadcast(
      NBodyProblemSimulation.PubSub,
      "#{@pubsub_topic}:#{state.id}",
      {:simulation_update, new_simulation}
    )

    {:noreply, new_state}
  end
end
