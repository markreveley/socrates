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

## M3 — client and intake

- **N19. Client behaviour boundary:** a client is a transport —
  `call(request_bytes, config) → {:ok, %{status, body, request_id}}`.
  Request assembly is shared (`Socrates.Client.build_request/2` +
  `encode_request/1`, the deterministic encoder), so the digested bytes are
  the sent bytes for fixture and live alike, and the fixture's provenance
  digests are real digests of real requests.
- **N20. Built-in fixture keying:** the default fixture serves the
  acceptance sequence for sources carrying canon #1's
  `*representation ratification*` marker, and the persistently-broken
  artifact (scenario 5) for anything else. `fixture:<path>` serves a JSON
  array of full response bodies by call index (last repeats) for arbitrary
  test behaviors. Fixture responses are emitted through the deterministic
  encoder, so archived bytes are stable across runs.
- **N21. Fixture artifact bodies** (scenario 4 said "statement bodies are
  the fixture's, deterministic once the fixture is authored"): canon #1's
  claims verbatim, minus the inline `(def_0)` notation artifacts (the dep
  edge replaces them — decomposition, not quotation), with claim_2's
  asymmetric `*…"` delimiter closed to `*…*` (only the re-emission makes
  the term findable — audit C1) and its inline brace note moved to the
  notes field. The minted def_2: term as coined, scope local, a
  single-clause body (0 warnings), the canon note carried over.
- **N22. Repair-turn transcript:** the assistant turn is the model's
  artifact text verbatim; the user turn is the `{"gate_errors": [...]}`
  JSON (loadout pin). The repaired artifact replaces the whole proposal
  (full re-emission).
- **N23. stop_reason ≠ end_turn** (audit B3): response archived, then
  `intake_rejected` journaled with a `stop_reason` finding (subject
  `response-<n>`), stderr `stop_reason <r> — response archived, not
  gated`, exit 1. Transport/API failure (non-200, network): exit 2, error
  on stderr, nothing further journaled — the exchange stays open with its
  archived source, which is honest: the source was archived, no inference
  completed. An unparseable 200 body or a schema-impossible artifact
  shape: archived, `intake_rejected` with an `artifact_shape` finding,
  exit 1.
- **N24. Inference footer content** for multi-call intakes: the model and
  request id of the last response, token usage summed across all calls of
  the invocation (the honest total cost). Fixture: `fixture · - · 0 in /
  0 out` (cli-v0 pin).
- **N25. Intake env-failure footer:** an intake that aborts before any
  call completes (missing key, unreadable file) footers `[deterministic]`
  — no inference ran; the footer reports what happened, not what was
  intended. After any completed call the footer is the inference form,
  including on rejection paths (scenario 5 pin).
- **N26. Exchange-dir collision** (crash mid-intake leaves archived files
  with no journal record): a later intake that would reuse the directory
  refuses with exit 2 and a cleanup message rather than violating
  write-once. Journal order for intake: `exchange_opened` (with source
  digest) first, statements or `intake_rejected` at the end — a crash
  between the two leaves an open, empty exchange, visible in `log`.
- **N27. `HTTPS_PROXY`** is honored by the live client when the
  environment sets it (standard convention; needed in sandboxed
  environments). No proxy → direct connection. TLS stays on the OS trust
  store either way (audit B1).
- **N28. `SOCRATES_MODEL`** reaches the request body verbatim; the
  journaled per-call `model` is taken from the response (what actually
  served), which is also what the footer shows.

## M4 — amend and finish

- **N29. Amend semantics** (audit left them open): the target must be live —
  amending a `superseded` sid errors pointing at the live head; amending a
  `rejected` statement errors (reject is a verdict; author fresh instead).
  Amending a `proposed` model statement is allowed as an operator rewrite;
  the replacement is operator-authored and therefore enters `ratified`,
  stamps exchange 1, and supersedes the proposal.
- **N30. Amend takes the full replacement:** the same flags as `add` minus
  `--type` (the type is fixed to the original's; passing `--type` is an
  unknown-option usage error). Nothing is inherited — a def amend requires
  `--term`/`--scope` again; deps not restated are dropped. Deliberate:
  supersession replaces a statement, and re-typing is the price of the
  journaled record.
- **N31. Amend runs the full gate** including a chain-aware cycle check:
  the live graph is checked with the chain's edges swapped for the
  candidate's, so a replacement cannot close a loop through its own
  dependents (`E_CYCLE`, exit 1, nothing journaled).
- **N32. Scenario-6 tamper walk note:** `truncate`-restoring the tampered
  byte restores verification (digests are content digests; no mtime
  anywhere).

## Acceptance

- Acceptance step 6 (one live `intake` from the built escript) requires
  `ANTHROPIC_API_KEY`, which this build session did not hold. Steps 1–5
  and the full scenario 1–7 walks ran from the built escript (transcripts
  in the PR); **step 6 is pending the operator's run**:
  `MIX_ENV=prod mix escript.build && ANTHROPIC_API_KEY=… ./socrates intake <file>`
  in a scratch store. No live transcript is included because none was run —
  provenance is not fabricated here of all places.
