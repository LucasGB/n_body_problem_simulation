defmodule NBodyProblemSimulation.Simulation do
  @moduledoc """
  A simple N‑body (extendable to more bodies) simulation in 3D using Euler‑Cromer integration.
  """

  @g 4 * :math.pi() * :math.pi()  # Gravitational constant compatible with 1 Solar Mass + 1 AU
  @solar_mass 1.0

  defstruct bodies: []

  @doc """
  Returns the initial simulation state with N bodies.
  """
  def initial_state do
    %__MODULE__{
      bodies: [
        # --- SUN ---
        %{
          id: 1,
          mass: @solar_mass,        # 1 solar mass
          color: 0xffff00,  # yellow
          pos: {0.0, 0.0, 0.0},
          vel: {0.0, 0.0, 0.0},
          radius: 20
        },
        # --- MERCURY ---
        %{
          id: 2,
          mass: 1.66e-7,    # ~3.30e23 kg => ~1.66e-7 solar masses
          color: 0xaaaaaa,  # gray-ish
          pos: {0.39, 0.0, 0.0},    # ~0.39 AU
          # v = 2*pi/sqrt(r) for circular orbit in these units
          vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(0.39)},
          radius: 1
        },
        # --- VENUS ---
        %{
          id: 3,
          mass: 2.45e-6,   # ~4.87e24 kg => ~2.45e-6 solar masses
          color: 0xffa07a, # light salmon
          pos: {0.723, 0.0, 0.0},
          vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(0.723)},
          radius: 3
        },
        # --- EARTH ---
        %{
          id: 4,
          mass: 3.0e-6,    # ~5.97e24 kg => ~3.0e-6 solar masses
          color: 0x0000ff, # blue
          pos: {1.0, 0.0, 0.0}, # 1 AU on X-axis
          vel: {0.0, 0.0, 2.0 * :math.pi}, # ~6.283 AU/year
          radius: 4
        },
        # --- MARS ---
        %{
          id: 5,
          mass: 3.22e-7,   # ~6.42e23 kg => ~3.22e-7 solar masses
          color: 0xff4500, # orange-red
          pos: {-1.524, 0.0, 0.0},
          vel: {0.0, 0.0, -2.0 * :math.pi / :math.sqrt(1.524)},
          radius: 2
        },
        # --- JUPITER ---
        %{
          id: 6,
          mass: 9.54e-4,   # ~1.90e27 kg => ~9.54e-4 solar masses
          color: 0xffa500, # orange
          pos: {5.2, 0.0, 0.0},
          vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(5.2)},
          radius: 12
        },
        # --- SATURN ---
        %{
          id: 7,
          mass: 2.86e-4,   # ~5.68e26 kg => ~2.86e-4 solar masses
          color: 0xffff99, # pale yellow
          pos: {9.58, 0.0, 0.0},
          vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(9.58)},
          radius: 10
        },
        # --- URANUS ---
        %{
          id: 8,
          mass: 4.36e-5,   # ~8.68e25 kg => ~4.36e-5 solar masses
          color: 0x40e0d0, # turquoise
          pos: {19.2, 0.0, 0.0},
          vel: {0.0, 0.0, 2.0 * :math.pi / :math.sqrt(19.2)},
          radius: 7
        },
        # --- NEPTUNE ---
        %{
          id: 9,
          mass: 5.1e-5,    # ~1.02e26 kg => ~5.1e-5 solar masses
          color: 0x0000ff, # darker blue
          pos: {-30.05, 0.0, 0.0},
          vel: {0.0, 0.0, -2.0 * :math.pi / :math.sqrt(30.05)},
          radius: 7
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
