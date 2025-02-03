defmodule NBodyProblemSimulation.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  @spec start(any(), any()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      NBodyProblemSimulationWeb.Telemetry,
      # NBodyProblemSimulation.Repo,
      # {DNSCluster, query: Application.get_env(:n_body_problem_simulation, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: NBodyProblemSimulation.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: NBodyProblemSimulation.Finch},
      # Start a worker by calling: NBodyProblemSimulation.Worker.start_link(arg)
      # {NBodyProblemSimulation.Worker, arg},
      # Start to serve requests, typically the last entry
      NBodyProblemSimulationWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NBodyProblemSimulation.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NBodyProblemSimulationWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
