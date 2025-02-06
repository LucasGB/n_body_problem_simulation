defmodule NBodyProblemSimulation.SimulationServer do
  @moduledoc """
  A GenServer that holds the simulation state and updates it sequentially
  using the selected integration strategy.
  """
  
  use GenServer
  alias NBodyProblemSimulation.Simulation

  @tick_interval 50   # milliseconds between updates
  @dt 0.001

  #  child spec efinition so this module can be started by a supervisor
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [init_arg]},
      type: :worker,
      restart: :permanent
    }
  end

  def start_link({initial_simulation, strategy}) do
    GenServer.start_link(__MODULE__, {initial_simulation, strategy}, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def set_strategy(strategy) do
    GenServer.cast(__MODULE__, {:set_strategy, strategy})
  end

  # GenServer Callbacks

  @impl true
  def init({initial_simulation, strategy}) do
    :timer.send_interval(@tick_interval, :tick)
    {:ok, %{simulation: initial_simulation, strategy: strategy}}
  end

  @impl true
  def handle_info(:tick, %{simulation: simulation, strategy: strategy} = state) do
    new_simulation = Simulation.update(simulation, dt: @dt, strategy: strategy)
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
end
