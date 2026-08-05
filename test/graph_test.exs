defmodule Socrates.GraphTest do
  use ExUnit.Case, async: true

  alias Socrates.Graph

  # Bare-map statements: Graph is context-neutral (key/deps_of supplied).
  defp s(id, deps \\ [], type \\ nil) do
    %{display_id: id, deps: deps, type: type || id |> String.split("_") |> hd()}
  end

  defp topo(statements), do: Graph.topo_sort(statements, & &1.deps, & &1.display_id)

  describe "topo_sort" do
    test "scenario 3's exact order: ready-set ties by journal order, deps satisfied first" do
      out =
        topo([
          s("attest_1"),
          s("attest_2"),
          s("infer_1", ["attest_1", "attest_2"]),
          s("attest_3"),
          s("act_1", ["infer_1", "attest_3"])
        ])

      assert Enum.map(out, & &1.display_id) == ~w(attest_1 attest_2 attest_3 infer_1 act_1)
    end

    test "defs and refs come first among ready nodes" do
      out = topo([s("attest_1"), s("def_2"), s("ref_1"), s("attest_2", ["def_2"])])
      assert Enum.map(out, & &1.display_id) == ~w(def_2 ref_1 attest_1 attest_2)
    end

    test "a def with deps still honors edges over class priority" do
      out = topo([s("attest_1"), s("def_1", ["attest_1"])])
      assert Enum.map(out, & &1.display_id) == ~w(attest_1 def_1)
    end

    test "external deps are treated as satisfied" do
      out = topo([s("attest_1", ["def_9"])])
      assert Enum.map(out, & &1.display_id) == ~w(attest_1)
    end
  end

  describe "cycle" do
    test "acyclic returns nil" do
      assert Graph.cycle([s("a_1"), s("b_1", ["a_1"])], & &1.deps, & &1.display_id) == nil
    end

    test "finds a cycle and returns the closed path" do
      statements = [s("a_1", ["b_1"]), s("b_1", ["c_1"]), s("c_1", ["a_1"])]
      assert Graph.cycle(statements, & &1.deps, & &1.display_id) == ["a_1", "b_1", "c_1", "a_1"]
    end

    test "self-dependency is a cycle" do
      assert Graph.cycle([s("a_1", ["a_1"])], & &1.deps, & &1.display_id) == ["a_1", "a_1"]
    end
  end

  describe "reach" do
    test "BFS discovery order, start excluded" do
      neighbors = fn
        "a" -> ["b", "c"]
        "b" -> ["d"]
        "c" -> ["d"]
        "d" -> []
      end

      assert Graph.reach("a", neighbors) == ["b", "c", "d"]
    end
  end
end
