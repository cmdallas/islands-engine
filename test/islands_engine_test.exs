defmodule IslandsEngineTest do
  use ExUnit.Case
  doctest IslandsEngine
  doctest IslandsEngine.Game
  doctest IslandsEngine.Island
  doctest IslandsEngine.Rules

  test "greets the world" do
    assert IslandsEngine.hello() == :world
  end
end
