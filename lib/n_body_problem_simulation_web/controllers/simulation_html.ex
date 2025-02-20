defmodule NBodyProblemSimulationWeb.SimulationHTML do
  use NBodyProblemSimulationWeb, :html

  embed_templates "simulation_html/*"

  def show(assigns) do
    ~H"""
    <h1>Simulation: <%= @simulation_id %></h1>

    <%= if @simulation_running do %>
      <p>Simulation is running.</p>
      <form action={~p"/#{@simulation_id}/stop"} method="post">
        <button type="submit">Stop Simulation</button>
      </form>
    <% else %>
      <p>No simulation is running.</p>
      <form action={~p"/#{@simulation_id}/start"} method="post">
        <select name="integration_method">
          <option value="euler-cromer">Euler-Cromer</option>
          <option value="velocity-verlet">Velocity Verlet</option>
        </select>
        <select name="initial_state">
          <%= for state <- @available_states do %>
            <option value={state}><%= state %></option>
          <% end %>
        </select>
        <button type="submit">Start Simulation</button>
      </form>
    <% end %>
    """
  end
end
