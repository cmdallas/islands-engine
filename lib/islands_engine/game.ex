defmodule IslandsEngine.Game do
  @moduledoc """

    ## The GenServer Pattern

    There are 3 moving parts:
      - A client function
      - A function from the genserver module
      - A callback

    The client function is the public interface. Within
    the client function, the genserver module function
    gets called. The callback is where the real work
    is performed and a response is returned.

    A client function wraps a GenServer module function
    which triggers a callback.

    +---------+   +-------+   +-------+
    |Other    +-->+ Game  +-->+ Gen   +---+
    |Process  |   |       |   |Server |   |
    +---------+   +-------+   +-----+-+   |
                                    ^     |
                                    +-----+
  """

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

  use GenServer

  @players [:player1, :player2]

  @doc """
    iex> alias IslandsEngine.Game
    iex> {:ok, game} = Game.start_link("Chris")
    iex> state = :sys.get_state(game)
    iex> state.player1.name
    "Chris"
  """
  def init(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  end

  def handle_info(:first, state), do: {:noreply, state}

  def start_link(name) when is_binary(name), do:
    GenServer.start_link(__MODULE__, name, [])

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      state
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
    end
  end

  @doc """
    Check the following conditions:

      - rules permit players to position their islands
      - row and col values agenerate valid coords
      - island key and upper left coord generate a valid island
      - positioning the island doesn't generate an error

    ## Examples

      iex> alias IslandsEngine.{Game, Rules}
      iex> {:ok, game} = Game.start_link("Chris")
      iex> Game.add_player(game, "Alexis")
      iex> state = :sys.get_state(game)
      iex> state.rules.state
      :players_set
      iex> Game.position_island(game, :player1, :square, 1, 1)
      iex> Game.position_island(game, :player1, :dot, 12, 1)
      {:error, :invalid_coordinate}
  """
  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
         %{} = board <- Board.position_island(board, key, island)
    do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> {:reply, :error, state}
      {:error, :invalid_coordinate} -> {:reply, {:error, :invalid_coordinate}, state}
      {:error, :invalid_island_type} -> {:reply, {:error, :invalid_island_type}, state}
    end
  end

  @doc """
    iex> alias IslandsEngine.{Game, Rules}
    iex> {:ok, game} = Game.start_link("Chris")
    iex> Game.add_player(game, "Alexis")
    iex> Game.set_islands(game, :player1)
    {:error, :not_all_islands_positioned}
    iex> Game.position_island(game, :player1, :atoll, 1, 1)
    iex> Game.position_island(game, :player1, :dot, 1, 4)
    iex> Game.position_island(game, :player1, :l_shape, 1, 5)
    iex> Game.position_island(game, :player1, :s_shape, 5, 1)
    iex> Game.position_island(game, :player1, :square, 5, 5)
    :ok
    iex> Game.set_islands(game, :player1)
    iex> state = :sys.get_state(game)
    iex> state.rules.player1
    :islands_set
    iex> state.rules.state
    :players_set
  """
  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board)
    do
      state
      |> update_rules(rules)
      |> reply_success({:ok, board})
    else
      :error -> {:reply, :error, state}
      false -> {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end

  @doc """
    iex> alias IslandsEngine.Game
    iex> {:ok, game} = Game.start_link("Chris")
    iex> Game.add_player(game, "Alexis")
    iex> state = :sys.get_state(game)
    iex> state.player2.name
    "Alexis"
  """
  def add_player(game, name) when is_binary(name), do:
    GenServer.call(game, {:add_player, name})

  def position_island(game, player, key, row, col) when player in @players, do:
    GenServer.call(game, {:position_island, player, key, row, col})

  def set_islands(game, player) when player in @players, do:
    GenServer.call(game, {:set_islands, player})

  defp reply_success(state, reply), do: {:reply, reply, state}

  defp player_board(state, player), do: Map.get(state, player).board

  defp update_rules(state, rules), do: %{state | rules: rules}

  defp update_player2_name(state, name), do: put_in(state.player2.name, name)

  defp update_board(state, player, board), do:
    Map.update!(state, player, fn player -> %{player | board: board} end)

end
