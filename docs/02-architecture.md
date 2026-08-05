---
title: "Docs — how socrates works, in plain words"
status: explanatory — non-normative; on any conflict, plans/0001-mvp-harness.md and spec/ win
authorship: agent-drafted for operator review
date: 2026-08-05
---

# How socrates works

This is the architecture of the first build (plan 0001), explained from the
ground up for a reader who has not seen the plans. Normative detail lives in
[`plans/0001-mvp-harness.md`](../plans/0001-mvp-harness.md),
[`spec/cli-v0.md`](../spec/cli-v0.md), and
[`spec/scenarios-v0.md`](../spec/scenarios-v0.md); if this document and those
disagree, those win.

## One invariant

Everything in the design serves a single sentence:

> models emit data, the gate stands between data and effect, and only the
> operator changes a statement's state.

Unpacked: the model never writes to the record directly — its output is data
to be checked. A deterministic program (the gate) checks it. And no matter who
authored a statement, only the human operator can move it between states
(`proposed → ratified | rejected`). Every architectural choice below is one of
these three clauses made concrete.

## The statement — the atom

A **statement** is one small unit of meaning with:

- a **type** — what kind of move it makes (below);
- a **body** — the sentence itself;
- **deps** — the statements it depends on, by id;
- a **state** — `proposed`, `ratified`, `rejected`, or `superseded`;
- an **author** — `operator` or `model`;
- bookkeeping the app stamps on (ids, timestamps, provenance).

There are six types (decision D5), carved at *functional roles* — what a
statement does, not how confident you are in it:

| Type | Plain meaning | Example |
|---|---|---|
| `attest` | "I assert this." Facts and first-person reports alike. | `apples are fruits` · `i want access to more food consistently` |
| `infer` | "This follows from my deps." | `apples reproduce` (from *apples are fruits* + *fruits reproduce*) |
| `act` | "Therefore I/we should do this." The only ought-type. | `i should consider planting apple trees` |
| `did` | "This was done." The record of an executed act. | *(execution machinery lands in plan 0004)* |
| `def` | A stipulated definition of a term, `local` or `global` in scope. | *representation ratification* means… |
| `ref` | An anchored pointer to something outside the store (file, url, quote), content-hashed. | a source document |

`attest`/`infer`/`act`/`did` form the practical loop — know, conclude, intend,
execute — and the is/ought boundary becomes *typed*: an `act` is legitimate
when its deps trace to an attested want, not to facts alone. See
[`canon/practical-syllogism.md`](../canon/practical-syllogism.md), the example
that settled the type set.

Two more rules of the language:

- **Multiple deps are implicit conjunction.** A statement depending on
  `(attest_1, attest_2)` takes both jointly as premises, so pure
  conjunction-statements ("A and B") decompose away.
- **Terms are marked.** `*term*` in a body must resolve to a `def` in scope.
  Coining a term without defining it is a hard error — the note `{coinable}`
  is an IOU, and the gate refuses IOUs.

## The graph

Deps make the store a directed graph, and the graph must be acyclic — circular
reasoning is a mechanical error (`E_CYCLE`), not a matter of taste. Because
deps resolve and cycles are refused, a topological order always exists, so
renders can put definitions first without asking the model to.

The graph is what makes the record *interrogable*: `deps <id>` answers "what
does this rest on?", `rdeps <id>` answers "what rests on this?" — i.e. "what
breaks if this is wrong?" as a keystroke. (The README's lineage note: this is
the answer to Socrates' complaint in the *Phaedrus* that written words stay
silent when questioned.)

## The store

Lives at `.socrates/` in the repo you run it in — for dogfooding, this repo,
committed like any other file.

```
.socrates/
  journal.jsonl        # the record: an append-only stream of events
  sources/<exchange>/  # verbatim inputs & raw model responses, write-once
  definitions.json     # derived index of ratified global defs (never authority)
```

- **The journal is append-only.** Four event kinds: `exchange_opened`,
  `statement_added`, `state_changed`, `intake_rejected`. Statements are
  immutable; *change is supersession* — `amend` writes a new statement with a
  `revises` edge and flips the old one to `superseded`. Nothing is ever
  deleted or rewritten, so the history of what you believed is itself part of
  the record.
- **JSON is canonical; the notation is a view.** The bracket syntax you see in
  renders is produced from the journal, never parsed back in. A hand-rolled
  deterministic encoder fixes field order so that encoding is byte-stable
  (property-tested: encode → decode → encode is byte-identical; folding the
  journal twice yields identical state).
- **Two kinds of identity (D7).** Every statement has a `sid` — a ULID, the
  real, permanent identifier that dep edges are stored as — and a
  `display_id` like `attest_3`, a human-friendly name the app assigns at
  acceptance: next free index per type, unique for the life of the store. The
  model's own numbering is treated as artifact-local scratch names and
  rewritten on acceptance; a `revises` chain shares one display id, which
  resolves to the chain's live head. Models emit data; the app stamps
  identity.
- **`definitions.json` is derived, never authoritative.** It is regenerated
  from the journal fold (`term → latest live ratified global def`) and read by
  nobody internally — the gate and the model prompt read the fold itself, so a
  stale or hand-edited file can't silently alter behavior.
- **Sources are write-once.** Input prose and every raw model response are
  archived byte-exact with sha256 digests, and `verify` re-hashes them all —
  zero network, zero inference. Tamper-evidence for statements themselves
  (content digests, hash chaining) is designed as plan 0002.

## The gate

The gate is the language compiled into executable checks. It runs on every
model proposal, and (minus the repair loop) on every human-authored statement.
In plain words, it refuses:

| Error | Refuses |
|---|---|
| `E_ID_FORM` | ids that don't match their type (`attest_3` must be an attest) |
| `E_DUP_ID` | the same id minted twice within an artifact |
| `E_DANGLING_DEP` | depending on a statement that doesn't exist |
| `E_CYCLE` | circular reasoning (the cycle path is printed) |
| `E_TERM_UNDEF` | using a `*term*` no def in scope defines |
| `E_DEF_NO_SCOPE` | defs that don't declare `local` or `global` |
| `E_REF_NO_ORIGIN` | refs with nothing to anchor to |
| `W_DEF_ATOMICITY` | *(warning)* defs that try to say two things at once |

When a model proposal fails, the structured error list goes back to the model
as a follow-up turn — at most **two** repair retries — then the run fails
loudly: nonzero exit, the rejected artifact saved to disk, an
`intake_rejected` event journaled. Never silently accepted. Rejected
artifacts are kept deliberately: they are a free evaluation corpus.

Both canonical examples in `canon/` carry known gate findings, which is the
system's argument made by its own seed data: even carefully hand-authored
decompositions contain dangling deps and undefined coined terms that
mechanical checking catches and prose reading glides over.

What the gate deliberately does *not* check: truth, fidelity to the source
prose, quality of the decomposition. That is layer two — the operator's
ratification judgment (and, later, plan 0004's adversarial verifier model,
which may *inform* the gate but "can never *be* the gate").

## The harness and the command surface

The harness is the orchestration around everything above: assemble context,
call the model, run the gate, write the journal, drive the CLI. Concretely
(all decisions ratified in plan 0001): Elixir ≥ 1.18 / OTP ≥ 27, exactly one
dependency (`req` for HTTP), no SDK — the request body is hand-assembled so
the provenance digest covers exactly the bytes sent — packaged as a single
`socrates` escript executable, run per-invocation with no server or
long-lived processes.

Every command is one of two kinds, and every command says which it is in a
stderr footer:

- **Deterministic** — pure functions over the store: `init`, `add`, `amend`,
  `show`, `deps`, `rdeps`, `graph`, `render`, `ratify`, `reject`, `verify`,
  `log`. Footer: `[deterministic]`.
- **Inference** — exactly one: `intake`. Footer:
  `[inference: <model> · <request-id> · <n> in / <m> out]`. One generative
  door, clearly marked, with provenance journaled per call (request-body
  sha256, model id, request id, token usage, timestamp).

Output discipline (D6): stdout carries only the artifact — renders, ids,
query results — so everything pipes cleanly into ordinary Unix tooling;
footers, progress, and gate errors go to stderr; status goes in exit codes
(`0` ok · `1` gate-rejected · `2` usage error · `3` verify mismatch). The
render marks ratified statements with `⊢` — Frege's judgment stroke — as
display only (D4): nothing ever parses the glyph, and the journal stores the
word `ratified`.

`verify` is the kernel property in miniature: a small, dumb, independent
check (re-hash everything, compare, exit nonzero on mismatch) that needs no
network and no model — the de Bruijn criterion applied to the store.

## The write asymmetry

Two doors into the store, deliberately unequal:

- **`add` (human).** The operator authors a statement directly. It gets a
  structural lint (no repair loop, no inference) and enters **`ratified`**
  immediately — authorship is assent; ratifying your own sentence to yourself
  would be ceremony.
- **`intake` (model).** Prose goes in; the model returns a structured
  decomposition against a JSON schema; the gate checks it (with up to two
  repairs); survivors enter **`proposed`** and wait for the operator. The
  model petitions.

The human write path ships first (milestone M1, before any API key is needed)
— deliberately: the operator can begin authoring socrates-in-socrates before
the model ever gets a door.

## The life of a statement — a worked walk

Condensed from [`spec/scenarios-v0.md`](../spec/scenarios-v0.md):

1. `socrates init` — creates `.socrates/`, opens exchange 1 (the operator's
   standing exchange).
2. `socrates add --type attest --body "apples are fruits"` — direct human
   write; linted; enters ratified; renders as `⊢ [attest_1] apples are fruits`.
3. `socrates intake canon-block.txt` — archives the prose verbatim, opens the
   next exchange, one model call decomposes it, the gate finds
   `E_TERM_UNDEF` on a coined term, the repair loop mints the missing def,
   the artifact passes; statements land as `proposed` (no `⊢`).
4. `socrates ratify def_2 attest_4 …` — the operator reads and accepts,
   statement by statement. Ratifying a global def promotes it into the
   definitions export, and future model calls see it.
5. `socrates rdeps attest_1` — interrogate the graph: what depends on this?
6. `socrates amend attest_1 --body "apples are a fruit"` — change is a new
   statement revising the old; the old one is `superseded`, never gone; the
   display id stays with the chain.
7. `socrates verify` — re-hash every archived source and ref origin; any
   mismatch is exit 3.

Acceptance for the whole build is exactly this walk (scenarios 4–7) performed
on the canonical example from `canon/representation-ratification.md`, with
the gate finding precisely the defects canon annotates.

## The road ahead (designed, not built)

Sibling plans, each explicitly out of the first build:

- **0002 — statement digests.** Extend `verify` from sources to every
  statement: content digests, possibly hash-chained events; tamper-evidence
  journal-wide.
- **0003 — composition & measurement.** The loop closes: `re-prose` renders a
  subgraph back to prose (archived, never truth); **patches** are named
  selectors with an append-only compilation history; `audit` proposes
  decompositions of overloaded statements as changesets; **roundtrip**
  measures decomposition stability (graph → prose → graph → structural diff)
  — regression testing for the methodology itself.
- **0004 — agency.** Acts gain execution: model proposes a typed `act`, gate
  validates, a versioned **policy table** (not a model) decides
  auto-execute / require-ratify / reject, the app executes deterministically,
  and a `did` with edges records it. Plan-envelope ratification keeps it from
  becoming approval hell; an adversarial second-model **verifier** (fresh
  context, no pen) files findings into the graph. "Inference can inform the
  gate; it can never be the gate."
- **0005 — surfaces.** A neovim plugin (buffers as views over the store,
  extmarks binding lines to sids, ratify on keypress), then a language server
  (go-to-def on terms, find-references as `rdeps`, gate diagnostics as
  squiggles while you type).
- **0006 — instrumentation.** Gate-pass rates, the ratification stream as a
  labeled dataset, and the rejection-rate canary against rubber-stamping.

## Where things live

| Path | What it is |
|---|---|
| `README.md` | Charter: invariant, four layers, plan map, lineage |
| `canon/` | Operator-authored, verbatim, canonical: purpose and the two seed examples |
| `plans/0001-mvp-harness.md` | The ratified first build (with `0001-audit.md`, the pre-build adversarial audit) |
| `plans/0002…0006` | The designed future, deferred |
| `spec/cli-v0.md` · `spec/scenarios-v0.md` | Normative interface and worked expected behavior |
| `docs/` | This folder: explanation and research, non-normative |
| `.socrates/` | (once built) the dogfood store itself |
