defmodule AutomataGraph do
  @moduledoc """
  Exportación de autómatas a formato DOT para Graphviz.
  """

  def to_dot({states, _alphabet, delta, start, accepted}, filename \\ "automata.dot") do
    ordered_states =
      Enum.sort_by(states, fn s -> state_label(s) end)

    normal_states =
      Enum.filter(ordered_states, fn s -> not MapSet.member?(accepted, s) end)

    final_states =
      Enum.filter(ordered_states, fn s -> MapSet.member?(accepted, s) end)

    dfa_mode = dfa_states?(ordered_states)

    transitions =
      Enum.map(delta, fn {{src, symbol}, target} ->
        transition_targets(target, dfa_mode)
        |> Enum.map(fn dst ->
          "  #{node_id(src)} -> #{node_id(dst)} [label=\"#{symbol_to_string(symbol)}\"];"
        end)
      end)
      |> List.flatten()
      |> Enum.join("\n")

    content = """
    digraph Automata {
      rankdir=LR;

      node [shape = point];
      qi;

      node [shape = circle];
    #{Enum.map(normal_states, fn s -> "  #{node_id(s)} [label=\"#{state_label(s)}\"];" end) |> Enum.join("\n")}

      node [shape = doublecircle];
    #{Enum.map(final_states, fn s -> "  #{node_id(s)} [label=\"#{state_label(s)}\"];" end) |> Enum.join("\n")}

      qi -> #{node_id(start)};

    #{transitions}
    }
    """

    File.write(filename, content)
  end

  defp node_id(state) do
    "n_" <> sanitize(state_label(state))
  end

  defp state_label(state) do
    cond do
      match?(%MapSet{}, state) ->
        elems =
          state
          |> MapSet.to_list()
          |> Enum.map(&to_string/1)
          |> Enum.sort()
          |> Enum.join(",")

        "{#{elems}}"

      is_atom(state) ->
        Atom.to_string(state)

      true ->
        to_string(state)
    end
  end

  defp symbol_to_string(:epsilon), do: "ε"
  defp symbol_to_string(symbol), do: to_string(symbol)

  defp sanitize(str) do
    String.replace(str, ~r/[^a-zA-Z0-9]/u, "_")
  end

  defp dfa_states?([]), do: false
  defp dfa_states?([first | _]), do: match?(%MapSet{}, first)

  defp transition_targets(target, true), do: [target]

  defp transition_targets(target, false) do
    if match?(%MapSet{}, target) do
      MapSet.to_list(target)
    else
      [target]
    end
  end
end
