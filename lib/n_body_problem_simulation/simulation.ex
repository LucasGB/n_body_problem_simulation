defmodule NBodyProblemSimulation.Simulation do
  @moduledoc """
  An N‑body (extendable to more bodies) simulation in 3D using Euler‑Cromer integration.
  """
  alias NBodyProblemSimulation.GravityField
  alias NBodyProblemSimulation.Simulation
  alias NBodyProblemSimulation.InitialState
  #@g (4 * :math.pi() * :math.pi())  # Gravitational constant compatible with 1 Solar Mass + 1 AU
  @g 6.67430*10.0e-11
  
  @solar_mass 1.0
  @solar_radii 20.0
  
  # Experimental parameters. Remove and set to function variables?
  @padding 1.0
  @grid_segments_per_axis 4
  defstruct bodies: [],
            grid: nil,
            time: 0.0

  @doc """
  Returns the initial simulation state with N bodies.
  """
  def initial_state do
      InitialState.initial_state()
  end

  @doc """
  Updates the simulation state by a time step dt using the given integration strategy that implements the NBodyProblemSimulation.Integration behavior.
  """
  def update(%Simulation{} = simulation, dt: dt, strategy: integration_module) do
    updated_bodies = integration_module.update(simulation, dt: dt)

    updated_grid = compute_grid_warp(simulation.grid, updated_bodies.bodies)

    %Simulation{simulation | bodies: updated_bodies.bodies, grid: updated_grid, time: simulation.time + dt}
  end

  defp compute_grid_warp(nil, bodies) do
    grid_lines = create_lines_from_bounding_box(bodies)
    grid_points = Enum.flat_map(grid_lines, fn %{start: start_point, end: end_point} ->
      [start_point, end_point]
    end)
    warp_grid(grid_points, bodies)
  end

  defp compute_grid_warp(existing_grid, bodies) do
    if out_of_bounds?(bodies, existing_grid) do
      grid_lines = create_lines_from_bounding_box(bodies)
      grid_points = Enum.flat_map(grid_lines, fn %{start: start_point, end: end_point} ->
        [start_point, end_point]
      end)
      warp_grid(grid_points, bodies)
    else
      p = existing_grid
        |> Enum.map(&Tuple.to_list/1)
      warp_grid(p, bodies)
    end
  end

  @doc """
  Creates a fresh grid based on the bounding box of the given bodies.
  Adjust `grid_step` to control resolution.
  """
  def create_lines_from_bounding_box(bodies) do
    {min_x, max_x, min_y, max_y, min_z, max_z} = bounding_box(bodies)
    grid_step_x = (abs(max_x) + abs(min_x)) / @grid_segments_per_axis 
    grid_step_y = (abs(max_y) + abs(min_y)) / @grid_segments_per_axis 
    grid_step_z = (abs(max_z) + abs(min_z)) / @grid_segments_per_axis 

    lines =
      for x <- float_range(min_x, max_x, grid_step_x),
          y <- float_range(min_y, max_y, grid_step_y),
          z <- float_range(min_z, max_z, grid_step_z),
          reduce: [] do
        acc ->
          new_lines =
            []
            |> (fn acc -> if x + grid_step_x <= max_x, do: [%{start: [x, y, z], end: [x + grid_step_x, y, z]} | acc], else: acc end).()
            |> (fn acc -> if y + grid_step_y <= max_y, do: [%{start: [x, y, z], end: [x, y + grid_step_y, z]} | acc], else: acc end).()
            |> (fn acc -> if z + grid_step_z <= max_z, do: [%{start: [x, y, z], end: [x, y, z + grid_step_z]} | acc], else: acc end).()

            updated_acc = acc ++ new_lines
            updated_acc
      end
    lines
  end


  @doc """
  Warps the list of grid points by applying `GravityField.warp_point/3` in parallel.
  Returns the new list of warped points.
  """
  defp warp_grid(grid_points, bodies) do
    grid_points
    |> Task.async_stream(fn [x, y, z] ->
      GravityField.warp_point({x, y, z}, bodies, @g)
    end)
    |> Enum.map(fn
      {:ok, warped_point} -> warped_point
      {:error, reason} ->
        raise "Warp failed: #{inspect(reason)}"
    end)
  end

  @doc """
  Determines if any body's position lies outside the bounding box
  of the existing grid. If so, return true, meaning we should expand the grid.
  """
  defp out_of_bounds?(bodies, grid_points) do
    {gmin_x, gmax_x, gmin_y, gmax_y, gmin_z, gmax_z} = bounding_box_of_grid(grid_points)

    Enum.any?(bodies, fn body ->
      {bx, by, bz} = body.pos
      bx < gmin_x or bx > gmax_x or
      by < gmin_y or by > gmax_y or
      bz < gmin_z or bz > gmax_z
    end)
  end

  @doc """
  Returns {min_x, max_x, min_y, max_y, min_z, max_z} for the given list of bodies.
  Adjust if you want padding around the edges.
  """
  defp bounding_box(bodies) do
    
    xs = Enum.map(bodies, fn b -> elem(b.pos, 0) end)
    ys = Enum.map(bodies, fn b -> elem(b.pos, 1) end)
    zs = Enum.map(bodies, fn b -> elem(b.pos, 2) end)

    min_x = Enum.min(xs) - @padding
    max_x = Enum.max(xs) + @padding 
    min_y = Enum.min(ys) - @padding
    max_y = Enum.max(ys) + @padding
    min_z = Enum.min(zs) - @padding
    max_z = Enum.max(zs) + @padding

    {min_x, max_x, min_y, max_y, min_z, max_z}
  end

  @doc """
  Computes the bounding box of an existing grid list (each grid point is {x,y,z}).
  """
  defp bounding_box_of_grid(grid_points) do
    xs = Enum.map(grid_points, fn {x, _, _} -> x end)
    ys = Enum.map(grid_points, fn {_, y, _} -> y end)
    zs = Enum.map(grid_points, fn {_, _, z} -> z end)

    {Enum.min(xs), Enum.max(xs),
     Enum.min(ys), Enum.max(ys),
     Enum.min(zs), Enum.max(zs)}
  end

  @doc """
  Generates a float range [start..stop] (inclusive-ish) with the given step.
  Example usage:
     float_range(-10.0, 10.0, 1.0) -> -10.0, -9.0, -8.0, ..., 10.0
  """
  defp float_range(start, stop, step) when start <= stop do
    Stream.unfold(start, fn current ->
      if current > stop do
        nil
      else
        {current, current + step}
      end
    end)
  end
  defp float_range(_start, _stop, _step), do: []

end
