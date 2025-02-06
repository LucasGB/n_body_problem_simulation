defmodule NBodyProblemSimulation.Math do
  @moduledoc """
  Provides helper functions for vector math and acceleration computation.
  """

  @g 4 * :math.pi() * :math.pi()

  def compute_acceleration(body, bodies) do
    bodies
    |> Enum.reject(&(&1.id == body.id))
    |> Enum.reduce({0.0, 0.0, 0.0}, fn other, {ax_total, ay_total, az_total} ->
      {dx, dy, dz} = subtract_vectors(other.pos, body.pos)
      distance = :math.sqrt(dx * dx + dy * dy + dz * dz)
      if distance == 0 do
        {ax_total, ay_total, az_total}
      else
        accel = @g * other.mass / (distance * distance)
        ax = accel * dx / distance
        ay = accel * dy / distance
        az = accel * dz / distance
        {ax_total + ax, ay_total + ay, az_total + az}
      end
    end)
  end

  def add_vectors({x1, y1, z1}, {x2, y2, z2}),
    do: {x1 + x2, y1 + y2, z1 + z2}

  def subtract_vectors({x1, y1, z1}, {x2, y2, z2}),
    do: {x1 - x2, y1 - y2, z1 - z2}

  def scalar_mult({x, y, z}, s),
    do: {x * s, y * s, z * s}
end
