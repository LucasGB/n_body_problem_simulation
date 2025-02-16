defmodule NBodyProblemSimulation.Integration.VelocityVerlet do
  @moduledoc """
  Velocity Verlet integration for N‑body simulation using Nx.
  """
  @behaviour NBodyProblemSimulation.Integration

  alias NBodyProblemSimulation.NxUtils
  require Nx.Defn

  @doc """
  Performs a complete Velocity Verlet integration step.

  - `positions`: an {N, 3} tensor.
  - `velocities`: an {N, 3} tensor.
  - `masses`: an {N} tensor.
  - `dt`: time step.
  - `g`: gravitational constant.

  Returns a tuple `{new_positions, new_velocities}` as Nx tensors.
  """
  Nx.Defn.defn velocity_verlet_step(positions, velocities, masses, dt, g) do
    initial_accelerations = NxUtils.compute_accelerations(positions, masses, g)
    new_positions = Nx.add(positions, Nx.add(Nx.multiply(velocities, dt), Nx.multiply(initial_accelerations, 0.5 * Nx.pow(dt, 2))))
    
    new_accelerations = NxUtils.compute_accelerations(new_positions, masses, g)
    new_velocities = Nx.add(velocities, Nx.multiply(Nx.add(initial_accelerations, new_accelerations), 0.5 * dt))

    {new_positions, new_velocities}
  end

  @impl true
  @spec update(NBodyProblemSimulation.Simulation.t(), keyword()) ::
          NBodyProblemSimulation.Simulation.t()
  def update(%NBodyProblemSimulation.Simulation{bodies: bodies} = simulation, opts) do
    dt = Keyword.fetch!(opts, :dt)
    g_constant = Keyword.fetch!(opts, :g_constant)
    
    {positions, velocities, masses} = NxUtils.extract_tensors(bodies)
    {new_positions, new_velocities} = velocity_verlet_step(positions, velocities, masses, dt, g_constant)
    new_bodies = NxUtils.update_bodies(bodies, new_positions, new_velocities)

    %{simulation | bodies: new_bodies, time: simulation.time + dt}
  end
end
