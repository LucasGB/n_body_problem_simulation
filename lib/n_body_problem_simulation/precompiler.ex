defmodule NBodyProblemSimulation.Precompiler do
  require Logger
  alias NBodyProblemSimulation.Integration.EulerCromer
  alias NBodyProblemSimulation.Integration.VelocityVerlet

  def precompile_integration do
    Logger.info("Precompiling GPU integration functions...")

    dummy_tensor = Nx.tensor([[1.0]])
    dummy_mass = Nx.tensor([1.0])
    dt = 0.001
    dummy_g_scale = 1

    _ = EulerCromer.euler_cromer_step(dummy_tensor, dummy_tensor, dummy_mass, dt, dummy_g_scale)
    _ = VelocityVerlet.velocity_verlet_step(dummy_tensor, dummy_tensor, dummy_mass, dt, dummy_g_scale)

    Logger.info("Precompilation complete.")
  end
end
