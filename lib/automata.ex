defmodule Automata do
  # Autómata #1 "

  # Se define 'Q' -> como el conjunto de estados que contendrá el autómata.
  def nfa_states do
    MapSet.new([:q0, :q1, :q2, :q3])
  end

  # Se define "Σ" -> como el alfabeto del autómata.
  def nfa_alphabet do
    MapSet.new([:a, :b])
  end

  # Se define "δ" -> la función de transición.
  def nfa_delta do
    %{
      {:q0, :a} => MapSet.new([:q0, :q1]),
      {:q0, :b} => MapSet.new([:q0]),
      {:q1, :b} => MapSet.new([:q2]),
      {:q2, :b} => MapSet.new([:q3])
    }
  end

  # Se define "q0" -> el estado inicial.
  def nfa_start do
    :q0
  end

  # Se define "F" -> el conjunto de estados de aceptación.
  def nfa_accepted do
    MapSet.new([:q3])
  end

  # Se define "N" -> la 5-tupla del autómata -> (Q, Σ, δ, q0, F)
  def nfa do
    {nfa_states(), nfa_alphabet(), nfa_delta(), nfa_start(), nfa_accepted()}
  end

  #  Autómnata #2

  def enfa_states do
    MapSet.new([:q0, :q1, :q2, :q3])
  end

  def enfa_alphabet do
    MapSet.new([:a, :b])
  end

  def enfa_delta do
    %{
      {:q0, :epsilon} => MapSet.new([:q1]),
      {:q1, :epsilon} => MapSet.new([:q2]),
      {:q2, :a} => MapSet.new([:q3])
    }
  end

  def enfa_start do
    :q0
  end

  def enfa_accepted do
    MapSet.new([:q3])
  end

  def enfa do
    {enfa_states(), enfa_alphabet(), enfa_delta(), enfa_start(), enfa_accepted()}
  end

  # δ(q, a)
  def transition(delta, state, symbol) do
    Map.get(delta, {state, symbol}, MapSet.new())
  end

  # δ'(R, a) = unión de δ(q, a) para todo q en R
  def prime_transition(delta, state_set, symbol) do
    Enum.reduce(state_set, MapSet.new(), fn state, acc ->
      MapSet.union(acc, transition(delta, state, symbol))
    end)
  end

  # Un estado del DFA es final si contiene al menos un estado final del NFA
  def prime_accept(state_set, accepted_states) do
    not MapSet.disjoint?(state_set, accepted_states)
  end

  def determinize({_, alphabet, delta, start, accepted}) do
    dfa_start = MapSet.new([start])

    {dfa_states, dfa_delta} =
      build_dfa([dfa_start], MapSet.new([dfa_start]), %{}, alphabet, delta)

    dfa_accepted =
      Enum.reduce(dfa_states, MapSet.new(), fn state_set, acc ->
        if prime_accept(state_set, accepted) do
          MapSet.put(acc, state_set)
        else
          acc
        end
      end)

    {dfa_states, alphabet, dfa_delta, dfa_start, dfa_accepted}
  end

  defp build_dfa([], discovered, dfa_delta, _alphabet, _nfa_delta) do
    {discovered, dfa_delta}
  end

  defp build_dfa([current | pending], discovered, dfa_delta, alphabet, nfa_delta) do
    {new_delta, new_states} =
      Enum.reduce(alphabet, {dfa_delta, []}, fn symbol, {delta_acc, states_acc} ->
        next_state = prime_transition(nfa_delta, current, symbol)
        delta_acc = Map.put(delta_acc, {current, symbol}, next_state)

        if MapSet.member?(discovered, next_state) do
          {delta_acc, states_acc}
        else
          {delta_acc, [next_state | states_acc]}
        end
      end)

    new_discovered =
      Enum.reduce(new_states, discovered, fn state_set, acc ->
        MapSet.put(acc, state_set)
      end)

    build_dfa(pending ++ new_states, new_discovered, new_delta, alphabet, nfa_delta)
  end

  # ε-closure(R)
  def e_closure({_, _, delta, _, _}, states) do
    explore_epsilon(delta, MapSet.to_list(states), states)
  end

  defp explore_epsilon(_delta, [], visited) do
    visited
  end

  defp explore_epsilon(delta, [current | pending], visited) do
    epsilon_next = transition(delta, current, :epsilon)

    new_states = MapSet.difference(epsilon_next, visited)
    new_visited = MapSet.union(visited, new_states)
    new_pending = pending ++ MapSet.to_list(new_states)

    explore_epsilon(delta, new_pending, new_visited)
  end
end
