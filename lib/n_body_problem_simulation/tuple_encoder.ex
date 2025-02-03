defimpl Jason.Encoder, for: Tuple do
  def encode(tuple, opts) do
    tuple
    |> Tuple.to_list()
    |> Jason.Encoder.List.encode(opts)
  end
end
