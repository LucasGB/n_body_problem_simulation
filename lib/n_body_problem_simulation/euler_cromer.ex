defmodule NBodyProblemSimulation.Integration.EulerCromer do
  @moduledoc """
  Euler-Cromer integration for N‑body simulation.
  """
  @behaviour NBodyProblemSimulation.Integration

  alias NBodyProblemSimulation.Math

  @impl true
  def update(simulation, dt: dt) do
    new_bodies =
      Enum.map(simulation.bodies, fn body ->
        acceleration = Math.compute_acceleration(body, simulation.bodies)
        new_vel = Math.add_vectors(body.vel, Math.scalar_mult(acceleration, dt))
        new_pos = Math.add_vectors(body.pos, Math.scalar_mult(new_vel, dt))
        Map.merge(body, %{vel: new_vel, pos: new_pos})
      end)

    %{simulation | bodies: new_bodies}
  end
end
