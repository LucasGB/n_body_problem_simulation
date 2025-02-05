defmodule NBodyProblemSimulation.Simulation do
  @moduledoc """
  A simple N‑body simulation in 3D using Euler‑Cromer integration.
  """

  @g 1.0  # Gravitational constant (set to 1 for simplicity)

  defstruct bodies: []

  @doc """
  Returns the initial simulation state with N bodies.
  """
  def initial_state do
    %NBodyProblemSimulation.Simulation{
      bodies: [
        %{
          id: 1,
          mass: 250.0,
          color: 0x0077ff,
          pos: {15.50, 10, 11.9},
          vel: {2.0, 1.5, -0.5}
        },
        %{
          id: 2,
          mass: 150.0,
          color: 0xff0000,
          pos: {10.0, -25, 15},
          vel: {-2.0, -2.0, 1}
        },
        %{
          id: 3,
          mass: 100.0,
          color: 0x00ff00,
          pos: {-23, -18.0, 8.0},
          vel: {2.0, -1.0, 0.75}
        },
        %{
          id: 4,
          mass: 170.0,
          color: 0x00ffff,
          pos: {-13, 23, 10},
          vel: {1.0, -2.0, -0.3}
        }
      ]
    }
  end

  @doc """
  Advances the simulation state by a time step dt.
  """
  def update(simulation, dt: dt) do
    new_bodies =
      Enum.map(simulation.bodies, fn body ->
        update_body(body, simulation.bodies, dt)
      end)

    %NBodyProblemSimulation.Simulation{simulation | bodies: new_bodies}
  end

  # Update one body using the Euler‑Cromer method.
  defp update_body(body, bodies, dt) do
    acceleration = compute_acceleration(body, bodies)
    new_vel = add_vectors(body.vel, scalar_mult(acceleration, dt))
    new_pos = add_vectors(body.pos, scalar_mult(new_vel, dt))
    Map.merge(body, %{vel: new_vel, pos: new_pos})
  end

  # Compute net gravitational acceleration on `body` from all other bodies.
  defp compute_acceleration(body, bodies) do
    bodies
    |> Enum.reject(&(&1.id == body.id))
    |> Enum.reduce({0.0, 0.0, 0.0}, fn other, {ax_total, ay_total, az_total} ->
      {dx, dy, dz} = subtract_vectors(other.pos, body.pos)
      distance = :math.sqrt(dx * dx + dy * dy + dz * dz)
      if distance == 0 do
        {ax_total, ay_total, az_total}
      else
        # Compute acceleration magnitude: G * m_other / r^2.
        accel = @g * other.mass / (distance * distance)
        ax = accel * dx / distance
        ay = accel * dy / distance
        az = accel * dz / distance
        {ax_total + ax, ay_total + ay, az_total + az}
      end
    end)
  end

  defp add_vectors({x1, y1, z1}, {x2, y2, z2}),
    do: {x1 + x2, y1 + y2, z1 + z2}

  defp subtract_vectors({x1, y1, z1}, {x2, y2, z2}),
    do: {x1 - x2, y1 - y2, z1 - z2}

  defp scalar_mult({x, y, z}, s),
    do: {x * s, y * s, z * s}
end
