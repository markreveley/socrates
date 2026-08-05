defmodule Socrates.CLIScenariosTest do
  @moduledoc """
  The normative scenario walks from spec/scenarios-v0.md, as integration
  tests. Lines outside <angle-brackets> in the spec are exact contracts —
  assertions here compare byte-for-byte, with sids/timestamps matched by
  pattern. Each scenario runs in a scratch tmp dir; the walks are cumulative
  within a test, mirroring the spec.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @moduletag :tmp_dir

  setup %{tmp_dir: dir} do
    prev = File.cwd!()
    File.cd!(dir)
    on_exit(fn -> File.cd!(prev) end)
    :ok
  end

  defp run(argv, input \\ nil) do
    parent = self()

    stderr =
      capture_io(:stderr, fn ->
        stdout =
          if input do
            capture_io([input: input, capture_prompt: false], fn ->
              send(parent, {:code, Socrates.CLI.run(argv)})
            end)
          else
            capture_io(fn -> send(parent, {:code, Socrates.CLI.run(argv)}) end)
          end

        send(parent, {:stdout, stdout})
      end)

    code =
      receive do
        {:code, c} -> c
      end

    stdout =
      receive do
        {:stdout, out} -> out
      end

    {code, stdout, stderr}
  end

  describe "scenario 1 — init, and the store refuses to be assumed" do
    test "show before init: exit 2, exact stderr" do
      {code, stdout, stderr} = run(~w(show attest_1))
      assert code == 2
      assert stdout == ""
      assert stderr == "no .socrates here (run: socrates init)\n[deterministic]\n"
    end

    test "init succeeds once, then refuses" do
      {code, stdout, stderr} = run(~w(init))
      assert code == 0
      assert stdout == ""
      assert stderr == "initialized .socrates/\n[deterministic]\n"

      {code, _, stderr} = run(~w(init))
      assert code == 2
      assert stderr =~ "already exists"
    end
  end

  describe "scenario 2 — the pen: the practical syllogism, authored directly" do
    test "the five adds, display ids assigned store-globally, then the dangling-dep refusal" do
      {0, _, _} = run(~w(init))

      {code, stdout, stderr} = run(~w(add --type attest --body) ++ ["apples are fruits"])
      assert code == 0
      assert [_, sid1] = String.split(String.trim(stdout), " ")
      assert stdout == "attest_1 #{sid1}\n"
      assert Socrates.Sid.valid?(sid1)
      assert stderr == "[deterministic]\n"

      {0, out2, _} = run(~w(add --type attest --body) ++ ["fruits reproduce"])
      assert String.starts_with?(out2, "attest_2 ")

      {0, out3, _} =
        run(~w(add --type infer --dep attest_1 --dep attest_2 --body) ++ ["apples reproduce"])

      assert String.starts_with?(out3, "infer_1 ")

      {0, out4, _} =
        run(~w(add --type attest --body) ++ ["i want access to more food consistently"])

      assert String.starts_with?(out4, "attest_3 ")

      {0, out5, _} =
        run(
          ~w(add --type act --dep infer_1 --dep attest_3 --body) ++
            ["i should consider planting apple trees"]
        )

      assert String.starts_with?(out5, "act_1 ")

      # the lint refuses a dangling dep — nothing is journaled
      journal_before = File.read!(".socrates/journal.jsonl")

      {code, stdout, stderr} =
        run(~w(add --type act --dep infer_9 --body) ++ ["i should plant now"])

      assert code == 1
      assert stdout == ""
      assert stderr == "E_DANGLING_DEP act: dep infer_9 not found\n[deterministic]\n"
      assert File.read!(".socrates/journal.jsonl") == journal_before
    end

    test "body arrives on stdin when --body is absent" do
      {0, _, _} = run(~w(init))
      {code, stdout, _} = run(~w(add --type attest), "from stdin\n")
      assert code == 0
      assert String.starts_with?(stdout, "attest_1 ")

      {0, line, _} = run(~w(render))
      assert line == "⊢ [attest_1] from stdin\n"
    end
  end

  describe "M1 render and log surfaces" do
    test "render shows ⊢ on ratified operator statements, pipe-clean stdout" do
      {0, _, _} = run(~w(init))
      {0, _, _} = run(~w(add --type attest --body) ++ ["apples are fruits"])
      {0, _, _} = run(~w(add --type attest --body) ++ ["fruits reproduce"])

      {code, stdout, stderr} = run(~w(render))
      assert code == 0
      assert stdout == "⊢ [attest_1] apples are fruits\n⊢ [attest_2] fruits reproduce\n"
      assert stderr == "[deterministic]\n"
    end

    test "render --ascii substitutes |-" do
      {0, _, _} = run(~w(init))
      {0, _, _} = run(~w(add --type attest --body) ++ ["apples are fruits"])
      {0, stdout, _} = run(~w(render --ascii))
      assert stdout == "|- [attest_1] apples are fruits\n"
    end

    test "def renders as [id] *term* : body and deps render in one paren group" do
      {0, _, _} = run(~w(init))

      {0, _, _} =
        run(
          ~w(add --type def --term glossary --scope global --body) ++ ["a list of defined terms"]
        )

      {0, _, _} = run(~w(add --type attest --body) ++ ["one"])

      {0, _, _} =
        run(
          ~w(add --type attest --dep attest_1 --dep def_1 --note) ++ ["a note", "--body", "two"]
        )

      {0, stdout, _} = run(~w(render))

      assert stdout ==
               "⊢ [def_1] *glossary* : a list of defined terms\n" <>
                 "⊢ [attest_1] one\n" <>
                 "⊢ [attest_2](attest_1, def_1) two   {a note}\n"
    end

    test "log prints events newest last with --limit" do
      {0, _, _} = run(~w(init))
      {0, _, _} = run(~w(add --type attest --body one))
      {0, _, _} = run(~w(add --type attest --body two))

      {0, stdout, _} = run(~w(log))
      lines = String.split(String.trim(stdout), "\n")
      assert length(lines) == 3
      assert Enum.at(lines, 0) =~ ~r/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z exchange_opened @1$/
      assert Enum.at(lines, 1) =~ ~r/ statement_added attest_1 [0-9A-Z]{26}$/
      assert Enum.at(lines, 2) =~ ~r/ statement_added attest_2 [0-9A-Z]{26}$/

      {0, stdout, _} = run(~w(log --limit 1))
      assert String.trim(stdout) =~ ~r/ statement_added attest_2 /
    end

    test "show prints the rendered line then the pinned field pairs" do
      {0, _, _} = run(~w(init))
      {0, out, _} = run(~w(add --type attest --body) ++ ["apples are fruits"])
      [_, sid] = out |> String.trim() |> String.split(" ")
      {0, _, _} = run(~w(add --type infer --dep attest_1 --body) ++ ["so they grow"])

      {code, stdout, _} = run(~w(show attest_1))
      assert code == 0

      assert stdout == """
             ⊢ [attest_1] apples are fruits
             sid: #{sid}
             exchange: 1
             state: ratified
             author: operator
             deps: -
             rdeps: 1
             provenance: -
             revises: -
             """

      # sids are accepted anywhere a display id is
      {0, by_sid, _} = run(["show", sid])
      assert by_sid == stdout
    end
  end

  describe "scenario 3 — reading the graph (M2)" do
    defp author_syllogism do
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
    end

    test "render: topological order, exact bytes, ⊢ on every operator statement" do
      author_syllogism()
      {code, stdout, stderr} = run(~w(render))
      assert code == 0

      assert stdout == """
             ⊢ [attest_1] apples are fruits
             ⊢ [attest_2] fruits reproduce
             ⊢ [attest_3] i want access to more food consistently
             ⊢ [infer_1](attest_1, attest_2) apples reproduce
             ⊢ [act_1](infer_1, attest_3) i should consider planting apple trees
             """

      assert stderr == "[deterministic]\n"
    end

    test "rdeps direct and --all, exact bytes" do
      author_syllogism()

      {0, stdout, stderr} = run(~w(rdeps attest_1))
      assert stdout == "infer_1\n"
      assert stderr == "[deterministic]\n"

      {0, stdout, _} = run(~w(rdeps attest_1 --all))
      assert stdout == "infer_1\nact_1\n"
    end

    test "deps direct and --all" do
      author_syllogism()

      {0, stdout, _} = run(~w(deps act_1))
      assert stdout == "infer_1\nattest_3\n"

      {0, stdout, _} = run(~w(deps act_1 --all))
      assert stdout == "infer_1\nattest_3\nattest_1\nattest_2\n"
    end

    test "selectors: <id>, <id>+deps, <id>+rdeps, @<exchange>" do
      author_syllogism()

      {0, stdout, _} = run(~w(render infer_1))
      assert stdout == "⊢ [infer_1](attest_1, attest_2) apples reproduce\n"

      {0, stdout, _} = run(~w(render infer_1+deps))

      assert stdout == """
             ⊢ [attest_1] apples are fruits
             ⊢ [attest_2] fruits reproduce
             ⊢ [infer_1](attest_1, attest_2) apples reproduce
             """

      {0, stdout, _} = run(~w(render attest_1+rdeps))

      assert stdout == """
             ⊢ [attest_1] apples are fruits
             ⊢ [infer_1](attest_1, attest_2) apples reproduce
             ⊢ [act_1](infer_1, attest_3) i should consider planting apple trees
             """

      {0, stdout, _} = run(~w(render @1))
      assert stdout =~ "act_1"

      {2, _, stderr} = run(~w(render attest_1+sideways))
      assert stderr =~ "unknown selector"
    end

    test "graph prints an indented dependency tree from the roots" do
      author_syllogism()
      {0, stdout, _} = run(~w(graph))

      assert stdout == """
             ⊢ [act_1](infer_1, attest_3) i should consider planting apple trees
               ⊢ [infer_1](attest_1, attest_2) apples reproduce
                 ⊢ [attest_1] apples are fruits
                 ⊢ [attest_2] fruits reproduce
               ⊢ [attest_3] i want access to more food consistently
             """
    end
  end

  describe "M2 — ratify/reject and verify surfaces" do
    test "transitioning a non-proposed statement: error, exit 2, nothing journaled" do
      {0, _, _} = run(~w(init))
      {0, _, _} = run(~w(add --type attest --body x))
      journal = File.read!(".socrates/journal.jsonl")

      {code, _, stderr} = run(~w(ratify attest_1))
      assert code == 2
      assert stderr =~ "attest_1 is ratified, not proposed"
      assert File.read!(".socrates/journal.jsonl") == journal

      {2, _, stderr} = run(~w(ratify attest_9))
      assert stderr =~ "unknown id: attest_9"
    end

    test "operator add now refuses an undefined term (M2 full lint)" do
      {0, _, _} = run(~w(init))

      {1, _, stderr} = run(~w(add --type attest --body) ++ ["*coinage* with no def"])

      assert stderr ==
               "E_TERM_UNDEF attest: term *coinage* has no def in scope\n[deterministic]\n"

      {0, _, _} =
        run(~w(add --type def --term coinage --scope local --body) ++ ["a term minted mid-walk"])

      {0, _, _} = run(~w(add --type attest --body) ++ ["*coinage* with a def"])
    end

    test "verify: clean empty store, then a tampered ref origin trips exit 3" do
      {0, _, _} = run(~w(init))

      {code, _, stderr} = run(~w(verify))
      assert code == 0
      assert stderr == "sources: 0 files ok · ref origins: 0 checked\n[deterministic]\n"

      File.write!("anchor.txt", "original\n")
      {0, _, _} = run(~w(add --type ref --origin file:anchor.txt --body) ++ ["an anchor"])

      {0, _, stderr} = run(~w(verify))
      assert stderr == "sources: 0 files ok · ref origins: 1 checked\n[deterministic]\n"

      File.write!("anchor.txt", "tampered\n")
      {code, _, stderr} = run(~w(verify))
      assert code == 3
      assert stderr == "MISMATCH anchor.txt\n[deterministic]\n"
    end
  end

  describe "usage and environment errors" do
    test "unknown command, unknown type, def/ref flag requirements" do
      {2, _, stderr} = run(~w(frobnicate))
      assert stderr =~ "unknown command: frobnicate"

      {0, _, _} = run(~w(init))

      {2, _, stderr} = run(~w(add --type banana --body x))
      assert stderr =~ "unknown type: banana"

      {2, _, stderr} = run(~w(add --type def --scope global --body x))
      assert stderr =~ "def requires --term"

      {1, _, stderr} = run(~w(add --type def --term t --body x))
      assert stderr =~ "E_DEF_NO_SCOPE def: defs declare local or global"

      {1, _, stderr} = run(~w(add --type ref --body x))
      assert stderr =~ "E_REF_NO_ORIGIN ref: refs carry an origin"

      {2, _, stderr} = run(~w(add --type attest --term t --body x))
      assert stderr =~ "--term is def-only"
    end

    test "ref file origin is hashed at add time; missing file is E_REF_NO_ORIGIN" do
      {0, _, _} = run(~w(init))

      File.write!("anchor.txt", "anchored bytes\n")
      {0, out, _} = run(~w(add --type ref --origin file:anchor.txt --body) ++ ["an anchor"])
      assert String.starts_with?(out, "ref_1 ")

      fold = Socrates.Journal.fold(".socrates")
      ref = Socrates.Journal.head(fold, "ref_1")

      assert ref.origin.sha256 ==
               :crypto.hash(:sha256, "anchored bytes\n") |> Base.encode16(case: :lower)

      {1, _, stderr} = run(~w(add --type ref --origin file:missing.txt --body) ++ ["nope"])
      assert stderr =~ "E_REF_NO_ORIGIN ref: file missing.txt not found"
    end

    test "def add warns W_DEF_ATOMICITY to stderr without blocking" do
      {0, _, _} = run(~w(init))

      {code, stdout, stderr} =
        run(~w(add --type def --term x --scope local --body) ++ ["One thing. Another thing."])

      assert code == 0
      assert String.starts_with?(stdout, "def_1 ")
      assert stderr == "W_DEF_ATOMICITY def: def body reads multi-sentence\n[deterministic]\n"
    end
  end
end
