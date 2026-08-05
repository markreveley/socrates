defmodule Socrates.GateTest do
  use ExUnit.Case, async: true

  alias Socrates.{Gate, Journal, Statement}

  @moduletag :tmp_dir

  # A fold with def_1 = *representation ratification*, ratified :global —
  # the store shape scenario 4's intake runs against.
  defp seeded_fold(dir) do
    File.write!(Path.join(dir, "journal.jsonl"), "")
    Journal.append(dir, %{event: "exchange_opened", exchange: 1, ts: ts()})

    Journal.append(dir, %{
      event: "statement_added",
      statement: %Statement{
        sid: "DEFSID0000000000000000000A",
        display_id: "def_1",
        type: "def",
        term: "representation ratification",
        scope: "global",
        body: "the operator verifying",
        exchange: 1,
        seq: 1,
        state: "ratified",
        author: "operator",
        inserted_at: ts()
      },
      ts: ts()
    })

    Journal.fold(dir)
  end

  defp ts, do: "2026-08-05T00:00:00Z"

  defp artifact_statement(id, attrs \\ []) do
    type = id |> String.split("_") |> hd()

    struct!(
      %Statement{artifact_id: id, type: type, body: "a body", deps: [], notes: []},
      attrs
    )
  end

  describe "check_artifact" do
    test "clean artifact passes, statements returned in order", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:ok, statements, []} =
        Gate.check_artifact(
          [
            artifact_statement("attest_1", deps: ["def_1"]),
            artifact_statement("attest_2", deps: ["attest_1"])
          ],
          fold
        )

      assert Enum.map(statements, & &1.artifact_id) == ~w(attest_1 attest_2)
    end

    test "E_ID_FORM: malformed id, and prefix/type mismatch", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:error, errors, _} =
        Gate.check_artifact(
          [
            artifact_statement("act", type: "act"),
            %Statement{artifact_id: "claim_1", type: "attest", body: "x", deps: [], notes: []},
            %Statement{artifact_id: "attest_1", type: "infer", body: "x", deps: [], notes: []}
          ],
          fold
        )

      assert [
               %{code: "E_ID_FORM", subject: "act"},
               %{code: "E_ID_FORM", subject: "claim_1"},
               %{code: "E_ID_FORM", subject: "attest_1", detail: "display id must be infer_<n>"}
             ] = errors
    end

    test "E_DUP_ID within the artifact, and collision with a global def", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:error, errors, _} =
        Gate.check_artifact(
          [
            artifact_statement("attest_1"),
            artifact_statement("attest_1"),
            artifact_statement("def_1", type: "def", term: "other", scope: "local")
          ],
          fold
        )

      codes = Enum.map(errors, &{&1.code, &1.subject})
      assert {"E_DUP_ID", "attest_1"} in codes
      assert {"E_DUP_ID", "def_1"} in codes
    end

    test "E_DANGLING_DEP: artifact-local ids ∪ global defs only — store attests dangle", %{
      tmp_dir: dir
    } do
      fold = seeded_fold(dir)

      {:error, errors, _} =
        Gate.check_artifact([artifact_statement("attest_2", deps: ["attest_9"])], fold)

      assert [%{code: "E_DANGLING_DEP", subject: "attest_2", detail: "dep attest_9 not found"}] =
               errors
    end

    test "E_CYCLE with the cycle path printed", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:error, errors, _} =
        Gate.check_artifact(
          [
            artifact_statement("attest_1", deps: ["attest_2"]),
            artifact_statement("attest_2", deps: ["attest_1"])
          ],
          fold
        )

      assert [%{code: "E_CYCLE", detail: "dependency cycle: attest_1 -> attest_2 -> attest_1"}] =
               errors
    end

    test "E_TERM_UNDEF: scenario 4's exact finding — coined term with no def", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:error, errors, _} =
        Gate.check_artifact(
          [
            artifact_statement("attest_1", body: "*representation ratification* is a process"),
            artifact_statement("attest_3",
              body: "*Sounds like you know what you are doing* is an operator failure"
            )
          ],
          fold
        )

      assert errors == [
               %{
                 code: "E_TERM_UNDEF",
                 subject: "attest_3",
                 detail: "term *Sounds like you know what you are doing* has no def in scope"
               }
             ]
    end

    test "a term defined by an artifact-local def satisfies the scan", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:ok, _, _} =
        Gate.check_artifact(
          [
            artifact_statement("def_2",
              type: "def",
              term: "Sounds like you know what you are doing",
              scope: "local",
              body: "an operator failure mode"
            ),
            artifact_statement("attest_1",
              body: "*Sounds like you know what you are doing* names a failure",
              deps: ["def_2"]
            )
          ],
          fold
        )
    end

    test "E_DEF_NO_SCOPE and W_DEF_ATOMICITY carry artifact subjects", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:error, errors, warnings} =
        Gate.check_artifact(
          [
            artifact_statement("def_2", type: "def", term: "x", scope: nil, body: "One. Two.")
          ],
          fold
        )

      assert [%{code: "E_DEF_NO_SCOPE", subject: "def_2"}] = errors
      assert [%{code: "W_DEF_ATOMICITY", subject: "def_2"}] = warnings
    end

    test "ref file origins are hashed at gate time; unreadable is E_REF_NO_ORIGIN", %{
      tmp_dir: dir
    } do
      fold = seeded_fold(dir)
      path = Path.join(dir, "anchor.txt")
      File.write!(path, "bytes")

      {:ok, [ref], _} =
        Gate.check_artifact(
          [
            artifact_statement("ref_1",
              type: "ref",
              origin: %{kind: "file", locator: path, sha256: nil}
            )
          ],
          fold
        )

      assert ref.origin.sha256 == :crypto.hash(:sha256, "bytes") |> Base.encode16(case: :lower)

      {:error, errors, _} =
        Gate.check_artifact(
          [
            artifact_statement("ref_2",
              type: "ref",
              origin: %{kind: "file", locator: Path.join(dir, "gone.txt"), sha256: nil}
            )
          ],
          fold
        )

      assert [%{code: "E_REF_NO_ORIGIN", subject: "ref_2"}] = errors
    end
  end

  describe "check_operator" do
    test "term scan resolves against any live def in the store", %{tmp_dir: dir} do
      fold = seeded_fold(dir)

      {:ok, _, _} =
        Gate.check_operator(
          %Statement{type: "attest", body: "*representation ratification* is a process"},
          fold
        )

      {:error, errors, _} =
        Gate.check_operator(%Statement{type: "attest", body: "*coined here* is new"}, fold)

      assert [
               %{
                 code: "E_TERM_UNDEF",
                 subject: "attest",
                 detail: "term *coined here* has no def in scope"
               }
             ] =
               errors
    end
  end
end
