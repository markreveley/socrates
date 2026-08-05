defmodule Socrates.IntakeTest do
  @moduledoc """
  Scenarios 4–6: intake under the fixture client, exact end to end (audit
  A3 — the fixture walk is the exact acceptance path). Cumulative store, as
  the spec's walkthrough is cumulative.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @moduletag :tmp_dir

  @canon_block """
  [claim_0](def_0) *representation ratification*(def_0) is a process whereby intent by the agent is ratified as a checkable artifact by the operator

  [claim_1](def_0, claim_0) *representation ratification*(def_0) is a process whereby socratic agent output is audited against socratic ratified intent statements

  [claim_2] *Sounds like you know what you are doing" {coinable local, candidate for global filing} is an operator failure when the combination of semantically dense and opaque communication which is expensive to unpack is left unpacked in favor of assuming the agent "knows what its doing", incentivizing the easier path of default approving

  [claim_3](def_0, claim_1, claim_2) *representation ratification*(def_0) converts "sounds like you know what you're doing, keep going" into a set of discrete decisions the operator approves or rejects one at a time."
  """

  setup %{tmp_dir: dir} do
    prev = File.cwd!()
    File.cd!(dir)
    System.put_env("SOCRATES_CLIENT", "fixture")

    on_exit(fn ->
      System.delete_env("SOCRATES_CLIENT")
      File.cd!(prev)
    end)

    :ok
  end

  defp run(argv) do
    parent = self()

    stderr =
      capture_io(:stderr, fn ->
        stdout = capture_io(fn -> send(parent, {:code, Socrates.CLI.run(argv)}) end)
        send(parent, {:stdout, stdout})
      end)

    {code, stdout} =
      receive do
        {:code, c} ->
          receive do
            {:stdout, out} -> {c, out}
          end
      end

    {code, stdout, stderr}
  end

  # Scenario 2's store, then scenario 4's def_1 add.
  defp seed_store do
    {0, _, _} = run(~w(init))
    {0, _, _} = run(~w(add --type attest --body) ++ ["apples are fruits"])
    {0, _, _} = run(~w(add --type attest --body) ++ ["fruits reproduce"])

    {0, _, _} =
      run(~w(add --type infer --dep attest_1 --dep attest_2 --body) ++ ["apples reproduce"])

    {0, _, _} = run(~w(add --type attest --body) ++ ["i want access to more food consistently"])

    {0, _, _} =
      run(
        ~w(add --type act --dep infer_1 --dep attest_3 --body) ++
          ["i should consider planting apple trees"]
      )

    {0, out, _} =
      run(
        ~w(add --type def --term) ++
          [
            "representation ratification",
            "--scope",
            "global",
            "--body",
            "the operator verifying the agent's socrates rendering of operator intent before any work is done"
          ]
      )

    assert String.starts_with?(out, "def_1 ")
    File.write!("canon-block.txt", @canon_block)
  end

  test "scenarios 4–6 cumulative: the gate catches the coinage, failure fails loudly, verify sees all" do
    seed_store()

    ## Scenario 4 — intake canon #1; the fixture walk is exact

    {code, stdout, stderr} = run(~w(intake canon-block.txt))
    assert code == 0

    assert stderr =~ ~r/^exchange 2 opened · source archived [0-9a-f]{12}\n/

    assert stderr ==
             Regex.run(~r/^exchange 2 opened · source archived [0-9a-f]{12}\n/, stderr)
             |> hd()
             |> Kernel.<>(
               "gate: E_TERM_UNDEF attest_3: term *Sounds like you know what you are doing* has no def in scope\n" <>
                 "repair 1/2 …\n" <>
                 "gate: pass (5 statements, 0 warnings)\n" <>
                 "[inference: fixture · - · 0 in / 0 out]\n"
             )

    assert stdout ==
             "  [def_2] *Sounds like you know what you are doing* {coinable local, candidate for global filing} : the operator failure of approving semantically dense and opaque agent output on the assumption that the agent knows what it is doing\n" <>
               "  [attest_4](def_1) *representation ratification* is a process whereby intent by the agent is ratified as a checkable artifact by the operator\n" <>
               "  [attest_5](def_1, attest_4) *representation ratification* is a process whereby socratic agent output is audited against socratic ratified intent statements\n" <>
               "  [attest_6](def_1, def_2) *Sounds like you know what you are doing* is an operator failure when the combination of semantically dense and opaque communication which is expensive to unpack is left unpacked in favor of assuming the agent \"knows what its doing\", incentivizing the easier path of default approving   {coinable local, candidate for global filing}\n" <>
               "  [attest_7](def_1, attest_5, attest_6) *representation ratification* converts \"sounds like you know what you're doing, keep going\" into a set of discrete decisions the operator approves or rejects one at a time.\"\n"

    # archives: source + two responses, journaled with digests
    assert File.exists?(".socrates/sources/2/source.txt")
    assert File.exists?(".socrates/sources/2/response-1.json")
    assert File.exists?(".socrates/sources/2/response-2.json")
    assert File.read!(".socrates/sources/2/source.txt") == @canon_block

    # provenance is honest: fixture, no request id, zero usage, both calls
    fold = Socrates.Journal.fold(".socrates")
    attest_4 = Socrates.Journal.head(fold, "attest_4")
    assert attest_4.author == "model"
    assert attest_4.state == "proposed"
    assert attest_4.artifact_id == "attest_1"
    assert [%{n: 1, model: "fixture"}, %{n: 2, model: "fixture"}] = attest_4.provenance.calls

    # proposed statements render without ⊢; ratification is the operator's act
    {code, _, stderr} = run(~w(ratify def_2 attest_4 attest_5 attest_6 attest_7))
    assert code == 0
    assert stderr == "5 ratified\n[deterministic]\n"

    {0, stdout, _} = run(~w(render @2))
    assert stdout =~ "⊢ [def_2] *Sounds like you know what you are doing*"
    assert stdout =~ "⊢ [attest_7](def_1, attest_5, attest_6)"

    # def_2 is scope local: definitions.json still carries only def_1
    defs = JSON.decode!(File.read!(".socrates/definitions.json"))
    assert Map.keys(defs) == ["representation ratification"]
    assert defs["representation ratification"]["display_id"] == "def_1"

    ## Scenario 5 — intake failure fails loudly

    File.write!("bad-input.txt", "gibberish that decomposes badly\n")
    journal_before = File.read!(".socrates/journal.jsonl")

    {code, stdout, stderr} = run(~w(intake bad-input.txt))
    assert code == 1
    assert stdout == ""

    assert stderr ==
             Regex.run(~r/^exchange 3 opened · source archived [0-9a-f]{12}\n/, stderr)
             |> hd()
             |> Kernel.<>(
               "gate: E_DANGLING_DEP attest_2: dep attest_9 not found\n" <>
                 "repair 1/2 …\n" <>
                 "gate: E_DANGLING_DEP attest_2: dep attest_9 not found\n" <>
                 "repair 2/2 …\n" <>
                 "gate: E_DANGLING_DEP attest_2: dep attest_9 not found\n" <>
                 "rejected after 2 repairs · artifact: .socrates/sources/3/rejected-2.json\n" <>
                 "[inference: fixture · - · 0 in / 0 out]\n"
             )

    # nothing entered the graph; intake_rejected is in the journal
    assert File.exists?(".socrates/sources/3/rejected-2.json")
    fold = Socrates.Journal.fold(".socrates")
    added = journal_events_after(journal_before)
    assert Enum.map(added, & &1["event"]) == ["exchange_opened", "intake_rejected"]
    assert map_size(fold.statements) == 11

    {0, log_out, _} = run(~w(log --limit 1))
    assert log_out =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z intake_rejected @3\n$/

    ## Scenario 6 — verify, clean and tampered

    {code, _, stderr} = run(~w(verify))
    assert code == 0
    assert stderr == "sources: 8 files ok · ref origins: 0 checked\n[deterministic]\n"

    original = File.read!(".socrates/sources/2/source.txt")
    File.write!(".socrates/sources/2/source.txt", original <> "x")

    {code, _, stderr} = run(~w(verify))
    assert code == 3
    assert stderr == "MISMATCH .socrates/sources/2/source.txt\n[deterministic]\n"

    File.write!(".socrates/sources/2/source.txt", original)
    {0, _, _} = run(~w(verify))
  end

  test "stop_reason other than end_turn fails loudly: archived, journaled, exit 1" do
    seed_store()

    truncated = %{
      "id" => "msg_fixture",
      "type" => "message",
      "role" => "assistant",
      "model" => "fixture",
      "stop_reason" => "max_tokens",
      "content" => [%{"type" => "text", "text" => "{\"statements\": []}"}],
      "usage" => %{"input_tokens" => 0, "output_tokens" => 0}
    }

    File.write!("responses.json", JSON.encode!([truncated]))
    System.put_env("SOCRATES_CLIENT", "fixture:responses.json")

    {code, stdout, stderr} = run(~w(intake canon-block.txt))
    assert code == 1
    assert stdout == ""
    assert stderr =~ "stop_reason max_tokens — response archived, not gated"
    assert stderr =~ "[inference: fixture · - · 0 in / 0 out]"

    assert File.exists?(".socrates/sources/2/response-1.json")
    fold = Socrates.Journal.fold(".socrates")

    assert [%{event: "intake_rejected", errors: [%{code: "stop_reason", detail: "max_tokens"}]}] =
             Enum.filter(fold.events, &(&1.event == "intake_rejected"))
  end

  test "intake without a store, without a source, with a bad client name" do
    {code, _, stderr} = run(~w(intake canon-block.txt))
    assert code == 2
    assert stderr == "no .socrates here (run: socrates init)\n[deterministic]\n"

    {0, _, _} = run(~w(init))

    {2, _, stderr} = run(~w(intake missing.txt))
    assert stderr =~ "cannot read missing.txt"

    System.put_env("SOCRATES_CLIENT", "carrier-pigeon")
    {2, _, stderr} = run(~w(intake canon-block.txt))
    assert stderr =~ "unknown SOCRATES_CLIENT: carrier-pigeon"
    System.put_env("SOCRATES_CLIENT", "fixture")
  end

  test "anthropic client without ANTHROPIC_API_KEY is an environment error before anything mutates" do
    {0, _, _} = run(~w(init))
    File.write!("in.txt", "prose\n")
    System.delete_env("SOCRATES_CLIENT")
    key = System.get_env("ANTHROPIC_API_KEY")
    System.delete_env("ANTHROPIC_API_KEY")

    journal = File.read!(".socrates/journal.jsonl")
    {code, _, stderr} = run(~w(intake in.txt))
    assert code == 2
    assert stderr == "ANTHROPIC_API_KEY not set (required by intake)\n[deterministic]\n"
    assert File.read!(".socrates/journal.jsonl") == journal
    refute File.exists?(".socrates/sources/2")

    if key, do: System.put_env("ANTHROPIC_API_KEY", key)
    System.put_env("SOCRATES_CLIENT", "fixture")
  end

  defp journal_events_after(before) do
    after_content = File.read!(".socrates/journal.jsonl")
    new_lines = String.replace_prefix(after_content, before, "")

    new_lines
    |> String.trim_trailing("\n")
    |> String.split("\n", trim: true)
    |> Enum.map(&JSON.decode!/1)
  end
end
