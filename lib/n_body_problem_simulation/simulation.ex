defmodule NBodyProblemSimulation.Simulation do
  @moduledoc """
  An N‑body (extendable to more bodies) simulation in 3D using Euler‑Cromer integration.
  """
  alias NBodyProblemSimulation.GravityField
  alias NBodyProblemSimulation.Simulation
  #@g (4 * :math.pi() * :math.pi())/16  # Gravitational constant compatible with 1 Solar Mass + 1 AU
  @g 1
  
  @solar_mass 1.0
  @g_scale 0.5
  
  # Experimental parameters. Remove and set to function variables?
  @padding 3.0
  @grid_step 0.5
  defstruct bodies: [],
            grid: nil,
            time: 0.0

  @spec initial_state() :: %NBodyProblemSimulation.Simulation{
          bodies: [
            %{
              color: 255 | 11_184_810 | 16_752_762 | 16_776_960,
              id: 1 | 2 | 3 | 4,
              mass: float(),
              pos: {any(), any(), any()},
              radius: 1 | 3 | 4,
              vel: {any(), any(), any()}
            },
            ...
          ],
          grid: nil,
          time: float()
        }
  @doc """
  Returns the initial simulation state with N bodies.
  """
  def initial_state do
    %__MODULE__{
      bodies: initial_bodies()
    }
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
      grid_lines = create_lines_from_bounding_box(bodies)
      grid_points = Enum.flat_map(grid_lines, fn %{start: start_point, end: end_point} ->
        [start_point, end_point]
      end)
      warp_grid(grid_points, bodies)
    end
  end

  @doc """
  Creates a fresh grid based on the bounding box of the given bodies.
  Adjust `grid_step` to control resolution.
  """
  def create_lines_from_bounding_box(bodies) do
    {min_x, max_x, min_y, max_y, min_z, max_z} = bounding_box(bodies)

    lines =
      for x <- float_range(min_x, max_x, @grid_step),
          y <- float_range(min_y, max_y, @grid_step),
          z <- float_range(min_z, max_z, @grid_step),
          reduce: [] do
        acc ->
          new_lines =
            []
            |> (fn acc -> if x + @grid_step <= max_x, do: [%{start: [x, y, z], end: [x + @grid_step, y, z]} | acc], else: acc end).()
            |> (fn acc -> if y + @grid_step <= max_y, do: [%{start: [x, y, z], end: [x, y + @grid_step, z]} | acc], else: acc end).()
            |> (fn acc -> if z + @grid_step <= max_z, do: [%{start: [x, y, z], end: [x, y, z + @grid_step]} | acc], else: acc end).()

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
    min_y = Enum.min(ys) - @padding / 2
    max_y = Enum.max(ys) + @padding / 2
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

  defp initial_bodies do
    [
       #%{
       #  id: 10,
       #  mass: @solar_mass,        # 1 solar mass
       #  color: 0xf2f955,  # mostard yellow
       #  pos: {3.0, 4.0, 4.0},
       #  vel: {0.0, -1.0, 0.0},
       #  radius: 1
       #},
      # --- SUN ---
      %{
        id: 1,
        mass: @solar_mass,        # 1 solar mass
        color: 0xffff00,  # yellow
        pos: {0.0, 0.0, 0.0},
        vel: {0.0, 0.0, 0.0},
        radius: 1
      },
      # --- MERCURY ---
      %{
        id: 2,
        mass: 1.66e-7,    # ~3.30e23 kg => ~1.66e-7 solar masses
        color: 0xaaaaaa,  # gray-ish
        pos: {0.39, 0.0, 0.0},    # ~0.39 AU
        vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(0.39)},
        radius: 0.5
      },
      # --- VENUS ---
      %{
        id: 3,
        mass: 2.45e-6,   # ~4.87e24 kg => ~2.45e-6 solar masses
        color: 0xffa07a, # light salmon
        pos: {0.723, 0.0, 0.0},
        vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(0.723)},
        radius: 0.5
      },
      # # --- EARTH ---
      %{
        id: 4,
        mass: 3.0e-6,    # ~5.97e24 kg => ~3.0e-6 solar masses
        color: 0x0000ff, # blue
        pos: {1.0, 0.0, 0.0}, # 1 AU on X-axis
        vel: {0.0, 0.0, 2.0 * :math.pi}, # ~6.283 AU/year
        radius: 0.5
      },
      # # --- MARS ---
      # %{
      #   id: 5,
      #   mass: 3.22e-7,   # ~6.42e23 kg => ~3.22e-7 solar masses
      #   color: 0xff4500, # orange-red
      #   pos: {-1.524, 0.0, 0.0},
      #   vel: {0.0, 0.0, -2.0 * :math.pi / :math.sqrt(1.524)},
      #   radius: 2
      # },
      # # --- JUPITER ---
      # %{
      #   id: 6,
      #   mass: 9.54e-4,   # ~1.90e27 kg => ~9.54e-4 solar masses
      #   color: 0xffa500, # orange
      #   pos: {5.2, 0.0, 0.0},
      #   vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(5.2)},
      #   radius: 12
      # },
      # # --- SATURN ---
      # %{
      #   id: 7,
      #   mass: 2.86e-4,   # ~5.68e26 kg => ~2.86e-4 solar masses
      #   color: 0xffff99, # pale yellow
      #   pos: {9.58, 0.0, 0.0},
      #   vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(9.58)},
      #   radius: 10
      # },
      # # --- URANUS ---
      # %{
      #   id: 8,
      #   mass: 4.36e-5,   # ~8.68e25 kg => ~4.36e-5 solar masses
      #   color: 0x40e0d0, # turquoise
      #   pos: {19.2, 0.0, 0.0},
      #   vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(19.2)},
      #   radius: 7
      # },
      # # --- NEPTUNE ---
      # %{
      #   id: 9,
      #   mass: 5.1e-5,    # ~1.02e26 kg => ~5.1e-5 solar masses
      #   color: 0x0000ff, # darker blue
      #   pos: {-30.05, 0.0, 0.0},
      #   vel: {0.0, 0.0, -2.0 * :math.pi / :math.sqrt(30.05)},
      #   radius: 7
      # }
    ]
  end
end
