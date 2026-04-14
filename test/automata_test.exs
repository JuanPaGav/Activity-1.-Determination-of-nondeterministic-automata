defmodule AutomataTest do
  use ExUnit.Case
  doctest Automata

  test "greets the world" do
    assert Automata.hello() == :world
  end
end
