defmodule NBodyProblemSimulation.Integration.VelocityVerlet do
  @moduledoc """
  Velocity Verlet integration for N‑body simulation.
  """
  @behaviour NBodyProblemSimulation.Integration

  alias NBodyProblemSimulation.Math

  @impl true
  def update(simulation, dt: dt) do
    bodies_with_acc =
      Enum.map(simulation.bodies, fn body ->
        acc = Map.get(body, :acc, Math.compute_acceleration(body, simulation.bodies))
        Map.put(body, :acc, acc)
      end)

    updated_positions =
      Enum.map(bodies_with_acc, fn body ->
        new_pos =
          Math.add_vectors(
            body.pos,
            Math.add_vectors(
              Math.scalar_mult(body.vel, dt),
              Math.scalar_mult(body.acc, 0.5 * dt * dt)
            )
          )

        Map.put(body, :pos, new_pos)
      end)

    sim_with_new_positions = %{simulation | bodies: updated_positions}

    bodies_with_new_acc =
      Enum.map(sim_with_new_positions.bodies, fn body ->
        new_acc = Math.compute_acceleration(body, sim_with_new_positions.bodies)
        Map.put(body, :new_acc, new_acc)
      end)

    final_bodies =
      Enum.map(bodies_with_new_acc, fn body ->
        new_vel =
          Math.add_vectors(
            body.vel,
            Math.scalar_mult(Math.add_vectors(body.acc, body.new_acc), 0.5 * dt)
          )

        body
        |> Map.merge(%{vel: new_vel, acc: body.new_acc})
        |> Map.delete(:new_acc)
      end)

    %{simulation | bodies: final_bodies}
  end
end
