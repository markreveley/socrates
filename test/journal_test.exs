defmodule Socrates.JournalTest do
  use ExUnit.Case, async: true

  alias Socrates.{Journal, Statement}

  @moduletag :tmp_dir

  describe "encoder determinism" do
    test "statement fields emit in canonical order, nils skipped" do
      s = %Statement{
        sid: "S1",
        display_id: "attest_1",
        type: "attest",
        body: "b",
        exchange: 1,
        seq: 1,
        state: "ratified",
        author: "operator",
        inserted_at: "2026-08-05T00:00:00Z"
      }

      line = Journal.encode(%{event: "statement_added", statement: s, ts: "2026-08-05T00:00:00Z"})

      assert line ==
               ~s({"event":"statement_added","statement":{"sid":"S1","display_id":"attest_1",) <>
                 ~s("type":"attest","body":"b","deps":[],"notes":[],"exchange":1,"seq":1,) <>
                 ~s("state":"ratified","author":"operator","inserted_at":"2026-08-05T00:00:00Z"},) <>
                 ~s("ts":"2026-08-05T00:00:00Z"})
    end

    test "plain maps emit sorted keys" do
      assert Journal.emit(%{"b" => 1, "a" => 2, "c" => %{"z" => 1, "y" => 2}}) ==
               ~s({"a":2,"b":1,"c":{"y":2,"z":1}})
    end
  end

  describe "append/fold" do
    test "append fsyncs a line; fold rebuilds statements, chains, exchanges", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "journal.jsonl"), "")
      Journal.append(dir, %{event: "exchange_opened", exchange: 1, ts: ts()})

      s = statement("S1", "attest_1", state: "ratified")
      Journal.append(dir, %{event: "statement_added", statement: s, ts: ts()})

      fold = Journal.fold(dir)
      assert fold.exchanges == [1]
      assert fold.order == ["S1"]
      assert fold.chains == %{"attest_1" => ["S1"]}
      assert fold.statements["S1"].body == "b"
      assert Journal.head(fold, "attest_1").sid == "S1"
    end

    test "state_changed folds onto the statement", %{tmp_dir: dir} do
      write_journal(dir, [
        %{event: "exchange_opened", exchange: 1, ts: ts()},
        %{
          event: "statement_added",
          statement: statement("S1", "attest_1", state: "proposed"),
          ts: ts()
        },
        %{event: "state_changed", sid: "S1", state: "ratified", note: nil, ts: ts()}
      ])

      assert Journal.fold(dir).statements["S1"].state == "ratified"
    end

    test "a revises chain shares one display id; head resolves to the live end", %{tmp_dir: dir} do
      write_journal(dir, [
        %{event: "exchange_opened", exchange: 1, ts: ts()},
        %{
          event: "statement_added",
          statement: statement("S1", "attest_1", state: "ratified"),
          ts: ts()
        },
        %{
          event: "statement_added",
          statement: statement("S2", "attest_1", state: "ratified", revises: "S1"),
          ts: ts()
        },
        %{event: "state_changed", sid: "S1", state: "superseded", note: nil, ts: ts()}
      ])

      fold = Journal.fold(dir)
      assert fold.chains["attest_1"] == ["S1", "S2"]
      assert Journal.head(fold, "attest_1").sid == "S2"
    end

    test "torn final line is a hard error, never a silent skip", %{tmp_dir: dir} do
      write_journal(dir, [%{event: "exchange_opened", exchange: 1, ts: ts()}])
      path = Path.join(dir, "journal.jsonl")
      File.write!(path, File.read!(path) <> ~s({"event":"state_ch))

      assert_raise Journal.Error, ~r/torn|malformed/, fn -> Journal.fold(dir) end
    end

    test "unknown event kind is a hard error", %{tmp_dir: dir} do
      File.write!(Path.join(dir, "journal.jsonl"), ~s({"event":"mystery"}) <> "\n")
      assert_raise Journal.Error, ~r/unknown journal event/, fn -> Journal.fold(dir) end
    end

    test "display id reuse without revises is a hard error", %{tmp_dir: dir} do
      write_journal(dir, [
        %{event: "exchange_opened", exchange: 1, ts: ts()},
        %{event: "statement_added", statement: statement("S1", "attest_1"), ts: ts()},
        %{event: "statement_added", statement: statement("S2", "attest_1"), ts: ts()}
      ])

      assert_raise Journal.Error, ~r/reused without revises/, fn -> Journal.fold(dir) end
    end
  end

  describe "derived views" do
    test "next_index is store-global over every id ever journaled (D7)", %{tmp_dir: dir} do
      write_journal(dir, [
        %{event: "exchange_opened", exchange: 1, ts: ts()},
        %{event: "statement_added", statement: statement("S1", "attest_1"), ts: ts()},
        %{
          event: "statement_added",
          statement: statement("S2", "attest_7", state: "rejected"),
          ts: ts()
        }
      ])

      fold = Journal.fold(dir)
      # rejected ids stay consumed for the life of the store
      assert Journal.next_index(fold, "attest") == 8
      assert Journal.next_index(fold, "def") == 1
    end

    test "global_defs lists live ratified :global defs in display order; export writes them", %{
      tmp_dir: dir
    } do
      write_journal(dir, [
        %{event: "exchange_opened", exchange: 1, ts: ts()},
        %{
          event: "statement_added",
          statement: def_statement("D1", "def_1", "beta", "global", "ratified"),
          ts: ts()
        },
        %{
          event: "statement_added",
          statement: def_statement("D2", "def_2", "alpha", "global", "proposed"),
          ts: ts()
        },
        %{
          event: "statement_added",
          statement: def_statement("D3", "def_3", "gamma", "local", "ratified"),
          ts: ts()
        }
      ])

      fold = Journal.fold(dir)
      assert [%{display_id: "def_1", term: "beta"}] = Journal.global_defs(fold)

      Journal.export_definitions(dir, fold)

      assert File.read!(Path.join(dir, "definitions.json")) ==
               ~s({"beta":{"body":"a def body","display_id":"def_1","sid":"D1"}}) <> "\n"
    end
  end

  describe "properties" do
    test "encode |> decode |> encode is byte-identical (seeded random events)", %{tmp_dir: _} do
      :rand.seed(:exsss, {2026, 8, 5})

      for _ <- 1..300 do
        event = random_event()
        line = Journal.encode(event)
        reencoded = line |> Journal.decode() |> Journal.encode()
        assert reencoded == line, "diverged for #{inspect(event)}"
      end
    end

    test "folding the journal twice yields identical state", %{tmp_dir: dir} do
      :rand.seed(:exsss, {5, 8, 2026})

      for round <- 1..20 do
        subdir = Path.join(dir, "round-#{round}")
        File.mkdir_p!(subdir)
        write_journal(subdir, random_journal())
        assert Journal.fold(subdir) == Journal.fold(subdir)
      end
    end
  end

  ## Helpers

  defp ts, do: "2026-08-05T00:00:00Z"

  defp write_journal(dir, events) do
    File.write!(Path.join(dir, "journal.jsonl"), "")
    Enum.each(events, &Journal.append(dir, &1))
  end

  defp statement(sid, display_id, opts \\ []) do
    %Statement{
      sid: sid,
      display_id: display_id,
      type: display_id |> String.split("_") |> hd(),
      body: "b",
      exchange: 1,
      seq: 1,
      state: opts[:state] || "ratified",
      revises: opts[:revises],
      author: "operator",
      inserted_at: ts()
    }
  end

  defp def_statement(sid, display_id, term, scope, state) do
    %{statement(sid, display_id, state: state) | term: term, scope: scope, body: "a def body"}
  end

  ## Random generators (stdlib only — no property-testing dep)

  defp random_event do
    case :rand.uniform(4) do
      1 ->
        %{
          event: "exchange_opened",
          exchange: :rand.uniform(100),
          source: maybe(fn -> random_source() end),
          ts: random_string()
        }

      2 ->
        %{event: "statement_added", statement: random_statement(), ts: random_string()}

      3 ->
        %{
          event: "state_changed",
          sid: random_string(),
          state: random_string(),
          note: maybe(fn -> random_string() end),
          ts: random_string()
        }

      4 ->
        %{
          event: "intake_rejected",
          exchange: :rand.uniform(100),
          errors:
            random_list(fn ->
              %{code: random_string(), subject: random_string(), detail: random_string()}
            end),
          calls: random_list(fn -> random_call() end),
          rejected: maybe(fn -> random_source() end),
          ts: random_string()
        }
    end
  end

  defp random_statement do
    type = Enum.random(~w(def ref attest infer act did))

    %Statement{
      sid: random_string(),
      display_id: "#{type}_#{:rand.uniform(20)}",
      artifact_id: maybe(fn -> random_string() end),
      type: type,
      term: if(type == "def", do: random_string()),
      scope: if(type == "def", do: Enum.random(~w(local global))),
      origin:
        if(type == "ref",
          do: %{
            kind: Enum.random(~w(file url exchange quote)),
            locator: random_string(),
            sha256: maybe(fn -> random_string() end)
          }
        ),
      body: random_string(),
      deps: random_list(fn -> random_string() end),
      notes: random_list(fn -> random_string() end),
      exchange: :rand.uniform(50),
      seq: :rand.uniform(50),
      state: Enum.random(~w(proposed ratified rejected superseded)),
      revises: maybe(fn -> random_string() end),
      author: Enum.random(~w(operator model)),
      provenance: maybe(fn -> %{calls: random_list(fn -> random_call() end)} end),
      inserted_at: random_string()
    }
  end

  defp random_call do
    %{
      n: :rand.uniform(3),
      model: random_string(),
      request_id: random_string(),
      request_sha256: random_string(),
      response_sha256: random_string(),
      usage: %{input_tokens: :rand.uniform(10_000), output_tokens: :rand.uniform(10_000)},
      ts: random_string()
    }
  end

  defp random_source, do: %{path: random_string(), sha256: random_string()}

  defp maybe(f), do: if(:rand.uniform(2) == 1, do: f.(), else: nil)

  defp random_list(f), do: for(_ <- 1..:rand.uniform(3), do: f.())

  # Strings that stress the encoder: escapes, quotes, unicode, newlines.
  @tricky [
    "",
    "plain",
    ~s("quoted"),
    "back\\slash",
    "line\nbreak",
    "tab\there",
    "⊢ unicode ✓",
    "emoji 🙂",
    "null byte",
    " · dots · "
  ]
  defp random_string do
    case :rand.uniform(3) do
      1 -> Enum.random(@tricky)
      _ -> for(_ <- 1..:rand.uniform(12), into: "", do: <<Enum.random(32..126)>>)
    end
  end

  # A structurally valid random journal: coherent chains, known sids.
  defp random_journal do
    n = :rand.uniform(15)

    {events, _sids} =
      Enum.reduce(1..n, {[%{event: "exchange_opened", exchange: 1, ts: ts()}], []}, fn i,
                                                                                       {events,
                                                                                        sids} ->
        case {:rand.uniform(3), sids} do
          {1, [_ | _]} ->
            {[
               %{
                 event: "state_changed",
                 sid: Enum.random(sids),
                 state: Enum.random(~w(ratified rejected superseded)),
                 note: nil,
                 ts: ts()
               }
               | events
             ], sids}

          _ ->
            sid = "S#{i}"
            s = statement(sid, "attest_#{i}", state: "proposed")
            {[%{event: "statement_added", statement: s, ts: ts()} | events], [sid | sids]}
        end
      end)

    Enum.reverse(events)
  end
end
