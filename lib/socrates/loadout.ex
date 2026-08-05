defmodule Socrates.Loadout do
  @moduledoc """
  The v0 language as data: the type list, the JSON schema sent to the API,
  and the system prompt assembly. Prose twin: `spec/loadout-v0.md` — the pins
  (term rule, schema subset, definitions block display ids, dep scope) live
  there; this module is the executable form.
  """

  @types ~w(def ref attest infer act did)
  @scopes ~w(local global)
  @origin_kinds ~w(file url exchange quote)

  def types, do: @types
  def scopes, do: @scopes
  def origin_kinds, do: @origin_kinds

  @doc "display_id form: prefix must equal the statement's type (E_ID_FORM)."
  def id_pattern, do: ~r/^(def|ref|attest|infer|act|did)_(\d+)$/

  @doc """
  The artifact schema for structured output: anyOf per-type shapes
  (audit C2 — additionalProperties: false everywhere; enums for closed sets;
  no minLength/pattern/numeric constraints; the gate re-checks everything).
  """
  def schema do
    %{
      "type" => "object",
      "properties" => %{
        "statements" => %{
          "type" => "array",
          "items" => %{"anyOf" => Enum.map(@types, &statement_shape/1)}
        }
      },
      "required" => ["statements"],
      "additionalProperties" => false
    }
  end

  defp statement_shape(type) do
    base = %{
      "display_id" => %{"type" => "string"},
      "type" => %{"enum" => [type]},
      "body" => %{"type" => "string"},
      "deps" => %{"type" => "array", "items" => %{"type" => "string"}},
      "notes" => %{"type" => "array", "items" => %{"type" => "string"}}
    }

    {props, required} =
      case type do
        "def" ->
          {Map.merge(base, %{
             "term" => %{"type" => "string"},
             "scope" => %{"enum" => @scopes}
           }), ["display_id", "type", "term", "scope", "body", "deps", "notes"]}

        "ref" ->
          {Map.put(base, "origin", %{
             "type" => "object",
             "properties" => %{
               "kind" => %{"enum" => @origin_kinds},
               "locator" => %{"type" => "string"}
             },
             "required" => ["kind", "locator"],
             "additionalProperties" => false
           }), ["display_id", "type", "origin", "body", "deps", "notes"]}

        _ ->
          {base, ["display_id", "type", "body", "deps", "notes"]}
      end

    %{
      "type" => "object",
      "properties" => props,
      "required" => required,
      "additionalProperties" => false
    }
  end

  @doc """
  System prompt assembly: loadout spec + current definitions, with
  cache_control ephemeral on the last block (plan 0001 → Inference).
  `definitions` is a list of `%{display_id, term, body}` maps — the store's
  live ratified :global defs, in display-index order.
  """
  def system_blocks(definitions) do
    [
      %{"type" => "text", "text" => spec_text()},
      %{
        "type" => "text",
        "text" => definitions_block(definitions),
        "cache_control" => %{"type" => "ephemeral"}
      }
    ]
  end

  @doc "The definitions block carries each def's display id (audit C3)."
  def definitions_block(definitions) do
    header = "Ratified global definitions (dep on them by display id):"

    case definitions do
      [] ->
        header <> "\n(none yet)"

      defs ->
        lines =
          Enum.map(defs, fn d ->
            "[#{d.display_id}] *#{d.term}*: #{d.body}"
          end)

        Enum.join([header | lines], "\n")
    end
  end

  @doc "The loadout spec block — the v0 language taught to the model."
  def spec_text do
    """
    You are the decomposition engine of socrates, a type system for
    statements. Decompose the operator's prose into typed, dependency-linked
    statements, returned as JSON conforming to the provided schema. You emit
    data only: you cannot write to the store, and every statement you emit
    enters as a proposal awaiting operator ratification.

    Types:
    - def: a ratified stipulation that coins a term. Fields: term (the term
      text, without asterisks), scope ("local" to this artifact's context, or
      "global"), body (the definition — one atomic sentence).
    - ref: an anchored pointer to something outside the graph. Field: origin,
      as {kind, locator} with kind one of file, url, exchange, quote.
    - attest: an assertion offered as holding — facts, reports, first-person
      wants (a desire report is an attestation about the speaker).
    - infer: a conclusion drawn from its deps.
    - act: a prescription — something to do; its deps should trace to an
      attested want, not to facts alone.
    - did: a record of something done.

    Rules:
    - display_id is <type>_<n> (for example attest_1), unique within this
      artifact. Display ids are artifact-local names; the store assigns final
      ids at acceptance. Never reuse the display id of a global definition
      listed below.
    - deps is a list of display ids. A dep may name a statement of this
      artifact or a global definition listed below. Nothing else resolves.
    - Multiple deps bind jointly (implicit conjunction). Do not emit
      conjunction-only statements; depend on the conjuncts directly.
    - The dependency graph must be acyclic.
    - In bodies, asterisks are reserved for terms: *term* marks a use of a
      defined term, and every term used must have a def in this artifact or
      among the global definitions. Never use asterisks for emphasis; drop
      emphasis asterisks present in the source. A coined term without a def
      is refused by the gate.
    - notes is the meta-channel: annotations about a statement that are not
      part of its content. Notes carried inline in the source (in braces)
      belong in the notes field, not in the body.
    - Decompose faithfully: preserve the source's wording where it is already
      statement-shaped; do not invent content the source does not carry;
      strip inline notation artifacts (bracketed ids, parenthesized dep
      lists) from bodies — the deps field replaces them.

    If a follow-up turn delivers gate errors, as JSON of the form
    {"gate_errors": [{"code", "subject", "detail"}, ...]}, re-emit the
    complete corrected artifact: every statement, not a diff.
    """
  end
end
