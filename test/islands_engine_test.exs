defmodule IslandsEngineTest do
  use ExUnit.Case
  doctest IslandsEngine
  doctest IslandsEngine.Island

  test "greets the world" do
    assert IslandsEngine.hello() == :world
  end
end
