defmodule Socrates.Statement do
  @moduledoc """
  One statement: the struct, its structural lint, and its canonical
  (de)serialization pairs — field order is owned here so `Socrates.Journal`'s
  encoder stays deterministic.

  Types, scopes, states, and authors are strings (JSON-native; the journal is
  canonical). `deps` holds sids — deps are sid-edges, resolved from display
  ids at write time (D7); display ids are view-layer.
  """

  alias Socrates.Loadout

  defstruct sid: nil,
            display_id: nil,
            artifact_id: nil,
            type: nil,
            term: nil,
            scope: nil,
            origin: nil,
            body: nil,
            deps: [],
            notes: [],
            exchange: nil,
            seq: nil,
            state: nil,
            revises: nil,
            author: nil,
            provenance: nil,
            inserted_at: nil

  @statement_fields ~w(sid display_id artifact_id type term scope origin body deps notes exchange seq state revises author provenance inserted_at)

  @doc """
  Structural lint of one statement's own shape (store-independent).
  Returns `{errors, warnings}` as `%{code, subject, detail}` maps; `subject`
  is the statement's display id when it has one, else its type.
  """
  def lint(%__MODULE__{} = s) do
    subject = s.display_id || s.artifact_id || s.type
    {shape_errors(s, subject), warnings(s, subject)}
  end

  defp shape_errors(%{type: "def"} = s, subject) do
    if s.scope in Loadout.scopes() do
      []
    else
      [error("E_DEF_NO_SCOPE", subject, "defs declare local or global")]
    end
  end

  defp shape_errors(%{type: "ref"} = s, subject) do
    case s.origin do
      %{kind: kind} ->
        if kind in Loadout.origin_kinds() do
          []
        else
          [error("E_REF_NO_ORIGIN", subject, "unknown origin kind #{kind}")]
        end

      _ ->
        [error("E_REF_NO_ORIGIN", subject, "refs carry an origin (kind:locator)")]
    end
  end

  defp shape_errors(_s, _subject), do: []

  defp warnings(%{type: "def", body: body}, subject) when is_binary(body) do
    cond do
      Regex.match?(~r/[.!?]\s+\S/, body) ->
        [error("W_DEF_ATOMICITY", subject, "def body reads multi-sentence")]

      String.contains?(body, "; ") ->
        [error("W_DEF_ATOMICITY", subject, "def body reads clause-conjoined")]

      true ->
        []
    end
  end

  defp warnings(_s, _subject), do: []

  defp error(code, subject, detail), do: %{code: code, subject: subject, detail: detail}

  @doc "Every `*term*` span used in a body (the reserved surface — loadout-v0)."
  def terms_in(body) when is_binary(body) do
    ~r/\*([^*\n]+)\*/
    |> Regex.scan(body, capture: :all_but_first)
    |> Enum.map(fn [t] -> t end)
    |> Enum.uniq()
  end

  @doc "Canonical field order as `{key, value}` pairs, nils skipped by the encoder."
  def to_pairs(%__MODULE__{} = s) do
    [
      {"sid", s.sid},
      {"display_id", s.display_id},
      {"artifact_id", s.artifact_id},
      {"type", s.type},
      {"term", s.term},
      {"scope", s.scope},
      {"origin", origin_pairs(s.origin)},
      {"body", s.body},
      {"deps", s.deps},
      {"notes", s.notes},
      {"exchange", s.exchange},
      {"seq", s.seq},
      {"state", s.state},
      {"revises", s.revises},
      {"author", s.author},
      {"provenance", provenance_pairs(s.provenance)},
      {"inserted_at", s.inserted_at}
    ]
  end

  defp origin_pairs(nil), do: nil

  defp origin_pairs(o),
    do: {:obj, [{"kind", o.kind}, {"locator", o.locator}, {"sha256", o[:sha256]}]}

  defp provenance_pairs(nil), do: nil

  defp provenance_pairs(%{calls: calls}) do
    {:obj, [{"calls", Enum.map(calls, &call_pairs/1)}]}
  end

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

  @doc "Strict decode from a journal map — unknown fields are a hard error."
  def from_map(%{} = m) do
    case Map.keys(m) -- @statement_fields do
      [] -> :ok
      extra -> raise ArgumentError, "unknown statement fields: #{Enum.join(extra, ", ")}"
    end

    %__MODULE__{
      sid: m["sid"],
      display_id: m["display_id"],
      artifact_id: m["artifact_id"],
      type: m["type"],
      term: m["term"],
      scope: m["scope"],
      origin: origin_from(m["origin"]),
      body: m["body"],
      deps: m["deps"] || [],
      notes: m["notes"] || [],
      exchange: m["exchange"],
      seq: m["seq"],
      state: m["state"],
      revises: m["revises"],
      author: m["author"],
      provenance: provenance_from(m["provenance"]),
      inserted_at: m["inserted_at"]
    }
  end

  defp origin_from(nil), do: nil

  defp origin_from(%{} = o) do
    case Map.keys(o) -- ~w(kind locator sha256) do
      [] -> :ok
      extra -> raise ArgumentError, "unknown origin fields: #{Enum.join(extra, ", ")}"
    end

    %{kind: o["kind"], locator: o["locator"], sha256: o["sha256"]}
  end

  defp provenance_from(nil), do: nil

  defp provenance_from(%{"calls" => calls}) do
    %{
      calls:
        Enum.map(calls, fn c ->
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
        end)
    }
  end
end
