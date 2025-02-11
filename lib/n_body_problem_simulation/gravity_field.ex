defmodule NBodyProblemSimulation.GravityField do
  def warp_point({x, y, z}, bodies, k) do
    Enum.reduce(bodies, {x, y, z}, fn body, acc ->
      apply_body_gravity(acc, body, k)
    end)
  end
  
  def warp_point(point, bodies, g_scale) do
    Enum.reduce(bodies, point, fn body, acc ->
      apply_body_gravity(acc, body, g_scale)
    end)
  end

  defp apply_body_gravity({x, y, z}, %{pos: {bx, by, bz}, mass: m}, g_scale) do
    dx = bx - x
    dy = by - y
    dz = bz - z
    dist_sqr = dx*dx + dy*dy + dz*dz
    dist = :math.sqrt(dist_sqr)
    if dist < 1.0e-6 do
      {x, y, z}
    else
      # Inverse-square
      force = g_scale * m / (dist_sqr * dist) # (1 / r^3)
      {
        x + dx * force,
        y + dy * force,
        z + dz * force
      }
    end
  end
end
