---
title: "Build notes — plan 0001"
status: proposed — decisions the normative documents forced during the build, filed for operator ratification
date: 2026-08-05
---

# Build notes — plan 0001

Where plan 0001, the specs, and the audit were genuinely silent, the build
made the smallest decision consistent with the invariant (models emit data;
the gate stands between data and effect; only the operator changes state) and
logged it here. Nothing in this file edits a ratified document; every item is
**proposed** for ratification. Items are grouped by milestone of first need.

## M0 — loadout

- **N1. Schema subset: `anyOf` per-type shapes** (audit C2 offered the
  choice). A discriminated union with per-branch required fields, so the
  server-side constraint carries as much of the language as the subset
  allows. `deps` and `notes` are required-but-may-be-empty on every branch:
  a model must always say "no deps" explicitly rather than omit the field.
- **N2. Repair-turn format**: the follow-up user turn is exactly
  `{"gate_errors": [{"code", "subject", "detail"}, …]}` JSON, and the model
  re-emits the complete artifact (not a diff). Pinned in loadout-v0 § repair
  protocol.

(Later milestones append here.)
