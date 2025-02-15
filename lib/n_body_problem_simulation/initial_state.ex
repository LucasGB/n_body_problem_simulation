defmodule NBodyProblemSimulation.InitialState do
  @moduledoc """
  Loads the initial simulation state from a JSON file.
  """

  @json_file Path.join(:code.priv_dir(:n_body_problem_simulation), "4_bodies.json")

  def initial_state do
    case File.read(@json_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"bodies" => bodies} = data} ->
            time = Map.get(data, "time", 0.0)
            %NBodyProblemSimulation.Simulation {
              bodies: convert_bodies(bodies),
              grid: nil,
              time: time
            }

          {:error, reason} ->
            raise "Failed to parse JSON: #{inspect(reason)}"
        end

      {:error, reason} ->
        raise "Failed to read initial state file: #{inspect(reason)}"
    end
  end

  defp convert_bodies(bodies) do
    Enum.map(bodies, fn body ->
      body
        |> convert_keys_to_atoms()
        |> Map.update!(:pos, &convert_to_tuple/1)
        |> Map.update!(:vel, &convert_to_tuple/1)
        |> Map.update!(:color, &convert_hex_to_int/1)
    end)
  end

  defp convert_keys_to_atoms(map) do
    for {key, value} <- map, into: %{} do
      {String.to_atom(key), value}
    end
  end

  defp convert_to_tuple([x, y, z]), do: {x, y, z}

  defp convert_hex_to_int("#" <> hex) do
    {int, _} = Integer.parse(hex, 16)
    int
  end
end
