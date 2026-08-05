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

## M1 — journal and CLI surface

- **N3. Journal event payloads.** The four ratified event kinds carry:
  `exchange_opened {exchange, source?: {path, sha256}, ts}` (source present
  only for intake exchanges; paths store-relative); `statement_added
  {statement, ts}`; `state_changed {sid, state, note?, ts}` (note carries
  `reject --note`); `intake_rejected {exchange, errors, calls, rejected:
  {path, sha256}, ts}`. Archive digests ride the events (audit B4's
  "recorded digests" need a home): the source digest on `exchange_opened`,
  response digests in `provenance.calls` on each surviving statement (the
  full call history of the intake, so intermediate repair responses stay
  verifiable on the success path too), and on `intake_rejected` for the
  failure path. Redundant across an intake's statements, but journal-native —
  no side manifest files.
- **N4. `seq`** (app-stamped, unspecified beyond its name) is the
  statement's 1-based ordinal within its exchange.
- **N5. Timestamps** are UTC ISO 8601, second precision (`…Z`); ordering
  authority is journal position, never timestamps.
- **N6. Torn/malformed journal lines are a hard error** on fold (exit 2),
  never a silent skip — per the audit's suggestion, decided here.
- **N7. Body via stdin** strips exactly one trailing newline; `--body` is
  taken byte-exact. An empty (or whitespace-only) body is a usage error
  (exit 2) — no gate code exists for it, and it is an invocation-shape
  problem, not a content finding.
- **N8. Usage-vs-lint boundary at `add`:** malformed invocations (unknown
  type, missing `--term`, malformed `--origin`, flag on the wrong type) are
  usage errors, exit 2, before any content check; content findings
  (`E_DEF_NO_SCOPE`, `E_REF_NO_ORIGIN`, `E_DANGLING_DEP`, `E_TERM_UNDEF`)
  are gate-coded lint errors, exit 1, nothing journaled. Scenario 2 pins the
  lint-error line format `<CODE> <subject>: <detail>` with the subject being
  the statement's type until an id is assigned.
- **N9. Dep targets must be live.** New deps (add/amend) resolve display ids
  to the chain's live head; a head in `rejected`/`superseded` state refuses
  with `E_DANGLING_DEP … dep <id> rejected|superseded`, and an explicit sid
  of a dead statement likewise. Model-artifact deps can never hit this case
  (they resolve against artifact ids ∪ ratified global defs).
- **N10. `definitions.json`** is written compact (deterministic sorted-key
  JSON, one line): `{term → {body, display_id, sid}}`. Regenerated after
  every fold, including by read-only commands.

## M2 — graph, gate, verify

- **N11. Render/topo order is layered:** statements sort by longest-path
  depth over intra-selection dep edges, then defs/refs first within a
  layer, then journal order. This is the one rule consistent with both
  normative renders (scenario 3 shows all premises before the first
  conclusion; scenario 4 shows repair-minted `def_2` first). Plan 0001
  names Kahn — layering is a deterministic Kahn schedule (each layer is a
  ready set); noting the refinement here rather than editing the plan.
- **N12. Term scope for operator writes:** `E_TERM_UNDEF` at `add`/`amend`
  resolves terms against every live (proposed or ratified) def in the
  store, local or global — the operator sees the store. Model artifacts
  resolve against artifact defs ∪ live ratified :global defs only
  (loadout-v0 pin).
- **N13. E_DUP_ID also covers artifact ids colliding with a listed global
  def's display id** (the definitions block shows the model those ids;
  minting over one is a collision, not a shadow).
- **N14. `verify` scope:** re-hashes every journal-recorded archive file
  (N3) and reports `MISMATCH`/`MISSING` per file, plus `UNRECORDED` for
  foreign files found under `sources/` — a foreign object in the verbatim
  area is a tamper signal. Ref origins: `file`-kind origins of live
  (proposed|ratified) chain heads are re-hashed against `origin.sha256`;
  other kinds are uncheckable without network and are not counted. Problem
  lines only on failure (exit 3); the summary line only when clean (exit
  0), matching scenario 6's shapes.
- **N15. `ratify`/`reject` batches are atomic:** every id is resolved and
  state-checked before the first `state_changed` is journaled; duplicate
  ids in one invocation are deduped. Confirmation `"<n> ratified"` /
  `"<n> rejected"` to stderr (scenario 4 pins the former).
- **N16. `rdeps` and closures are chain-aware and live:** an edge to any
  sid of a revises chain counts as an edge to the chain; dependents listed
  are live statements, in journal order; `--all` closures are BFS
  discovery order (scenario 3 pins `infer_1` then `act_1`).
- **N17. `graph` output:** roots are statements no live statement in the
  selection depends on, in journal order; children are the statement's
  deps in stored order, indented two spaces per level; shared subtrees
  repeat under each dependent.
- **N18. `E_CYCLE` detail** prints the cycle as
  `dependency cycle: a -> b -> a` (artifact-local ids; ASCII arrows).

(Later milestones append here.)
