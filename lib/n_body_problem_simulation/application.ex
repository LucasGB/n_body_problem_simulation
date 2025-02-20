defmodule NBodyProblemSimulation.Application do

  use Application

  @impl true
  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      NBodyProblemSimulationWeb.Telemetry,
      {Registry, keys: :unique, name: NBodyProblemSimulation.SimulationRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: NBodyProblemSimulation.SimulationSupervisor},
      {Phoenix.PubSub, name: NBodyProblemSimulation.PubSub},
      NBodyProblemSimulationWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: NBodyProblemSimulation.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    NBodyProblemSimulationWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
