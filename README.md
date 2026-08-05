---
title: "socrates — charter"
date: 2026-08-05
status: pre-build
---

# socrates

A **type system for statements**, restarted from first principles.

An LLM decomposes prose into typed, dependency-linked statements. A
deterministic **gate** validates structure before anything is recorded. A human
**ratifies** meaning statement-by-statement. The invariant that everything else
serves: *models emit data, the gate stands between data and effect, and only the
operator changes a statement's state.*

This repo succeeds `ob6to8/socrates`, which incubated the v1 vocabulary and the
founding thread. Nothing from v1 is imported; the language regrows from one
canonical example, through use, with each addition ratified and journaled.

## Layout

- [`canon/`](canon/representation-ratification.md) — the canonical example
  (operator-authored, verbatim) that seeds the v2 language, and doubles as the
  harness acceptance fixture.
- [`plans/0001-mvp-harness.md`](plans/0001-mvp-harness.md) — the MVP build
  plan: Elixir harness, gate, journal, ratification loop. **Status: proposed,
  awaiting operator ratification.**
- `spec/` — the loadout (language definition) — arrives with M0.
- `.socrates/` — the dogfood store, once the harness exists: socrates built
  with socrates, journaled in its own repo.

## Lineage

The name stays socrates — the elenchus attacks unearned confidence in one's own
understanding, which is the purpose of this system. The components carry their
own ancestors: the ratified glyph `⊢` is Frege's judgment stroke; the
zero-network `verify` command follows the de Bruijn criterion (a small, dumb,
independent checker); the journal is a scorebook of commitments in Brandom's
sense. Writing that can be interrogated — `deps`, `rdeps` — is the answer to
Socrates' own objection, in the *Phaedrus*, that written words stay silent when
questioned.
