defmodule Automata do
  @moduledoc """
  Transformación de NFA a DFA y de ε-NFA a DFA.
  """

  # =========================
  # Ejemplos de autómatas
  # =========================

  def nfa() do
    {
      MapSet.new([0, 1, 2, 3]),
      MapSet.new([:a, :b]),
      %{
        {0, :a} => MapSet.new([0, 1]),
        {0, :b} => MapSet.new([0]),
        {1, :b} => MapSet.new([2]),
        {2, :b} => MapSet.new([3])
      },
      0,
      MapSet.new([3])
    }
  end

  def enfa() do
    {
      MapSet.new([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      MapSet.new([:a, :b]),
      %{
        {0, :epsilon} => MapSet.new([1, 7]),
        {1, :epsilon} => MapSet.new([2, 3, 6]),
        {2, :a} => MapSet.new([4]),
        {3, :b} => MapSet.new([5]),
        {4, :epsilon} => MapSet.new([6]),
        {5, :epsilon} => MapSet.new([6]),
        {6, :epsilon} => MapSet.new([1, 7]),
        {7, :a} => MapSet.new([8]),
        {8, :b} => MapSet.new([9]),
        {9, :b} => MapSet.new([10])
      },
      0,
      MapSet.new([10])
    }
  end

  # =========================
  # Funciones base
  # =========================

  def transition(delta, state, symbol) do
    Map.get(delta, {state, symbol}, MapSet.new())
  end

  def prime_transition(delta, states, symbol) do
    Enum.reduce(states, MapSet.new(), fn state, acc ->
      MapSet.union(acc, transition(delta, state, symbol))
    end)
  end

  def prime_accept(states, accepted) do
    not MapSet.disjoint?(states, accepted)
  end

  # =========================
  # Parte 1: powerset + determinize/1
  # =========================

  def power([]), do: [[]]

  def power([h | t]) do
    p = power(t)
    p ++ Enum.map(p, fn subset -> [h | subset] end)
  end

  def powerset(states) do
    states
    |> Enum.to_list()
    |> power()
    |> Enum.map(&MapSet.new/1)
  end

  def determinize({q, sigma, delta, q0, f}) do
    q_prime = powerset(q)
    q0_prime = MapSet.new([q0])

    delta_prime =
      Enum.reduce(q_prime, %{}, fn r, acc ->
        Enum.reduce(sigma, acc, fn a, acc2 ->
          s = prime_transition(delta, r, a)

          if MapSet.size(s) == 0 do
            acc2
          else
            Map.put(acc2, {r, a}, s)
          end
        end)
      end)

    f_prime =
      q_prime
      |> Enum.filter(fn r -> prime_accept(r, f) end)
      |> MapSet.new()

    {q_prime, sigma, delta_prime, q0_prime, f_prime}
    |> prune()
  end

  # =========================
  # Prune: conserva solo los estados alcanzables desde el inicial
  # =========================

  def prune({states, sigma, delta, q0, f}) do
    reachable = bfs_reachable([q0], MapSet.new([q0]), delta, sigma)

    q_prime =
      states
      |> Enum.filter(fn state -> MapSet.member?(reachable, state) end)

    delta_prime =
      Enum.reduce(delta, %{}, fn {{src, symbol}, dst}, acc ->
        if MapSet.member?(reachable, src) and MapSet.member?(reachable, dst) do
          Map.put(acc, {src, symbol}, dst)
        else
          acc
        end
      end)

    f_prime =
      f
      |> Enum.filter(fn state -> MapSet.member?(reachable, state) end)
      |> MapSet.new()

    {q_prime, sigma, delta_prime, q0, f_prime}
  end

  defp bfs_reachable([], visited, _delta, _sigma), do: visited

  defp bfs_reachable([current | pending], visited, delta, sigma) do
    next_states =
      sigma
      |> Enum.reduce([], fn symbol, acc ->
        case Map.get(delta, {current, symbol}) do
          nil -> acc
          target -> [target | acc]
        end
      end)
      |> Enum.reverse()

    fresh_states =
      Enum.filter(next_states, fn state ->
        not MapSet.member?(visited, state)
      end)

    new_visited =
      Enum.reduce(fresh_states, visited, fn state, acc ->
        MapSet.put(acc, state)
      end)

    bfs_reachable(pending ++ fresh_states, new_visited, delta, sigma)
  end

  # =========================
  # Parte 2: e_closure/2
  # =========================

  def e_closure({_, _, delta, _, _}, states) do
    explore_epsilon(delta, MapSet.to_list(states), states)
  end

  defp explore_epsilon(_delta, [], visited), do: visited

  defp explore_epsilon(delta, [current | pending], visited) do
    next =
      transition(delta, current, :epsilon)
      |> MapSet.difference(visited)

    new_visited = MapSet.union(visited, next)
    new_pending = pending ++ MapSet.to_list(next)

    explore_epsilon(delta, new_pending, new_visited)
  end

  def e_prime_transition({_, _, delta, _, _} = automaton, states, symbol) do
    states
    |> e_closure(automaton)
    |> Enum.reduce(MapSet.new(), fn state, acc ->
      MapSet.union(acc, transition(delta, state, symbol))
    end)
    |> then(fn moved -> e_closure(automaton, moved) end)
  end

  # =========================
  # Parte 3: e_determinize/1 utilizando un recorrido BFS recursivo
  # =========================

  def e_determinize({_, sigma, _, q0, f} = automaton) do
    q0_prime = e_closure(automaton, MapSet.new([q0]))

    {q_prime, delta_prime} =
      bfs_build(
        automaton,
        [q0_prime],
        MapSet.new(),
        %{},
        sigma
      )

    f_prime =
      q_prime
      |> Enum.filter(fn r -> prime_accept(r, f) end)
      |> MapSet.new()

    {q_prime, sigma, delta_prime, q0_prime, f_prime}
  end

  defp bfs_build(_automaton, [], discovered, delta_prime, _sigma) do
    {MapSet.to_list(discovered), delta_prime}
  end

  defp bfs_build(automaton, [current | pending], discovered, delta_prime, sigma) do
    if MapSet.member?(discovered, current) do
      bfs_build(automaton, pending, discovered, delta_prime, sigma)
    else
      new_discovered = MapSet.put(discovered, current)

      {new_pending, new_delta} =
        Enum.reduce(sigma, {pending, delta_prime}, fn symbol, {queue_acc, delta_acc} ->
          next = e_prime_transition(automaton, current, symbol)

          if MapSet.size(next) == 0 do
            {queue_acc, delta_acc}
          else
            queue_acc =
              if MapSet.member?(new_discovered, next) or next in queue_acc do
                queue_acc
              else
                queue_acc ++ [next]
              end

            delta_acc = Map.put(delta_acc, {current, symbol}, next)
            {queue_acc, delta_acc}
          end
        end)

      bfs_build(automaton, new_pending, new_discovered, new_delta, sigma)
    end
  end
end
