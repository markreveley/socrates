defmodule Socrates.Journal do
  @moduledoc """
  Append/fold over `.socrates/journal.jsonl`, and the deterministic encoder.

  The encoder owns byte-level determinism: stdlib map key order is not
  guaranteed, so events and statements are emitted through explicit field
  orders (statement order lives in `Socrates.Statement.to_pairs/1`), nil
  fields skipped, no whitespace. Plain maps (schema, exports) are emitted
  with sorted keys. `encode |> decode |> encode` is byte-identical — property
  tested. Every append is fsynced.

  Events: `exchange_opened | statement_added | state_changed |
  intake_rejected`. The journal is never rewritten; a malformed or torn line
  is a hard error (`Socrates.Journal.Error`), never a silent skip.
  """

  alias Socrates.Statement

  @journal "journal.jsonl"
  @definitions "definitions.json"

  defmodule Error do
    defexception [:message]
  end

  ## Append

  def append(store, event) do
    line = [encode(event), "\n"]

    File.open!(Path.join(store, @journal), [:append, :raw, :binary], fn io ->
      :ok = :file.write(io, line)
      :ok = :file.sync(io)
    end)

    :ok
  end

  ## Encode — one event, canonical field order, compact

  def encode(%{event: "exchange_opened"} = e) do
    emit(
      {:obj,
       [
         {"event", "exchange_opened"},
         {"exchange", e.exchange},
         {"source", source_pairs(e[:source])},
         {"ts", e.ts}
       ]}
    )
  end

  def encode(%{event: "statement_added"} = e) do
    emit(
      {:obj,
       [
         {"event", "statement_added"},
         {"statement", {:obj, Statement.to_pairs(e.statement)}},
         {"ts", e.ts}
       ]}
    )
  end

  def encode(%{event: "state_changed"} = e) do
    emit(
      {:obj,
       [
         {"event", "state_changed"},
         {"sid", e.sid},
         {"state", e.state},
         {"note", e[:note]},
         {"ts", e.ts}
       ]}
    )
  end

  def encode(%{event: "intake_rejected"} = e) do
    emit(
      {:obj,
       [
         {"event", "intake_rejected"},
         {"exchange", e.exchange},
         {"errors", Enum.map(e.errors, &error_pairs/1)},
         {"calls", Enum.map(e.calls, &call_pairs/1)},
         {"rejected", source_pairs(e[:rejected])},
         {"ts", e.ts}
       ]}
    )
  end

  defp source_pairs(nil), do: nil
  defp source_pairs(s), do: {:obj, [{"path", s.path}, {"sha256", s.sha256}]}

  defp error_pairs(err),
    do: {:obj, [{"code", err.code}, {"subject", err.subject}, {"detail", err.detail}]}

  defp call_pairs(c) do
    {:obj,
     [
       {"n", c.n},
       {"model", c.model},
       {"request_id", c.request_id},
       {"request_sha256", c.request_sha256},
       {"response_sha256", c.response_sha256},
       {"usage",
        {:obj, [{"input_tokens", c.usage.input_tokens}, {"output_tokens", c.usage.output_tokens}]}},
       {"ts", c.ts}
     ]}
  end

  @doc """
  Deterministic JSON for any value: `{:obj, pairs}` keeps the given order
  (nil values skipped); plain maps emit sorted keys; scalars/lists via
  stdlib `JSON`. Used for journal lines, request bodies, and exports.
  """
  def emit({:obj, pairs}) do
    inner =
      pairs
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> [JSON.encode!(k), ":", emit(v)] end)
      |> Enum.intersperse(",")

    IO.iodata_to_binary(["{", inner, "}"])
  end

  def emit(%{} = map) do
    emit(
      {:obj,
       map
       |> Enum.sort_by(fn {k, _} -> to_string(k) end)
       |> Enum.map(fn {k, v} -> {to_string(k), v} end)}
    )
  end

  def emit(list) when is_list(list) do
    IO.iodata_to_binary(["[", list |> Enum.map(&emit/1) |> Enum.intersperse(","), "]"])
  end

  def emit(scalar), do: JSON.encode!(scalar)

  ## Decode — strict

  def decode(line) do
    map =
      try do
        JSON.decode!(line)
      rescue
        _ -> raise Error, "malformed journal line: #{inspect(line)}"
      end

    decode_event(map)
  end

  defp decode_event(%{"event" => "exchange_opened"} = m) do
    strict_keys(m, ~w(event exchange source ts))

    %{
      event: "exchange_opened",
      exchange: m["exchange"],
      source: source_from(m["source"]),
      ts: m["ts"]
    }
  end

  defp decode_event(%{"event" => "statement_added"} = m) do
    strict_keys(m, ~w(event statement ts))
    %{event: "statement_added", statement: Statement.from_map(m["statement"]), ts: m["ts"]}
  end

  defp decode_event(%{"event" => "state_changed"} = m) do
    strict_keys(m, ~w(event sid state note ts))
    %{event: "state_changed", sid: m["sid"], state: m["state"], note: m["note"], ts: m["ts"]}
  end

  defp decode_event(%{"event" => "intake_rejected"} = m) do
    strict_keys(m, ~w(event exchange errors calls rejected ts))

    %{
      event: "intake_rejected",
      exchange: m["exchange"],
      errors: Enum.map(m["errors"], &error_from/1),
      calls: Enum.map(m["calls"], &call_from/1),
      rejected: source_from(m["rejected"]),
      ts: m["ts"]
    }
  end

  defp decode_event(m), do: raise(Error, "unknown journal event: #{inspect(m["event"])}")

  defp strict_keys(m, allowed) do
    case Map.keys(m) -- allowed do
      [] -> :ok
      extra -> raise Error, "unknown event fields: #{Enum.join(extra, ", ")}"
    end
  end

  defp source_from(nil), do: nil
  defp source_from(%{"path" => p, "sha256" => h}), do: %{path: p, sha256: h}

  defp error_from(%{"code" => c, "subject" => s, "detail" => d}),
    do: %{code: c, subject: s, detail: d}

  defp call_from(c) do
    %{
      n: c["n"],
      model: c["model"],
      request_id: c["request_id"],
      request_sha256: c["request_sha256"],
      response_sha256: c["response_sha256"],
      usage: %{
        input_tokens: c["usage"]["input_tokens"],
        output_tokens: c["usage"]["output_tokens"]
      },
      ts: c["ts"]
    }
  end

  ## Fold

  @doc """
  Fold the journal into state:

      %{statements: %{sid => %Statement{}},
        order: [sid],                 # journal insertion order
        chains: %{display_id => [sid]},  # revises order; the live head is last
        exchanges: [n],               # ascending
        events: [event]}              # parsed, journal order (for log)

  Folding twice yields identical state — property tested.
  """
  def fold(store) do
    content = File.read!(Path.join(store, @journal))

    events =
      content
      |> lines()
      |> Enum.with_index(1)
      |> Enum.map(fn {line, n} ->
        try do
          decode(line)
        rescue
          e in [Error, ArgumentError] ->
            reraise Error, [message: "journal line #{n}: #{Exception.message(e)}"], __STACKTRACE__
        end
      end)

    events
    |> Enum.reduce(%{statements: %{}, order: [], chains: %{}, exchanges: []}, &apply_event/2)
    |> Map.update!(:order, &Enum.reverse/1)
    |> Map.update!(:exchanges, &Enum.reverse/1)
    |> Map.new(fn
      {:chains, chains} -> {:chains, Map.new(chains, fn {k, v} -> {k, Enum.reverse(v)} end)}
      other -> other
    end)
    |> Map.put(:events, events)
  end

  defp lines(""), do: []

  defp lines(content) do
    if not String.ends_with?(content, "\n") do
      raise Error, "journal does not end with a newline (torn write?)"
    end

    content |> String.trim_trailing("\n") |> String.split("\n")
  end

  defp apply_event(%{event: "exchange_opened", exchange: n}, state) do
    if n in state.exchanges, do: raise(Error, "exchange #{n} opened twice")
    %{state | exchanges: [n | state.exchanges]}
  end

  defp apply_event(%{event: "statement_added", statement: s}, state) do
    if Map.has_key?(state.statements, s.sid), do: raise(Error, "duplicate sid #{s.sid}")

    chain = Map.get(state.chains, s.display_id, [])

    case {s.revises, chain} do
      {nil, []} -> :ok
      {nil, _} -> raise Error, "display id #{s.display_id} reused without revises"
      {old, [head | _]} when old == head -> :ok
      {old, _} -> raise Error, "revises #{old} is not the head of chain #{s.display_id}"
    end

    %{
      state
      | statements: Map.put(state.statements, s.sid, s),
        order: [s.sid | state.order],
        chains: Map.put(state.chains, s.display_id, [s.sid | chain])
    }
  end

  defp apply_event(%{event: "state_changed", sid: sid, state: new}, state) do
    case state.statements[sid] do
      nil -> raise Error, "state_changed for unknown sid #{sid}"
      s -> %{state | statements: Map.put(state.statements, sid, %{s | state: new})}
    end
  end

  defp apply_event(%{event: "intake_rejected"}, state), do: state

  ## Derived views of the fold

  @doc "The live head (last statement) of a display id's revises chain."
  def head(fold, display_id) do
    case fold.chains[display_id] do
      nil -> nil
      sids -> fold.statements[List.last(sids)]
    end
  end

  @doc "Live ratified :global defs, display-index order — what the loadout and gate read (audit B2)."
  def global_defs(fold) do
    fold.chains
    |> Enum.map(fn {_id, sids} -> fold.statements[List.last(sids)] end)
    |> Enum.filter(&(&1.type == "def" and &1.scope == "global" and &1.state == "ratified"))
    |> Enum.sort_by(&display_index/1)
  end

  @doc "Next free display index for a type — store-global, over every id ever journaled (D7)."
  def next_index(fold, type) do
    fold.chains
    |> Map.keys()
    |> Enum.filter(&String.starts_with?(&1, type <> "_"))
    |> Enum.map(fn id -> id |> String.split("_") |> List.last() |> String.to_integer() end)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp display_index(s),
    do: s.display_id |> String.split("_") |> List.last() |> String.to_integer()

  @doc """
  Regenerate `definitions.json` — a derived export of the fold,
  `{term → live ratified :global def}`, never read as authority (audit B2).
  """
  def export_definitions(store, fold) do
    defs =
      fold
      |> global_defs()
      |> Map.new(fn d ->
        {d.term, %{"display_id" => d.display_id, "sid" => d.sid, "body" => d.body}}
      end)

    File.write!(Path.join(store, @definitions), emit(defs) <> "\n")
  end
end
