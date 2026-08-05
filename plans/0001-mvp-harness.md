---
title: "Plan 0001 — MVP harness"
status: proposed
date: 2026-08-05
decides: language=elixir, scope=minimum-viable dogfooding loop
---

# Plan 0001 — MVP harness

**Status: `proposed`.** In keeping with the system this plan describes, it does not
build itself: the operator ratifies (or amends) it, then implementation begins.
Open decisions are collected at the bottom as D1–D4.

This document is self-contained — implementable without access to the thread that
produced it. Context in one paragraph: socrates is a type system for statements.
An LLM decomposes prose into typed, dependency-linked statements; a deterministic
**gate** validates structure before anything is recorded; a human **ratifies**
meaning statement-by-statement. The model proposes; only the app writes; only the
operator changes a statement's state. The notation is a view — canonical data is
JSON in an append-only journal.

## Objective

The smallest system that lets the operator **start building socrates with
socrates**: author statements directly, decompose prose through one gated
inference path, inspect the graph deterministically, ratify/reject — everything
journaled with provenance. Nothing else.

## Ground rules (non-negotiable, from the design)

1. **Inference/determinism boundary.** Every command is either a pure function
   over the store or an explicitly-marked inference call. Model output is data;
   it reaches the store only through the gate.
2. **Append-only.** Statements are immutable. Change is supersession (a new
   statement with a `revises` edge), never mutation. The journal is never
   rewritten.
3. **Operator-only state.** `proposed → ratified | rejected` transitions exist
   solely as operator commands. The model's output schema has no state field.
4. **Human writes are first-class and ungated.** Operator-authored statements
   enter directly (structural lint only, no inference, no repair loop). The
   human is direct; the model petitions.
5. **Provenance on every inference.** Request-body digest, model id, request id,
   token usage, timestamp — journaled.
6. **Verbatim surfaces are write-once.** Source prose and raw model responses
   are archived byte-exact with digests and never regenerated.

## Runtime

- **Elixir**, pinned **≥ 1.18 / OTP ≥ 27** (stdlib `JSON` module — no JSON dep).
- **One dependency: `req`** (HTTP). Everything else stdlib. No SDK: the request
  body is hand-assembled, so the provenance digest covers exactly the bytes sent.
- **Distribution: escript** — `mix escript.build` → a single `socrates`
  executable (host needs Erlang). CLI is per-invocation: read journal → act →
  append → exit. No server, no locks, no OTP processes in the MVP (single
  operator, sequential use).

## The loadout (v0 language)

Seeded from `canon/representation-ratification.md`, conservatively. The loadout
does not exist yet — it is the first M0 deliverable, written as
`spec/loadout-v0.md` (prose for humans) plus a module
(`Socrates.Loadout`) that carries the same facts as data: the type list, the
JSON schema sent to the API, and the system prompt assembly.

- **Types: `def`, `ref`, `attest`, `infer`, `act`, `did`.** Ratified
  2026-08-05 from the two canonical examples: `attest`/`infer`/`act`/`did`
  carve at functional roles (assert / conclude / prescribe / record); `def` and
  `ref` remain machinery types (ratified stipulations; anchored pointers). The
  first canon example's `[claim_n]` statements read as `attest` under this set.
  **Implicit-conjunction rule (ratified):** multiple deps bind jointly, so
  conjunction-only statements decompose away. The v1 vocabulary is deliberately
  *not* imported. **Growth rule:** a new type is a loadout edit made through
  use — proposed, ratified, journaled — the naive-emergence method, this time
  with a record.
- **Model-suppliable fields:** `display_id`, `type`, `body`, `term` (defs),
  `scope` (defs: `local | global`), `deps` (list of display_ids), `notes` (list;
  the `{}` meta-channel), `origin` (refs: `{kind, locator}`).
- **App-stamped fields (never in the model schema):** `sid` (ULID —
  `Socrates.Sid`, ~40 lines, no dep), `exchange`, `seq`, `state`
  (`proposed | ratified | rejected | superseded`), `revises`, `author`
  (`operator | model`), `provenance`, `inserted_at`. Ref `origin.sha256` is
  computed by the app at gate time — measured, never trusted.

## Store

Lives at `.socrates/` in whatever repo the operator runs in — for dogfooding,
**this repo**, committed.

```
.socrates/
  journal.jsonl        # events: exchange_opened | statement_added |
                       #         state_changed | intake_rejected
  sources/<exchange>/  # verbatim prose + raw model responses, write-once
  definitions.json     # :global defs, promoted on ratification
```

- **Deterministic serializer:** `Socrates.Journal.encode/1` owns field order
  (stdlib map key order is not guaranteed — the encoder emits fields in a fixed
  sequence). Property tests: `encode |> decode |> encode` is byte-identical;
  folding the journal twice yields identical state. `fsync` on every append.
- **State rebuild:** fold journal → `%{sid => statement}` + adjacency (deps and
  reverse-deps). Cheap at MVP scale; no cache, no index.

## The gate (`Socrates.Gate`)

Runs on every model proposal, and (minus the repair loop) on every human-authored
statement. Hard errors and advisory warnings are distinct.

| Code | Check |
|---|---|
| `E_ID_FORM` | `display_id` matches `^(def\|ref\|attest\|infer\|act\|did)_\d+$` and prefix equals `type` |
| `E_DUP_ID` | display_ids unique within the exchange |
| `E_DANGLING_DEP` | every dep resolves to an existing statement |
| `E_CYCLE` | dependency graph is acyclic (DFS; the cycle path is printed) |
| `E_TERM_UNDEF` | every `*term*` used in a body has a def in scope or in the definitions file |
| `E_DEF_NO_SCOPE` | defs declare `local` or `global` |
| `E_REF_NO_ORIGIN` | refs carry an origin; app resolves and hashes local files |
| `W_DEF_ATOMICITY` | *warning:* def body is multi-sentence or clause-conjoined |

**Repair loop:** on hard errors, the structured error list goes back to the model
as a follow-up turn — at most **2** retries — then the run fails loudly: nonzero
exit, rejected artifact saved to `sources/<exchange>/rejected-<n>.json`, an
`intake_rejected` event journaled. Never silently accepted. Rejected artifacts
are kept: they are the free eval corpus.

Because deps resolve and the graph is acyclic, a topological order provably
exists — "definitions first" is computed by the renderer, not requested of the
model.

## Inference (`Socrates.Client`)

A behaviour with two implementations: `Anthropic` (live, via Req) and `Fixture`
(canned responses; all tests except one optional live smoke test run against it).

Request shape (hand-assembled):

- `POST https://api.anthropic.com/v1/messages`, headers `x-api-key`
  (`ANTHROPIC_API_KEY`), `anthropic-version: 2023-06-01`.
- `model: "claude-opus-5"`, `max_tokens: 16000`, `thinking` omitted (on by
  default for this model). Generous receive timeout (≥ 5 min).
- `system`: array of blocks — loadout spec + current definitions — with
  `cache_control: {"type": "ephemeral"}` on the last block (repeat invocations
  pay ~10% for the stable prefix).
- `output_config: {format: {type: "json_schema", schema: <from Loadout>}}` with
  `additionalProperties: false` — generation is constrained server-side; the
  gate re-checks everything anyway.
- **Provenance recorded per call:** sha256 of the exact request body bytes,
  `request-id` response header, `usage`, model, timestamp.

## Command surface

Every command prints a boundary footer: `[deterministic]` or
`[inference: model · request-id · tokens in/out]`.

Deterministic: `add`, `amend`, `show`, `deps`, `rdeps`, `graph`, `render`,
`ratify`, `reject`, `verify`, `log`.
Inference: `intake`. (That is the complete list. One generative door.)

- `add` — operator authors a statement directly (flags or stdin). Lint only,
  journaled with `author: operator`. Operator statements enter `ratified`
  directly — authorship is assent; only model proposals wait in `proposed`.
  **Lands before `intake` exists** — see M1.
- `amend <id>` — operator authors a replacement; new statement + `revises` edge;
  old statement → `superseded`. The human edit path, journaled, attributed.
- `intake <file|->` — archive source verbatim (digest recorded) → one client
  call → gate + repair loop → journal as `proposed` → render.
- `ratify | reject <ids…>` — state transitions. Ratifying a `:global` def
  promotes it into `definitions.json`.
- `render [selector]` — topological order, defs/refs first, bracket notation;
  ratified statements carry the `⊢` prefix (D4); notes dimmed; footer lists
  what the gate checked.
- `verify` — re-hash `sources/**` and every ref origin; nonzero on any mismatch.
  Zero network, zero inference — the kernel property.
- Selectors (minimal): explicit ids, `id+deps`, `id+rdeps`, `@exchange`.
- Exit codes: `0` ok · `1` gate-rejected after retries · `2` usage error ·
  `3` verify mismatch.

## Milestones

Each milestone is independently usable; later ones never break earlier surfaces.

- **M0 — scaffold.** Mix project, `spec/loadout-v0.md`, this plan ratified.
  (Canon and plan are already filed.)
- **M1 — the pen.** `Statement`, `Sid`, `Journal`, and `add / show / render /
  log`. **Dogfooding starts here, with no API key:** the operator can begin
  authoring socrates-in-socrates directly. The human write path ships before
  the model write path — deliberately.
- **M2 — the graph.** `Graph`, `Gate`, `deps / rdeps / graph / verify`,
  `ratify / reject`, the `⊢` render. Human-authored statements now fully
  linted; circular reasoning now a mechanical error.
- **M3 — the gate in anger.** `Client` (behaviour + both impls), `intake`,
  repair loop, source archiving, provenance. The one generative door opens.
- **M4 — finish.** `amend`, definitions promotion, escript packaging, acceptance
  run below, README updated with usage.

## Acceptance — the canonical example is the test

1. `socrates add` the companion `def_0` (from canon) → journaled, renders.
2. `socrates intake` the canonical block → the gate must find **exactly**
   `E_TERM_UNDEF` on claim_2's coined term (and `E_DANGLING_DEP` for `def_0` if
   step 1 is skipped). The repair loop either mints the missing def or fails
   visibly with the artifact saved.
3. `ratify` all → `render` shows `⊢` on every statement; any `:global` defs
   appear in `definitions.json`.
4. `verify` passes; folding the journal twice produces identical state.
5. Forced-failure fixture → exit `1`, `rejected-*.json` on disk,
   `intake_rejected` in the journal.

## Non-goals (MVP)

re-prose · patches/compile · audit/changesets · roundtrip · verifier model ·
acts/policy table · nvim · LSP · GenServer store ownership · streaming ·
multi-loadout switching · elixir-mind coupling. All designed, none built here.

## Decisions

- **D1 — `req` as the sole dependency.** **Ratified 2026-08-05.**
- **D2 — escript distribution.** **Ratified 2026-08-05.**
- **D3 — pin Elixir ≥ 1.18 / OTP ≥ 27** for stdlib JSON. **Ratified 2026-08-05.**
- **D4 — `⊢` as the ratified glyph.** **Ratified 2026-08-05, display-only:**
  the glyph exists solely in renderer output. The journal stores
  `"state": "ratified"`; the operator types `socrates ratify <id>`, never the
  glyph; nothing ever parses it. (`--ascii` render flag may fall back to `|-`.)

- **D5 — type set `def / ref / attest / infer / act / did`**, plus the
  implicit-conjunction rule, from the operator's practical-syllogism example
  (`canon/practical-syllogism.md`, now canonical). **Ratified 2026-08-05.**
  The loadout section above reflects it.
