defmodule NBodyProblemSimulation.Integration.EulerCromer do
  @moduledoc """
  Euler-Cromer integration for N‑body simulation using Nx.
  """
  @behaviour NBodyProblemSimulation.Integration

  alias NBodyProblemSimulation.NxUtils
  require Nx.Defn
  require Logger

  Nx.Defn.defn euler_cromer_step(positions, velocities, masses, dt, g_constant) do
    accelerations = NxUtils.compute_accelerations(positions, masses, g_constant)
    new_velocities = Nx.add(velocities, Nx.multiply(accelerations, dt))
    new_positions = Nx.add(positions, Nx.multiply(new_velocities, dt))
    {new_positions, new_velocities}
  end

  @impl true
  @spec update(NBodyProblemSimulation.Simulation.t(), keyword()) ::
          NBodyProblemSimulation.Simulation.t()
  def update(%NBodyProblemSimulation.Simulation{bodies: bodies} = simulation, opts) do
    
    dt = Keyword.fetch!(opts, :dt)
    g_constant = Keyword.fetch!(opts, :g_constant)

    {positions, velocities, masses} = NxUtils.extract_tensors(bodies)
    Logger.info("Starting GPU Euler-Cromer integration computation")
    start_time = System.monotonic_time()
    
    {new_positions, new_velocities} = euler_cromer_step(positions, velocities, masses, dt, g_constant)
    
    end_time = System.monotonic_time()
    Logger.info("GPU Euler-Cromer integration computation finished in #{System.convert_time_unit(end_time - start_time, :native, :millisecond)} ms")
    
    new_bodies = NxUtils.update_bodies(bodies, new_positions, new_velocities)

    %{simulation | bodies: new_bodies, time: simulation.time + dt}
  end
end
