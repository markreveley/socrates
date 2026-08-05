defmodule Socrates.LoadoutTest do
  use ExUnit.Case, async: true

  alias Socrates.Loadout

  test "the six ratified types, in order" do
    assert Loadout.types() == ~w(def ref attest infer act did)
  end

  test "id pattern accepts well-formed ids and refuses malformed ones" do
    assert Regex.match?(Loadout.id_pattern(), "attest_1")
    assert Regex.match?(Loadout.id_pattern(), "def_0")
    refute Regex.match?(Loadout.id_pattern(), "act")
    refute Regex.match?(Loadout.id_pattern(), "claim_1")
    refute Regex.match?(Loadout.id_pattern(), "attest_")
    refute Regex.match?(Loadout.id_pattern(), "attest_1x")
  end

  describe "schema (audit C2 pins)" do
    test "is a statements-array object with anyOf per-type shapes" do
      schema = Loadout.schema()
      assert schema["required"] == ["statements"]
      branches = schema["properties"]["statements"]["items"]["anyOf"]
      assert length(branches) == 6
      types = Enum.map(branches, fn b -> b["properties"]["type"]["enum"] end)
      assert types == [["def"], ["ref"], ["attest"], ["infer"], ["act"], ["did"]]
    end

    test "additionalProperties false on every object" do
      assert_no_open_objects(Loadout.schema())
    end

    test "no minLength, pattern, or numeric constraints anywhere" do
      refute find_key(Loadout.schema(), [
               "minLength",
               "maxLength",
               "pattern",
               "minimum",
               "maximum",
               "minItems",
               "maxItems"
             ])
    end

    test "def branch requires term and scope; ref branch requires origin" do
      [def_b, ref_b, attest_b | _] =
        Loadout.schema()["properties"]["statements"]["items"]["anyOf"]

      assert "term" in def_b["required"]
      assert "scope" in def_b["required"]
      assert def_b["properties"]["scope"]["enum"] == ["local", "global"]
      assert "origin" in ref_b["required"]
      assert ref_b["properties"]["origin"]["required"] == ["kind", "locator"]

      assert ref_b["properties"]["origin"]["properties"]["kind"]["enum"] ==
               ["file", "url", "exchange", "quote"]

      assert attest_b["required"] == ["display_id", "type", "body", "deps", "notes"]
    end

    test "origin has no sha256 in the model schema (app-stamped, measured never trusted)" do
      [_, ref_b | _] = Loadout.schema()["properties"]["statements"]["items"]["anyOf"]
      refute Map.has_key?(ref_b["properties"]["origin"]["properties"], "sha256")
    end

    test "no app-stamped fields leak into any branch" do
      for branch <- Loadout.schema()["properties"]["statements"]["items"]["anyOf"],
          field <- ~w(sid exchange seq state revises author provenance inserted_at) do
        refute Map.has_key?(branch["properties"], field)
      end
    end
  end

  describe "system prompt assembly (audit C3 pins)" do
    test "two blocks, cache_control ephemeral on the last" do
      [spec, defs] = Loadout.system_blocks([])
      assert spec["type"] == "text"
      refute Map.has_key?(spec, "cache_control")
      assert defs["cache_control"] == %{"type" => "ephemeral"}
    end

    test "definitions block carries each def's display id" do
      block =
        Loadout.definitions_block([
          %{
            display_id: "def_1",
            term: "representation ratification",
            body: "the operator verifying"
          }
        ])

      assert block =~ "[def_1] *representation ratification*: the operator verifying"
    end

    test "empty definitions block says so rather than vanishing" do
      assert Loadout.definitions_block([]) =~ "(none yet)"
    end

    test "spec text teaches the term rule, dep scope, and implicit conjunction" do
      text = Loadout.spec_text()
      assert text =~ "reserved for terms"
      assert text =~ "Never use asterisks for emphasis"
      assert text =~ "a global definition listed below. Nothing else resolves"
      assert text =~ "implicit conjunction"
      assert text =~ "re-emit the\ncomplete corrected artifact"
    end
  end

  defp assert_no_open_objects(%{"type" => "object"} = obj) do
    assert obj["additionalProperties"] == false,
           "object without additionalProperties: false — #{inspect(Map.keys(obj["properties"] || %{}))}"

    Enum.each(obj["properties"] || %{}, fn {_k, v} -> assert_no_open_objects(v) end)
  end

  defp assert_no_open_objects(%{} = node) do
    Enum.each(node, fn {_k, v} -> assert_no_open_objects(v) end)
  end

  defp assert_no_open_objects(list) when is_list(list),
    do: Enum.each(list, &assert_no_open_objects/1)

  defp assert_no_open_objects(_), do: :ok

  defp find_key(%{} = node, keys) do
    Enum.any?(node, fn {k, v} -> k in keys or find_key(v, keys) end)
  end

  defp find_key(list, keys) when is_list(list), do: Enum.any?(list, &find_key(&1, keys))
  defp find_key(_, _), do: false
end
