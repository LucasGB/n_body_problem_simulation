defmodule NBodyProblemSimulation.GravityField do
  @moduledoc """
  Provides functions to warp points by applying gravitational effects.
  """
  alias NBodyProblemSimulation.Geometry
  
  @doc """
  Warps a point by applying the gravitational influence of all bodies.
  """
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

  defp apply_body_gravity(point, %{pos: pos, mass: m}, g_scale) do
    delta = Geometry.subtract(pos, point)
    dist = Geometry.magnitude(delta)
    if dist < 1.0e-6 do
      point
    else
      force = g_scale * m / (dist * dist * dist)
      Geometry.add(point, Geometry.scale(delta, force))
    end
  end
end
