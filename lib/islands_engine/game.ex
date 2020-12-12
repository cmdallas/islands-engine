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

  alias IslandsEngine.{Board, Guesses, Rules}

  use GenServer

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

end
