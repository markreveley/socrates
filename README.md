---
title: "socrates — charter"
date: 2026-08-05
status: plan 0001 built — MVP harness usable, acceptance walked
---

# socrates

A **type system for statements**. An LLM decomposes prose into typed,
dependency-linked statements; a deterministic **gate** validates structure
before anything is recorded; a human **ratifies** meaning
statement-by-statement. The invariant everything serves: *models emit data, the
gate stands between data and effect, and only the operator changes a
statement's state.*

## Purpose

In the operator's words — the full passages, mechanically extracted and
byte-verified, are in [`canon/purpose.md`](canon/purpose.md):

<!-- verbatim: master-thread -->
> what i am trying to do is build a system that takes longer to use and is less powerful, so that you are forced to move at the pace of approvals and ratification after proper comprehension. socrates is not as fun to read as prose. that's partially the point

The system re-denominates velocity: the unit of progress is statements
ratified — comprehension events — not tokens generated.

## Architecture — four layers

1. **The language** — types, fields, notation: the loadout (`spec/` — the CLI
   reference and scenarios are filed; the loadout itself lands at M0).
   Ratified type set: `def / ref / attest / infer / act / did`.
2. **The store** — an append-only journal plus write-once verbatim sources
   (`.socrates/`). The notation is a view; the JSON is canonical.
3. **The gate** — the language compiled into executable checks: the compiler
   front-end prose never had.
4. **The harness** — orchestration: assembles context, calls the model, runs
   the gate, writes the store, drives surfaces (CLI first; nvim and LSP are
   designed in plan 0005).

Writes are asymmetric by design: operator statements enter directly (`add` —
lint only; authorship is assent), while model output enters only through the
gate, as `proposed`, and waits. The human is direct; the model petitions.

## Usage

Build (Elixir ≥ 1.18 / OTP ≥ 27; the host running the escript needs only
Erlang):

```
mix deps.get && MIX_ENV=prod mix escript.build   # → ./socrates
```

Every command operates on `./.socrates` in the current directory and prints
a boundary footer on stderr — `[deterministic]`, or `[inference: <model> ·
<request-id> · <n> in / <m> out]` for the one generative door. stdout
carries only the artifact (D6): renders pipe clean. Exit codes: `0` ok ·
`1` gate-rejected · `2` usage/environment · `3` verify mismatch. The
complete interface is [`spec/cli-v0.md`](spec/cli-v0.md); worked walks with
exact expected output are [`spec/scenarios-v0.md`](spec/scenarios-v0.md).

```
socrates init                         # create the store; opens exchange 1
socrates add --type attest --body "apples are fruits"
socrates add --type infer --dep attest_1 --dep attest_2 --body "…"
socrates amend attest_1 --body "…"    # supersession, never mutation
socrates show attest_1                # full record
socrates deps act_1 --all             # dependencies (transitive)
socrates rdeps attest_1               # dependents
socrates graph                        # indented dependency tree
socrates render                       # ⊢-marked bracket notation, topological
socrates intake prose.txt             # the one inference command (gated)
socrates ratify def_2 attest_4        # operator-only state transitions
socrates reject attest_5 --note "…"
socrates verify                       # re-hash archives + ref origins; no network
socrates log --limit 10               # journal events, newest last
```

`intake` needs `ANTHROPIC_API_KEY` (model default `claude-opus-5`, override
with `SOCRATES_MODEL`); `SOCRATES_CLIENT=fixture` selects the canned client —
honest provenance, no key, no network — which is how every test and the
acceptance walk runs. Operator statements enter `ratified`; model proposals
wait as `proposed` (no `⊢`) until `ratify`/`reject`. Ratifying a `:global`
def promotes it into `definitions.json`, a derived export of the journal
fold. Build decisions the specs left open are logged in
[`plans/0001-build-notes.md`](plans/0001-build-notes.md), proposed for
ratification.

## Map

| Plan | Through-line | Status |
|---|---|---|
| [0001](plans/0001-mvp-harness.md) | the MVP harness — gate, journal, ratification loop | **ratified — the first build** |
| [0002](plans/0002-statement-digests.md) | tamper-evidence: statement digests, chained verify | deferred |
| [0003](plans/0003-composition-and-measurement.md) | re-prose, patches, audit, roundtrip | proposed — next after 0001 |
| [0004](plans/0004-agency.md) | acts, policy, the verifier, runtime evolution | deferred |
| [0005](plans/0005-surfaces.md) | neovim, then a language server | deferred |
| [0006](plans/0006-instrumentation.md) | evals and the canary | deferred |

Canon (operator-authored, verbatim, annotated):
[purpose](canon/purpose.md) ·
[representation-ratification](canon/representation-ratification.md) — the seed
example and acceptance fixture ·
[practical-syllogism](canon/practical-syllogism.md) — settled the type set.

The session all of this descends from is captured verbatim as the **master
thread** at `direction → socrates_2/threads/2026-08-05-master-thread.md`. This
repo succeeds `ob6to8/socrates` (v1); nothing from v1 is imported — the
language regrows from canon, through use, each addition ratified and
journaled.

## Lineage

The name stays socrates — the elenchus attacks unearned confidence in one's own
understanding, which is the purpose of this system. The components carry their
own ancestors: the ratified glyph `⊢` is Frege's judgment stroke; the
zero-network `verify` command follows the de Bruijn criterion (a small, dumb,
independent checker); the journal is a scorebook of commitments in Brandom's
sense. Writing that can be interrogated — `deps`, `rdeps` — is the answer to
Socrates' own objection, in the *Phaedrus*, that written words stay silent when
questioned.
