defmodule NBodyProblemSimulation.NxUtils do
  @moduledoc """
  Shared helper functions for Nx-based integration methods.
  """

  require Nx.Defn

  @epsilon 1.0e-6

  @doc """
  Computes gravitational accelerations for all bodies.

  - `positions`: an {N, 3} tensor.
  - `masses`: an {N} tensor.
  - `g`: gravitational constant.

  Returns an {N, 3} tensor representing net acceleration on each body.
  """
  Nx.Defn.defn compute_accelerations(positions, masses, g) do
    pos1 = Nx.new_axis(positions, 1)        # shape: {N, 1, 3}
    pos2 = Nx.new_axis(positions, 0)        # shape: {1, N, 3}
    delta = Nx.subtract(pos2, pos1)         # shape: {N, N, 3}

    dist_sqr = Nx.sum(Nx.pow(delta, 2), axes: [2]) + @epsilon
    distances = Nx.sqrt(dist_sqr)
    mask = distances
           |> Nx.not_equal(0.0)
           |> Nx.as_type(:f32)

    masses_matrix = Nx.new_axis(masses, 0)    # shape: {1, N}
    accel_mag =
      g
      |> Nx.multiply(masses_matrix)
      |> Nx.divide(Nx.multiply(dist_sqr, distances))
      |> Nx.multiply(mask)

    # Expand scalar acceleration for broadcasting.
    accel_vectors = Nx.multiply(delta, Nx.new_axis(accel_mag, -1))
    Nx.sum(accel_vectors, axes: [1])
  end

  @spec extract_tensors(any()) :: {any(), any(), any()}
  @doc """
  Extracts positions, velocities, and masses from a list of bodies.

  Assumes each body is a map with keys `:pos`, `:vel`, and `:mass`.
  Returns a tuple of Nx tensors: `{positions, velocities, masses}`.
  """
  def extract_tensors(bodies) do
    positions =
      bodies
      |> Enum.map(fn body ->
        body.pos |> Tuple.to_list() |> Nx.tensor(type: {:f, 32})
      end)
      |> Nx.stack()

    velocities =
      bodies
      |> Enum.map(fn body ->
        body.vel |> Tuple.to_list() |> Nx.tensor(type: {:f, 32})
      end)
      |> Nx.stack()

    masses =
      bodies
      |> Enum.map(fn body ->
        body.mass |> Nx.tensor(type: {:f, 32})
      end)
      |> Nx.stack()

    {positions, velocities, masses}
  end

  @doc """
  Updates the list of bodies with new positions and velocities.

  Assumes that `new_positions` and `new_velocities` are Nx tensors of shape {N, 3}.
  Returns an updated list of bodies with positions and velocities converted back to tuples.
  """
  def update_bodies(bodies, new_positions, new_velocities) do
    pos_list = Nx.to_flat_list(new_positions)
    vel_list = Nx.to_flat_list(new_velocities)
    
    # Chunk into lists of 3 values (for 3D coordinates).
    pos_chunks = Enum.chunk_every(pos_list, 3)
    vel_chunks = Enum.chunk_every(vel_list, 3)

    Enum.zip([bodies, pos_chunks, vel_chunks])
    |> Enum.map(fn {body, pos, vel} ->
      Map.merge(body, %{pos: List.to_tuple(pos), vel: List.to_tuple(vel)})
    end)
  end
end
