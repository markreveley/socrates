---
title: "Plan 0002 — statement content digests"
status: deferred — implement after plan 0001's milestones
date: 2026-08-05
spun-out-from: plans/0001-mvp-harness.md
---

# Plan 0002 — statement content digests

**Status: `deferred`.** Spun out of plan 0001 on 2026-08-05. Implement after
the MVP (M0–M4) lands; nothing in the MVP depends on it, and adding it later
touches only `Journal.encode/1` and `verify`.

## Objective

Extend zero-network verification from sources and ref origins to **every
statement in the journal**: tamper-evidence for the whole record, computable by
a small, dumb, independent checker — the de Bruijn kernel property,
journal-wide.

## Context

Prompted by the convergent design in `llm` v0.32's content-addressed message
store (Git-modeled, hash-deduplicated). Full content-addressing is the wrong
identity scheme for socrates — two identical bodies in different exchanges must
not share identity, and `revises` chains want stable ids — so `sid` remains a
ULID. This plan takes the tamper-evidence half only.

## Design

- New app-stamped field on every statement: `digest` — sha256 over the
  statement's **canonical serialization** (the deterministic `Journal.encode/1`
  byte form) of its immutable fields: `sid`, `exchange`, `seq`, `type`,
  `display_id`, `body`, `term`, `scope`, `deps`, `notes`, `origin`, `revises`,
  `author`, `inserted_at`, and provenance. Excluded: `state` (state lives in
  separate `state_changed` events; the statement record itself never mutates)
  and the `digest` field itself.
- `verify` re-computes every statement's digest from the journaled bytes and
  fails nonzero on any mismatch, alongside the existing source and ref-origin
  checks. Still zero network, zero inference, stdlib-only hashing.
- Digest computation lives beside the serializer so the two cannot drift:
  property test — decode → re-encode → re-hash equals the stored digest for
  every event in a journal.
- Idempotence side benefit: identical re-`add`s are detectable (same digest,
  different sid) and can warn.

## Open questions (resolve at implementation)

1. **Event-level hash chaining** — should each journal event also carry a hash
   of the previous event (a tamper-evident chain, Git-log style), or is
   per-statement digesting sufficient? Chaining detects deletion and
   reordering, not just mutation; it also makes partial journal truncation
   evident. Likely worth it; decide when implementing.
2. **Backfill** — journals written before this plan lack digests. `verify`
   should treat missing digests as a warning with a `socrates migrate` command
   to backfill (an append-only migration event, never a rewrite).
3. **`state_changed` events** — digest those too, or rely on the chain from
   (1)? Leaning: the chain covers them.
