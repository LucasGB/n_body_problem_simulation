defmodule NBodyProblemSimulation.Simulation do
  @moduledoc """
  A simple two‑body (extendable to more bodies) simulation in 3D using Euler‑Cromer integration.
  """

  @g 1.0  # Gravitational constant (set to 1 for simplicity)

  defstruct bodies: []

  @doc """
  Returns the initial simulation state with two bodies.
  """
  def initial_state do
    %NBodyProblemSimulation.Simulation{
      bodies: [
        %{
          id: 1,
          mass: 10.0,
          # Centered in a 3D volume (we’ll later adjust coordinates for rendering)
          pos: {250.0, 250.0, 250.0},
          vel: {0.0, 0.0, 0.0}
        },
        %{
          id: 2,
          mass: 1.0,
          # Start offset in 3D space
          pos: {250.0, 100.0, 250.0},
          # Initial velocity given a tangential component (feel free to tweak)
          vel: {1.5, 0.0, 0.5}
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

  # Helper: vector addition for 3D vectors.
  defp add_vectors({x1, y1, z1}, {x2, y2, z2}),
    do: {x1 + x2, y1 + y2, z1 + z2}

  # Helper: vector subtraction for 3D vectors.
  defp subtract_vectors({x1, y1, z1}, {x2, y2, z2}),
    do: {x1 - x2, y1 - y2, z1 - z2}

  # Helper: multiply a 3D vector by a scalar.
  defp scalar_mult({x, y, z}, s),
    do: {x * s, y * s, z * s}
end
