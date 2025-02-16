defmodule NBodyProblemSimulation.Geometry do
  @moduledoc """
  Provides helper functions for 3D vector math and geometry calculations.
  """

  @doc "Adds two 3D vectors."
  @spec add({number(), number(), number()}, {number(), number(), number()}) ::
          {number(), number(), number()}
  def add({x1, y1, z1}, {x2, y2, z2}), do: {x1 + x2, y1 + y2, z1 + z2}

  @doc "Subtracts the second 3D vector from the first."
  @spec subtract({number(), number(), number()}, {number(), number(), number()}) ::
          {number(), number(), number()}
  def subtract({x1, y1, z1}, {x2, y2, z2}), do: {x1 - x2, y1 - y2, z1 - z2}

  @doc "Multiplies a 3D vector by a scalar."
  @spec scale({number(), number(), number()}, number()) :: {number(), number(), number()}
  def scale({x, y, z}, s), do: {x * s, y * s, z * s}

  @doc "Returns the Euclidean magnitude of a 3D vector."
  @spec magnitude({number(), number(), number()}) :: number()
  def magnitude({x, y, z}), do: :math.sqrt(x * x + y * y + z * z)

  @spec bounding_box(list()) :: {number(), number(), number(), number(), number(), number()}
  @doc """
  Computes the bounding box for a list of points or bodies.
  
  If given bodies, each element should be a map with a `:pos` key.
  Returns `{min_x, max_x, min_y, max_y, min_z, max_z}`.
  """
  @spec bounding_box(list(), number()) :: {number(), number(), number(), number(), number(), number()}
  def bounding_box(bodies, padding \\ 0.0) when is_list(bodies) do
    points =
      case bodies do
        [%{pos: pos} | _] -> Enum.map(bodies, fn %{pos: pos} -> pos end)
        _ -> bodies
      end

    xs = Enum.map(points, fn {x, _y, _z} -> x end)
    ys = Enum.map(points, fn {_x, y, _z} -> y end)
    zs = Enum.map(points, fn {_x, _y, z} -> z end)
    {Enum.min(xs) - padding, Enum.max(xs) + padding,
     Enum.min(ys) - padding, Enum.max(ys) + padding,
     Enum.min(zs) - padding, Enum.max(zs) + padding}
  end

  @doc """
  Generates a float range from start to stop (inclusive-ish) with the given step.
  
  Example usage:
     float_range(-10.0, 10.0, 1.0) -> -10.0, -9.0, -8.0, ..., 10.0
  """
  @spec float_range(number(), number(), number()) :: Enumerable.t()
  def float_range(start, stop, step) when start <= stop do
    Stream.unfold(start, fn current ->
      if current > stop do
        nil
      else
        {current, current + step}
      end
    end)
  end
  def float_range(_start, _stop, _step), do: []

  @doc """
  Creates grid points from the bounding box of a set of bodies.
  
  Generates points for grid lines in each axis direction based on the number of segments
  and an optional padding. (You can later add caching here if needed.)
  """
  @spec create_grid_points(list(), pos_integer(), number()) :: [tuple()]
  def create_grid_points(bodies, segments_per_axis, padding \\ 1.0) do
    {min_x, max_x, min_y, max_y, min_z, max_z} = bounding_box(bodies, padding)
    grid_step_x = (abs(max_x) + abs(min_x)) / segments_per_axis
    grid_step_y = (abs(max_y) + abs(min_y)) / segments_per_axis
    grid_step_z = (abs(max_z) + abs(min_z)) / segments_per_axis

    for x <- float_range(min_x, max_x, grid_step_x),
        y <- float_range(min_y, max_y, grid_step_y),
        z <- float_range(min_z, max_z, grid_step_z) do
      # For each (x,y,z) we can produce grid points along the x, y and z directions,
      # if they lie within bounds.
      []
      |> maybe_add({x, y, z}, {x + grid_step_x, y, z}, max_x, :x)
      |> maybe_add({x, y, z}, {x, y + grid_step_y, z}, max_y, :y)
      |> maybe_add({x, y, z}, {x, y, z + grid_step_z}, max_z, :z)
    end
    |> List.flatten()
  end

  defp maybe_add(acc, p1, p2, max_value, axis) do
    cond do
      axis == :x and elem(p2, 0) <= max_value -> [p1, p2 | acc]
      axis == :y and elem(p2, 1) <= max_value -> [p1, p2 | acc]
      axis == :z and elem(p2, 2) <= max_value -> [p1, p2 | acc]
      true -> acc
    end
  end
end
