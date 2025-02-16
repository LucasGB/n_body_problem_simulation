defmodule NBodyProblemSimulation.Simulation do
  @moduledoc """
  An N‑body (extendable to more bodies) simulation in 3D using Euler‑Cromer integration.
  """
  alias NBodyProblemSimulation.Simulation
  alias NBodyProblemSimulation.InitialState
  alias NBodyProblemSimulation.Grid
  @g_constant (4 * :math.pi() * :math.pi())  # Gravitational constant compatible with 1 Solar Mass + 1 AU
  @g 6.67430*10.0e-11
  
  @solar_mass 1.0
  @solar_radii 20.0
  
  # Experimental parameters. Remove and set to function variables?
  @padding 1.0
  @grid_segments_per_axis 4

  @type t :: %__MODULE__{
    bodies: list(any()),
    grid: any(),
    time: number()
  }
  defstruct bodies: [],
            grid: nil,
            time: 0.0

  @doc """
  Returns the initial simulation state with N bodies.
  """
  @spec initial_state() :: t
  def initial_state do
      InitialState.initial_state()
  end

  @doc """
  Updates the simulation state by a time step dt using the given integration strategy that implements the NBodyProblemSimulation.Integration behavior.
  """
  @spec update(t, [{:dt, number()} | {:strategy, module()} | {:g_constant, number()}]) :: t
  def update(%Simulation{} = simulation, dt: dt, strategy: integration_module) do
    updated_bodies = integration_module.update(simulation, dt: dt, g_constant:  @g_constant)

    updated_grid = Grid.compute_grid(simulation.grid, updated_bodies.bodies, @grid_segments_per_axis, @padding, @g)

    %Simulation{simulation | bodies: updated_bodies.bodies, grid: updated_grid, time: simulation.time + dt}
  end
end
