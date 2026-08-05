---
title: "Plan 0004 — agency under the invariant: acts, policy, verifier, runtime"
status: deferred — NOT part of the first build
date: 2026-08-05
source: master thread (direction → socrates_2/threads/2026-08-05-master-thread.md)
---

# Plan 0004 — agency under the invariant

**Not part of the 0001 build.** Recaptures dynamic agent-with-tools ability
while keeping every guarantee: models emit data, the gate stands between data
and effect, only the operator changes state. `act` and `did` already exist as
statement types (D5); this plan gives them execution machinery. Quoted blocks
are verbatim from the master thread.

## Acts are statements — the loop

<!-- verbatim: master-thread -->
> ```
> model proposes:   [act_0] write file X with content C   (structured output — data, not effect)
> gate validates:   path inside workspace? op on the allowlist? matches ratified plan?
> policy decides:   auto-execute | require ratify | reject     (a table, not a model)
> app executes:     deterministically — and prefers byte-preserving ops
> journal records:  [did_0](act_0) executed; result R; digest of bytes written
> ```

The audit-trail property that distinguishes this from every existing harness:

<!-- verbatim: master-thread -->
> A `did` is a node with inbound and outbound edges, so later claims can depend on actions ("`claim_3`(did_0): the test passed *because* the fix landed"), and "why did you do X" is answered by edges, not by scrollback.

## The policy table

Deterministic, keyed by effect class (read / store-append / workspace write /
external-irreversible), versioned as data in the repo. What makes it different
from every harness's approval layer:

<!-- verbatim: master-thread -->
> 1. **Policy is data, not scattered code.** A versioned table in the repo — reviewable, diffable, journaled when it changes — versus heuristics spread across a codebase plus runtime prompts.
> 2. **Decisions key on typed effects, not opaque strings.** Claude Code must decide about `bash -c "..."` — a string whose semantics it cannot inspect, which is why it asks a human to eyeball it. An `act` is typed: the policy engine *knows* it's a workspace-file patch versus an external POST, so rules attach to what the action *is*.
> 3. **The gate precedes policy.** Proposals are validated data before policy ever sees them. There's no equivalent step for a shell string.
> 4. **The audit trail is the argument graph.** Claude Code's record is a transcript you scroll; here every act and result is a statement with edges, so later claims can *depend on* actions and "why did you do X" is answered by following deps.

## Plan-envelope ratification

What keeps the loop from being approval-prompt hell:

<!-- verbatim: master-thread -->
> the operator ratifies a **plan** — a set of proposed `act`s with dependencies — once, up front; the loop then runs autonomously within the ratified envelope, and only a proposal *outside* the envelope pauses for a new ratification.

## Byte-surface minimization

<!-- verbatim: master-thread -->
> **Plainspeak:** the less model-generated text you allow to become bytes on disk, the less can be silently corrupted. So never have the model *re-say* content that already exists — have it *point at* what should change. And for the store, go further: the model never produces file bytes at all; it produces objects, and dumb code turns objects into bytes.

Encoding choice (native tool_use vs custom act schema) is an implementation
decision — the architecture is identical either way, because:

<!-- verbatim: master-thread -->
> if your handler's body is "journal the proposal → consult policy → maybe execute → return result," the gate isn't a discipline the model might route around; it's the only door.

## The verifier — a second model without a pen

<!-- verbatim: master-thread -->
> - **Inputs, assembled by the harness:** the proposal under review, the ratified intent statements it claims to serve, and the source prose. Deliberately *excluded:* the proposer's conversation and reasoning. Fresh context, so it cannot be anchored by the thing it's checking.
> - **Stance, set by its system prompt:** adversarial — "attempt to refute each statement's fidelity to the source; when uncertain, refute." Skeptic by construction, because a verifier that wants to agree is a rubber stamp with extra tokens.

Findings pass their own mini-gate and enter the graph with dep edges to the
statements they assess — verification lives in the graph, not beside it. The
governing rule, from the thread:

<!-- verbatim: master-thread -->
> Inference can inform the gate; it can never be the gate.

Policy may condition on verdicts for low-stakes classes only (the rule stays
deterministic; the verdict is one input, like CI gating merges on tests written
by fallible humans). External/irreversible classes always reach the operator.

## Runtime evolution (BEAM)

The MVP is a per-invocation CLI. Agency forces a long-lived runtime, and that's
where the BEAM mapping from the thread activates:

<!-- verbatim: master-thread -->
> one GenServer owns the journal; every writer — intake, audit, the agentic loop, an nvim session — sends it a message. Write serialization stops being a lock and becomes the actor model doing what it's for. The gate as a process whose mailbox is the only door.

Decision rule, verbatim:

<!-- verbatim: master-thread -->
> **if socrates stays a single-operator CLI, BEAM is optional; the moment it becomes a server — shared store, several humans ratifying, agents proposing concurrently — BEAM is the natural home**

## Open questions

1. Verifier finding types under D5: findings are naturally `attest` (with
   basis) or `infer` — or does a `finding`/`judgment` type earn loadout entry
   through use?
2. Policy file format and its own ratification workflow (policy changes are
   journaled events).
3. Envelope semantics: what counts as "inside" a ratified plan when an act's
   parameters differ slightly from the ratified one — exact match, schema
   match, or policy-defined tolerance?
4. Native tool_use vs custom `act` schema — decide at implementation against
   the then-current API.
