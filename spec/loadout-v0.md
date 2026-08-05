---
title: "Loadout v0 — the seed language"
status: authored at M0 of the 0001 build; normative for v0; carries the pins required by plan 0001 → loadout and audit §C
date: 2026-08-05
---

# Loadout v0

The v0 language, seeded from `canon/representation-ratification.md` under the
ratified type set (D5). This document is the prose form;
`Socrates.Loadout` carries the same facts as data — the type list, the JSON
schema sent to the API, and the system prompt assembly. Where the two could
diverge, the module is what runs and this document is what the operator
ratified; a divergence is a defect in one of them.

## Types

Six types, ratified 2026-08-05 (D5). `attest` / `infer` / `act` / `did` carve
at functional roles; `def` and `ref` are machinery types.

| Type | Role |
|---|---|
| `def` | a ratified stipulation: coins a *term* |
| `ref` | an anchored pointer to something outside the graph |
| `attest` | an assertion offered as holding — facts, reports, first-person wants |
| `infer` | a conclusion drawn from its deps |
| `act` | a prescription — something to do, bridged from attested wants |
| `did` | a record of something done |

**Implicit-conjunction rule (ratified):** multiple deps bind jointly — a
statement depending on `(attest_1, attest_2)` takes both as premises — so
conjunction-only statements decompose away.

**Growth rule:** a new type is a loadout edit made through use — proposed,
ratified, journaled. The v1 vocabulary is deliberately not imported.

## Fields

**Model-suppliable** (the complete schema surface; anything else in a model
artifact is a schema violation):

| Field | On | Content |
|---|---|---|
| `display_id` | all | `<type>_<n>`, artifact-local (D7) |
| `type` | all | one of the six |
| `body` | all | the statement text |
| `deps` | all | list of display ids (may be empty) |
| `notes` | all | list of strings — the `{}` meta-channel (may be empty) |
| `term` | `def` | the coined term, without asterisks |
| `scope` | `def` | `local` \| `global` |
| `origin` | `ref` | `{kind: file \| url \| exchange \| quote, locator}` |

**App-stamped, never in the model schema:** `sid`, `exchange`, `seq`, `state`,
`revises`, `author`, `provenance`, `inserted_at`, ref `origin.sha256`
(computed by the app at gate time — measured, never trusted), and the final
`display_id` (app-assigned at acceptance, store-global, next free index per
type — D7). The model's output schema has no state field: models emit data;
only the operator changes state.

## The term rule (pin: audit C1)

In statement bodies, `*…*` is **reserved for terms**. A span `*x*` is a use
of the term `x` and nothing else. Consequences:

- **Emphasis is normalized away on entry.** Entry-side rule, binding on every
  author: emphasis asterisks in source material are dropped by whoever enters
  the statement — the operator at `add`, the model at decomposition (canon's
  own def_0 body carries `*before*` as emphasis; it enters as `before`). The
  app never strips asterisks itself: it cannot tell emphasis from terms, which
  is why the surface is reserved.
- The term scanner reads every `*…*` span in a body as a term usage.
  `E_TERM_UNDEF` fires for any term with no def in scope. A `{coinable}` note
  is an IOU; the gate refuses IOUs.
- Term matching is exact string equality between the span's content and a
  def's `term` field, after entry normalization. No case folding, no stemming.
- Unclosed or asymmetric delimiters (canon claim_2's `*…"`) do not scan as
  terms; only a symmetric re-emission makes the term findable. This is a known
  property, not a defect: the scanner parses the reserved surface, nothing
  more.

## The API schema (pin: audit C2)

The schema sent with every intake, from `Socrates.Loadout.schema/0`. The
subset choice is **`anyOf` per-type shapes** — a discriminated union, one
branch per type — rather than one permissive shape:

- The artifact is `{"statements": [<statement>, …]}` — one object, one
  required key, `additionalProperties: false`.
- Each statement matches exactly one of six branches. The discriminant is
  `type`, a single-value `enum` per branch.
- Per-branch required fields: every branch requires `display_id`, `type`,
  `body`, `deps`, `notes` (empty lists allowed for the last two); the `def`
  branch additionally requires `term` and `scope`; the `ref` branch
  additionally requires `origin` (`kind`, `locator`, both required).
- `additionalProperties: false` on **every** object, `origin` included.
- Closed sets (`type`, `scope`, `origin.kind`) are `enum`s.
- **No `minLength`, no `pattern`, no numeric constraints** — the structured
  output subset does not support them. Form constraints the schema cannot
  carry (`display_id` shape, non-empty bodies, term coverage, dep resolution,
  acyclicity) are the gate's job; the gate re-checks everything the schema
  states anyway. Server-side constrained generation is an optimization, never
  the authority.

## What the model sees (pin: audit C3)

The system prompt is loadout + current definitions, nothing else — assembled
by `Socrates.Loadout.system_blocks/1` as an array of two text blocks:

1. **The loadout spec block** — the v0 language taught to the model: types,
   field rules, the term rule, dep scope, the repair protocol.
2. **The definitions block** — the store's live ratified `:global` defs, one
   line each, **carrying each def's display id**:

   ```
   Ratified global definitions (dep on them by display id):
   [def_1] *representation ratification*: the operator verifying the agent's socrates rendering of operator intent before any work is done
   ```

   (`(none yet)` when the store has none.) The display id is load-bearing:
   without it the model can neither dep on `def_1` nor avoid minting a
   colliding def.

`cache_control: {"type": "ephemeral"}` is set on the last block, per plan
0001 → Inference. The user turn is the source prose, verbatim.

## Dep scope (pin: audit C3)

Model-artifact deps resolve against **artifact-local display ids ∪ the global
defs listed in the definitions block** — exactly what the model can see.
Anything else dangles (`E_DANGLING_DEP`): a dep that only resolves against
store statements the model never saw is a hallucination and is treated as
one. Artifact display ids must not reuse a listed global def's display id;
the gate reports such reuse as `E_DUP_ID`.

(Operator writes are broader by design — the operator sees the store, so
`add`/`amend` deps resolve against any live statement in it. The human is
direct; the model petitions.)

## The repair protocol

On hard gate errors, the follow-up user turn is the structured error list,
JSON-encoded: `{"gate_errors": [{"code", "subject", "detail"}, …]}` — codes
from the gate table, `subject` the artifact-local display id (the ids the
model can follow). The model re-emits the **complete corrected artifact** —
every statement, not a diff — against the same schema. At most 2 repair
turns; then the run fails loudly (exit 1, rejected artifact archived,
`intake_rejected` journaled).
