---
title: "socrates — charter"
date: 2026-08-05
status: pre-build — plan 0001 ratified, build next
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

Explanatory (non-normative): [docs/](docs/README.md) — purpose and
architecture in plain words, plus a research spike testing the core claims
against outside evidence.

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
