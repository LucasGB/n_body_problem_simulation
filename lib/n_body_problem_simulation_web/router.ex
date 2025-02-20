defmodule NBodyProblemSimulationWeb.Router do
  use NBodyProblemSimulationWeb, :router

  import Phoenix.LiveView.Router
  
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {NBodyProblemSimulationWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NBodyProblemSimulationWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/create_simulation", PageController, :create_simulation

    live "/:simulation_id", SimulationLive, :index
  end

  if Application.compile_env(:n_body_problem_simulation, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NBodyProblemSimulationWeb.Telemetry
    end
  end
end
