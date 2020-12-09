defmodule IslandsEngine.Island do
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  def types(), do: [:atoll, :dot, :l_shape, :s_shape, :square]

  @doc """
  Builds an island given an island type and top left coordinate.

  ## Examples

    iex> IslandsEngine.Island.new(:unsupported_shape, %IslandsEngine.Coordinate{col: 6, row: 4})
    {:error, :invalid_island_type}

    iex> {:ok, island} = IslandsEngine.Island.new(:l_shape, %IslandsEngine.Coordinate{col: 6, row: 4})
    iex> island.coordinates
    #MapSet<[%IslandsEngine.Coordinate{col: 6, row: 4}, %IslandsEngine.Coordinate{col: 6, row: 5}, %IslandsEngine.Coordinate{col: 6, row: 6}, %IslandsEngine.Coordinate{col: 7, row: 6}]>
    iex> island.hit_coordinates
    #MapSet<[]>
  """
  def new(type, %Coordinate{} = upper_left) do
    with [_|_] = offsets <- offsets(type),
      %MapSet{} = coordinates <- add_coordinates(offsets, upper_left)
    do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      # Expects:
      # {:error, :invalid_coordinate}
      # {:error, :invalid_island_type}
      error -> error
    end
  end

  @doc """
  Determine whether islands overlap.

  ## Examples

    iex> alias IslandsEngine.{Coordinate, Island}
    iex> {:ok, square_coordinate} = Coordinate.new(1,1)
    iex> {:ok, square} = Island.new(:square, square_coordinate)
    iex> {:ok, dot_coordinate} = Coordinate.new(1,2)
    iex> {:ok, dot} = Island.new(:dot, dot_coordinate)
    iex> Island.overlaps?(square, dot)
    true
  """
  def overlaps?(existing_island, new_island), do:
    # Disjointed sets share no members
    not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)

  def forested?(island), do:
    MapSet.equal?(island.coordinates, island.hit_coordinates)

  def guess(island, coordinate) do
    case MapSet.member?(island.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
        {:hit, %{island | hit_coordinates: hit_coordinates}}
      false -> :miss
    end
  end

  #     0   1   2
  #   +-----------+
  #  0| X | X |   |
  #   +-----------+
  #  1| X | X |   |
  #   +-----------+
  #  2|   |   |   |
  #   +-----------+
  defp offsets(:square), do: [{0,0}, {0,1}, {1,0}, {1,1}]

  #     0   1   2
  #   +-----------+
  #  0| X | X |   |
  #   +-----------+
  #  1|   | X |   |
  #   +-----------+
  #  2| X | X |   |
  #   +-----------+
  defp offsets(:atoll), do: [{0,0}, {0,1}, {1,1}, {0,2}, {2,1}]

  #     0   1   2
  #   +-----------+
  #  0| X |   |   |
  #   +-----------+
  #  1|   |   |   |
  #   +-----------+
  #  2|   |   |   |
  #   +-----------+
  defp offsets(:dot), do: [{0,0}]

  #     0   1   2
  #   +-----------+
  #  0| X |   |   |
  #   +-----------+
  #  1| X |   |   |
  #   +-----------+
  #  2| X | X |   |
  #   +-----------+
  defp offsets(:l_shape), do: [{0,0}, {1,0}, {2,0}, {2,1}]

  #     0   1   2
  #   +-----------+
  #  0|   | X | X |
  #   +-----------+
  #  1| X | X  |  |
  #   +-----------+
  #  2|   |   |   |
  #   +-----------+
  defp offsets(:s_shape), do: [{0,1}, {0,2}, {1,0}, {1,1}]

  defp offsets(_), do: {:error, :invalid_island_type}

  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    # Each time a coordinate is built, validate it. Halt enumeration if a coordinate is invalid
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} ->
        {:cont, MapSet.put(coordinates, coordinate)}
      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end
end
