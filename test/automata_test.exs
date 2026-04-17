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

  test "e_closure/2 calcula correctamente el cierre epsilon del automata de prueba" do
    assert Automata.e_closure(Automata.enfa(), MapSet.new([:q0])) ==
             MapSet.new([:q0, :q1, :q2])

    assert Automata.e_closure(Automata.enfa(), MapSet.new([:q1])) ==
             MapSet.new([:q1, :q2])

    assert Automata.e_closure(Automata.enfa(), MapSet.new([:q2])) ==
             MapSet.new([:q2])
  end

  test "e_determinize/1 genera un DFA con estado inicial correcto para la parte 3" do
    {dfa_states, dfa_alphabet, dfa_delta, dfa_start, dfa_accepted} =
      Automata.e_determinize(Automata.p3_enfa())

    assert dfa_alphabet == MapSet.new([:a, :b])

    assert dfa_start == MapSet.new([0, 1, 2, 3, 7])

    assert MapSet.member?(dfa_states, dfa_start)

    assert map_size(dfa_delta) > 0
    assert MapSet.size(dfa_accepted) > 0
  end
end
