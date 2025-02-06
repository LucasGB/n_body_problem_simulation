defmodule NBodyProblemSimulation.Integration do
  @moduledoc """
  Behavior for N‑body integration strategies.
  """

  @callback update(simulation :: any(), dt: number()) :: any()
end
