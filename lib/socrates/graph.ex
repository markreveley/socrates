defmodule Socrates.Graph do
  @moduledoc """
  Deterministic graph machinery over a selection of statements: topological
  order (Kahn — because deps resolve and the graph is acyclic, an order
  provably exists; "definitions first" is computed here, never requested of
  the model), cycle detection (DFS, with the cycle path), and BFS closures
  for deps/rdeps.

  Functions are context-neutral: callers pass `key` (statement → node key)
  and `deps_of` (statement → list of node keys), so the same code serves the
  store graph (keys are display ids, deps resolved from sids) and a model
  artifact (keys are artifact-local ids, deps as emitted). Edges leaving the
  selection are ignored — external deps are treated as satisfied.
  """

  @doc """
  Layered topological order: statements sort by longest-path depth over
  intra-selection dep edges, then defs/refs first within a layer, then input
  order. An edge u→dep forces depth(u) > depth(dep), so the order is always
  a valid topological sort — and layering is what the normative renders
  show: every premise-layer statement appears before the first conclusion
  drawn from it (scenarios 3 and 4).
  """
  def topo_sort(statements, deps_of, key) do
    keys = MapSet.new(statements, key)

    deps_in =
      Map.new(statements, fn s ->
        {key.(s), Enum.filter(deps_of.(s), &(MapSet.member?(keys, &1) and &1 != key.(s)))}
      end)

    depths =
      Enum.reduce(Map.keys(deps_in), %{}, fn k, memo ->
        elem(depth(k, deps_in, memo, MapSet.new()), 1)
      end)

    statements
    |> Enum.with_index()
    |> Enum.sort_by(fn {s, i} -> {depths[key.(s)], class(s), i} end)
    |> Enum.map(&elem(&1, 0))
  end

  # Longest path to a sink, memoized; a visiting guard bounds cyclic input
  # (the gate refuses cycles before anything renders, but never loop).
  defp depth(k, deps_in, memo, visiting) do
    cond do
      Map.has_key?(memo, k) ->
        {memo[k], memo}

      MapSet.member?(visiting, k) ->
        {0, memo}

      true ->
        visiting = MapSet.put(visiting, k)

        {max_dep, memo} =
          Enum.reduce(deps_in[k], {-1, memo}, fn dep, {best, memo} ->
            {d, memo} = depth(dep, deps_in, memo, visiting)
            {max(best, d), memo}
          end)

        {max_dep + 1, Map.put(memo, k, max_dep + 1)}
    end
  end

  defp class(%{type: t}) when t in ["def", "ref"], do: 0
  defp class(_), do: 1

  @doc """
  First dependency cycle, as a key path (`[a, b, a]`), or nil. DFS in input
  order, neighbors in dep order — deterministic.
  """
  def cycle(statements, deps_of, key) do
    keys = MapSet.new(statements, key)

    neighbors =
      Map.new(statements, fn s ->
        {key.(s), Enum.filter(deps_of.(s), &MapSet.member?(keys, &1))}
      end)

    try do
      Enum.reduce(statements, MapSet.new(), fn s, done ->
        dfs(key.(s), neighbors, done, [], MapSet.new())
      end)

      nil
    catch
      {:cycle, path} -> path
    end
  end

  defp dfs(node, neighbors, done, path, on_path) do
    cond do
      MapSet.member?(on_path, node) ->
        cycle_path = Enum.drop_while(Enum.reverse([node | path]), &(&1 != node))
        throw({:cycle, cycle_path})

      MapSet.member?(done, node) ->
        done

      true ->
        done =
          Enum.reduce(neighbors[node] || [], done, fn next, acc ->
            dfs(next, neighbors, acc, [node | path], MapSet.put(on_path, node))
          end)

        MapSet.put(done, node)
    end
  end

  @doc """
  BFS closure from `start` (a key) over `neighbors` (key → keys), excluding
  the start itself; discovery order — closest first, ties in neighbor order.
  """
  def reach(start, neighbors) do
    bfs([start], MapSet.new([start]), neighbors, [])
  end

  defp bfs([], _seen, _neighbors, out), do: Enum.reverse(out)

  defp bfs([node | rest], seen, neighbors, out) do
    fresh = Enum.reject(neighbors.(node), &MapSet.member?(seen, &1))
    seen = Enum.reduce(fresh, seen, &MapSet.put(&2, &1))
    bfs(rest ++ fresh, seen, neighbors, Enum.reverse(fresh) ++ out)
  end
end
