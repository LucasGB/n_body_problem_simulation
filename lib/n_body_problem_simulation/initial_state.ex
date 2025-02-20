defmodule NBodyProblemSimulation.InitialState do
  @moduledoc """
  Loads the initial simulation state from a preset of JSON files.
  """

  @states_dir Path.join(:code.priv_dir(:n_body_problem_simulation), "")
  @json_file Application.app_dir(:n_body_problem_simulation, "priv/4_bodies.json")

  
  @doc """
  Returns the initial simulation state.
  """
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

  @doc """
  Returns a list of available state names based on JSON files in `priv/`.
  """
  def list_states do
    @states_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))
    |> Enum.map(&String.replace_suffix(&1, ".json", ""))
  end

  @doc """
  Loads the simulation state from the specified file in `priv/`.
  """
  def load_state(state_name) do
    file_path = Path.join(@states_dir, "#{state_name}.json")

    case File.read(file_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, %{"bodies" => bodies} = data} ->
            time = Map.get(data, "time", 0.0)
            %NBodyProblemSimulation.Simulation{
              bodies: convert_bodies(bodies),
              grid: nil,
              time: time
            }

          {:error, reason} -> raise "Failed to parse JSON: #{inspect(reason)}"
        end

      {:error, reason} -> raise "Failed to read state file #{state_name}: #{inspect(reason)}"
    end
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
