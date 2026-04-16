ExUnit.start()

defmodule AutomataTest do
  use ExUnit.Case

  test "determinize/1 transforma el NFA en su DFA equivalente" do
    {dfa_states, dfa_alphabet, dfa_delta, dfa_start, dfa_accepted} =
      Automata.determinize(Automata.nfa())

    expected_states =
      MapSet.new([
        MapSet.new([:q0]),
        MapSet.new([:q0, :q1]),
        MapSet.new([:q0, :q2]),
        MapSet.new([:q0, :q3])
      ])

    expected_alphabet =
      MapSet.new([:a, :b])

    expected_start =
      MapSet.new([:q0])

    expected_accepted =
      MapSet.new([
        MapSet.new([:q0, :q3])
      ])

    expected_delta = %{
      {MapSet.new([:q0]), :a} => MapSet.new([:q0, :q1]),
      {MapSet.new([:q0]), :b} => MapSet.new([:q0]),
      {MapSet.new([:q0, :q1]), :a} => MapSet.new([:q0, :q1]),
      {MapSet.new([:q0, :q1]), :b} => MapSet.new([:q0, :q2]),
      {MapSet.new([:q0, :q2]), :a} => MapSet.new([:q0, :q1]),
      {MapSet.new([:q0, :q2]), :b} => MapSet.new([:q0, :q3]),
      {MapSet.new([:q0, :q3]), :a} => MapSet.new([:q0, :q1]),
      {MapSet.new([:q0, :q3]), :b} => MapSet.new([:q0])
    }

    assert dfa_states == expected_states
    assert dfa_alphabet == expected_alphabet
    assert dfa_start == expected_start
    assert dfa_accepted == expected_accepted
    assert dfa_delta == expected_delta
  end
end
