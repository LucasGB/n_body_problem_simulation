defmodule NBodyProblemSimulation.Grid do
  @moduledoc """
  Provides helper functions to compute and warp the simulation grid.
  """

  alias NBodyProblemSimulation.Geometry
  alias NBodyProblemSimulation.GravityField

  @doc """
  Computes the warped grid based on the surrounding bodies.

  If an existing grid is provided and bodies are within bounds, it will reuse it;
  otherwise, it generates a new grid based on the bodies’ bounding box.
  """
  @spec compute_grid(any(), list(), pos_integer(), number(), number()) :: list()
  def compute_grid(nil, bodies, segments, padding, g) do
    bodies
    |> Geometry.create_grid_points(segments, padding)
    |> warp_grid(bodies, g)
  end

  def compute_grid(existing_grid, bodies, segments, padding, g) do
    if out_of_bounds?(bodies, existing_grid) do
      bodies
      |> Geometry.create_grid_points(segments, padding)
      |> warp_grid(bodies, g)
    else
      warp_grid(existing_grid, bodies, g)
    end
  end

  @doc """
  Warps each grid point by applying the gravitational field from the bodies.
  """
  @spec warp_grid(list(), list(), number()) :: list()
  def warp_grid(grid_points, bodies, g) do
    grid_points
    |> Task.async_stream(fn point ->
         GravityField.warp_point(point, bodies, g)
       end)
    |> Enum.map(fn
         {:ok, warped_point} -> warped_point
         {:error, reason} -> raise "Warp failed: #{inspect(reason)}"
       end)
  end

  @doc """
  Checks if any body's position lies outside the bounding box of the grid points.
  """
  @spec out_of_bounds?(list(), list()) :: boolean()
  def out_of_bounds?(bodies, grid_points) do
    {min_x, max_x, min_y, max_y, min_z, max_z} = Geometry.bounding_box(grid_points)
    Enum.any?(bodies, fn body ->
      {bx, by, bz} = body.pos
      bx < min_x or bx > max_x or
      by < min_y or by > max_y or
      bz < min_z or bz > max_z
    end)
  end
end
