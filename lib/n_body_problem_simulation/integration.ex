defmodule NBodyProblemSimulation.Integration do
  @moduledoc """
  Behavior for N‑body integration strategies.
  """

  @callback update(simulation :: NBodyProblemSimulation.Simulation.t(), opts :: Keyword.t()) :: NBodyProblemSimulation.Simulation.t()
end
