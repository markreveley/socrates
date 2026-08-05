---
title: "Plan 0001 — MVP harness"
status: ratified 2026-08-05 — the first build
date: 2026-08-05
decides: language=elixir, scope=minimum-viable dogfooding loop
---

# Plan 0001 — MVP harness

**Status: `ratified` (2026-08-05). This document is the exact first build:**
run the milestones in order, satisfy the acceptance section, and stop. Sibling
plans 0002–0006 are designed but explicitly **not** part of this build.
Decisions D1–D7 below are ratified.

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
  the `{}` meta-channel), `origin` (refs: `{kind, locator}`). Under D7,
  `display_id` and `deps` are **artifact-local names**: the gate validates them
  within the proposal, and the app assigns final store-global display ids at
  acceptance, rewriting internal dep references and journaling the mapping.
- **App-stamped fields (never in the model schema):** `sid` (ULID —
  `Socrates.Sid`, ~40 lines, no dep), `exchange`, `seq`, `state`
  (`proposed | ratified | rejected | superseded`), `revises`, `author`
  (`operator | model`), `provenance`, `inserted_at`. Ref `origin.sha256` is
  computed by the app at gate time — measured, never trusted. The final
  `display_id` is likewise app-assigned at acceptance — next free index per
  type, store-global, unique for the life of the store (D7); a `revises`
  chain shares one display id, resolving to the chain's live head.
- **The loadout must pin (audit §C):** in statement bodies `*…*` is reserved
  for terms — emphasis asterisks are normalized away on entry (canon's own
  def_0 body carries `*before*` as emphasis); the API schema's subset choice
  (`anyOf` per-type shapes or permissive-plus-gate; `additionalProperties:
  false` throughout; no `minLength`/`pattern`); the definitions block in the
  system prompt carries each def's display id; model-artifact deps resolve
  against artifact-local ids ∪ global defs only — anything else dangles.

## Store

Lives at `.socrates/` in whatever repo the operator runs in — for dogfooding,
**this repo**, committed.

```
.socrates/
  journal.jsonl        # events: exchange_opened | statement_added |
                       #         state_changed | intake_rejected
  sources/<exchange>/  # verbatim prose + raw model responses, write-once
  definitions.json     # derived export: term → live ratified :global def
```

- **Deterministic serializer:** `Socrates.Journal.encode/1` owns field order
  (stdlib map key order is not guaranteed — the encoder emits fields in a fixed
  sequence). Property tests: `encode |> decode |> encode` is byte-identical;
  folding the journal twice yields identical state. `fsync` on every append.
- **State rebuild:** fold journal → `%{sid => statement}` + adjacency (deps and
  reverse-deps). Cheap at MVP scale; no cache, no index.
- **Deps are sid-edges** (D7): resolved from display ids at write time — `add`
  resolves against the store, the gate resolves model artifacts against what
  the model can see (artifact-local ids ∪ global defs). Display ids are
  view-layer.
- **`definitions.json` is a derived export** of the fold —
  `{term → latest live ratified :global def}` — regenerated on every fold and
  never read as authority: the gate and the loadout read the fold (audit B2).
  Promotion-on-amend falls out for free.

## The gate (`Socrates.Gate`)

Runs on every model proposal, and (minus the repair loop) on every human-authored
statement. Hard errors and advisory warnings are distinct.

| Code | Check |
|---|---|
| `E_ID_FORM` | `display_id` matches `^(def\|ref\|attest\|infer\|act\|did)_\d+$` and prefix equals `type` |
| `E_DUP_ID` | display_ids unique within the artifact (final ids are app-assigned, store-global — D7) |
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
- **`stop_reason` checked before parsing** (audit B3): anything but `end_turn`
  — `max_tokens` truncation (thinking counts against the cap on this model) or
  `refusal` — fails loudly: raw response archived, rejection journaled, nonzero
  exit; never fed to the gate as if complete. Transport/API failure (Req does
  not retry POSTs) exits `2` with the error on stderr.
- **Escript TLS** (audit B1): castore's CA bundle lives in a `priv/` dir
  escripts do not ship (req#299), so the client passes
  `connect_options: [transport_opts: [cacerts: :public_key.cacerts_get()]]` —
  the OS trust store, available because OTP ≥ 27 is pinned.

## Command surface

Every command prints a boundary footer: `[deterministic]` or
`[inference: model · request-id · tokens in/out]`.

**Output discipline (D6):** stdout carries only the artifact — renders, JSON,
query results — so every command pipes cleanly into ordinary Unix tooling.
The boundary footer, progress notes, and gate warnings go to **stderr**;
status goes in exit codes. Pipe-cleanliness is a guarantee, not an accident.

Deterministic: `init`, `add`, `amend`, `show`, `deps`, `rdeps`, `graph`,
`render`, `ratify`, `reject`, `verify`, `log`.
Inference: `intake`. (That is the complete list. One generative door.)

**The complete interface — every argument, flag, and output contract — is
[`spec/cli-v0.md`](../spec/cli-v0.md); worked usage with expected behavior is
[`spec/scenarios-v0.md`](../spec/scenarios-v0.md). Both are normative for this
build.** Details pinned there and binding here: store discovery is
`./.socrates` in the cwd only (`init` creates it; no ancestor walking); `add`
auto-assigns display ids (next free index per type).

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

## Module map

| Module | Responsibility |
|---|---|
| `Socrates.Statement` | struct + structural lint for one statement |
| `Socrates.Sid` | ULID generation (~40 lines, stdlib only) |
| `Socrates.Journal` | append/fold; deterministic field-order encoder; fsync |
| `Socrates.Graph` | fold output → map + adjacency; resolve, cycles (DFS), topological order (Kahn), deps/rdeps closures |
| `Socrates.Gate` | the check pipeline; structured errors and warnings |
| `Socrates.Loadout` | type list, JSON schema for the API, system-prompt assembly |
| `Socrates.Client` | behaviour; `Client.Anthropic` (Req), `Client.Fixture` (tests) |
| `Socrates.Render` | topological order, bracket notation, `⊢`; artifact to stdout |
| `Socrates.CLI` | escript `main/1`, dispatch, exit codes, stderr footers |

## Milestones

Each milestone is independently usable; later ones never break earlier surfaces.

- **M0 — scaffold.** Mix project, `spec/loadout-v0.md`, this plan ratified.
  (Canon, this plan, `spec/cli-v0.md`, and `spec/scenarios-v0.md` are already
  filed — the loadout is the remaining M0 deliverable.)
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

Under the ratified type set (D5), intake of canon #1 emits `attest_n` display
ids (model-proposed, app-finalized under D7); `claim_2` and `def_0` below name
the canon lines themselves. Scenarios
4–7 in `spec/scenarios-v0.md` are the walked form of this section — passing
them (by test harness or by hand) is passing acceptance.

1. `socrates add` the companion `def_0` (from canon) → journaled, renders.
2. `socrates intake` the canonical block. **The exact walk is
   fixture-canonical** (audit A3): under `SOCRATES_CLIENT=fixture` with the
   canned first response, the gate finds `E_TERM_UNDEF` on claim_2's coined
   term and the repair loop mints the missing def — scenario 4 verbatim. A
   **live** run passes iff intake either surfaces gate findings the repair
   loop resolves within 2 rounds, or passes clean with the coined term
   defined.
3. `ratify` all → `render` shows `⊢` on every statement; any `:global` defs
   appear in `definitions.json`.
4. `verify` passes; folding the journal twice produces identical state.
5. Forced-failure fixture → exit `1`, `rejected-*.json` on disk,
   `intake_rejected` in the journal.
6. At least one live `intake` runs **from the built escript**, not `mix` —
   the TLS path is escript-specific (audit B1; see Inference: escript TLS).

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
- **D6 — output discipline:** stdout artifact-only; footer, progress, and
  warnings to stderr; status in exit codes. **Ratified 2026-08-05.**
- **D7 — display identity is app-assigned and store-global.** Model display
  ids are artifact-local names; at acceptance the app assigns final display
  ids (next free index per type, store-global, unique for the life of the
  store), rewrites internal dep references, journals the mapping, and stores
  deps as sid-edges. A `revises` chain shares one display id, resolving to
  the live head; gate and repair messages speak the model's artifact-local
  ids. **Ratified 2026-08-05** — proposed in
  [`plans/0001-audit.md`](0001-audit.md) (option B), applied on operator
  instruction.

## Spinouts

Designed in the master thread, filed as sibling plans, **none part of this
build**:

- `0002` — statement content digests (tamper-evidence; chained verify)
- `0003` — re-prose, patches, audit, roundtrip (the build after this one)
- `0004` — acts, policy, the verifier, runtime evolution
- `0005` — neovim, then a language server
- `0006` — evals and the canary
