---
title: "Docs — terminology: the vocabulary, defined"
status: explanatory — non-normative; canon/, plans/, and spec/ win on any conflict
authorship: agent-drafted for operator review
date: 2026-08-07
---

# Terminology

The repo runs on a small vocabulary used precisely. Some of it is ordinary
English narrowed to one meaning (*ratify*, *gate*, *exchange*); some of it is
coined here (*loadout*, *changeset*, *boundary footer*); and a few words were
deliberately split apart after they collided (*patch* / *changeset*). This
file is the lookup surface for all of it.

How to read an entry:

- **Where it's fixed.** Every entry ends with the file that settles the term.
  This document only translates — where it and the cited source disagree, the
  source wins, and the disagreement is a defect here.
- **What's built.** Unmarked terms are live in the 0001 build. Terms marked
  **(0002)**–**(0006)** name the plan that designs them: vocabulary that
  exists on paper, with no code behind it yet. **(docs/05)** marks the
  restatement design, which has no plan number.
- **Terms about socrates vs. terms *in* socrates.** A `def` inside the store
  is a statement with a state and an author. Nothing in this file is: these
  are glosses for readers, not ratified definitions. If the vocabulary ever
  enters the store as `def`s, that is a ratification workload, and
  [`04-transfer-study.md`](04-transfer-study.md) is where the question of
  transferring the docs is worked out.

## Index

**A** [act](#the-language) · [amend](#identity-and-state) · [analyses/](#repo-vocabulary) · [anti-parrot lint](#composition-and-measurement) · [artifact](#the-gate) · [artifact id](#identity-and-state) · [attest](#the-language) · [audit](#composition-and-measurement) · [author](#identity-and-state)

**B** [basis](#the-language) · [body](#the-language) · [boundary footer](#the-harness) · [byte-surface minimization](#agency)

**C** [canary](#instrumentation) · [canon/](#repo-vocabulary) · [changeset](#composition-and-measurement) · [closed book](#composition-and-measurement) · [coinable](#the-language) · [compile](#composition-and-measurement) · [comprehension event](#the-wager)

**D** [de Bruijn criterion](#the-store) · [decision (D*n*)](#repo-vocabulary) · [def](#the-language) · [deference](#the-wager) · [definitions.json](#the-store) · [dep](#the-graph) · [deps / rdeps](#the-graph) · [deterministic command](#the-harness) · [did](#the-language) · [digest](#the-store) · [display id](#identity-and-state)

**E** [effect class](#agency) · [exchange](#the-store) · [exit code](#the-harness) · [extmark](#surfaces)

**F** [fixture client](#the-harness) · [fold](#the-store) · [forcing function](#the-wager)

**G** [gate](#the-gate) · [glossary](#the-store) · [graph](#the-graph) · [growth rule](#the-language)

**H** [halt rule](#composition-and-measurement) · [harness](#the-harness) · [hard error](#the-gate)

**I** [implicit conjunction](#the-language) · [infer](#the-language) · [inference command](#the-harness) · [intake](#the-harness) · [invariant](#the-wager)

**J** [journal](#the-store) · [judge-as-annotator](#composition-and-measurement) · [judgment stroke (⊢)](#the-graph)

**L** [lint](#the-gate) · [loadout](#the-language)

**M** [master thread](#repo-vocabulary) · [milestone (M*n*)](#repo-vocabulary) · [model](#the-wager)

**N** [notation](#the-graph) · [notes](#the-language)

**O** [operator](#the-wager) · [origin](#the-language)

**P** [patch](#composition-and-measurement) · [plan-envelope ratification](#agency) · [plans/](#repo-vocabulary) · [policy table](#agency) · [proposed](#identity-and-state) · [provenance](#the-store)

**R** [ratified](#identity-and-state) · [ratify](#the-wager) · [reconstitute](#composition-and-measurement) · [ref](#the-language) · [rejected](#identity-and-state) · [render](#the-graph) · [repair loop](#the-gate) · [re-prose](#composition-and-measurement) · [representation ratification](#the-wager) · [restate](#composition-and-measurement) · [revises](#identity-and-state) · [roundtrip](#composition-and-measurement) · [rubber-stamping](#the-wager)

**S** [scope](#the-language) · [selector](#the-graph) · [seq](#identity-and-state) · [shadow exchange](#composition-and-measurement) · [sid](#identity-and-state) · [sources/](#the-store) · [spec/](#repo-vocabulary) · [stability score](#composition-and-measurement) · [state](#identity-and-state) · [statement](#the-language) · [stats](#instrumentation) · [store](#the-store) · [superseded / supersession](#identity-and-state)

**T** [term](#the-language) · [topological order](#the-graph) · [type](#the-language)

**V** [verifier](#agency) · [verify](#the-store) · [view](#surfaces)

**W** [warning](#the-gate) · [write asymmetry](#the-harness)

---

## The wager

- **socrates** — this system: a type system for statements, in which an LLM
  decomposes prose into typed, dependency-linked statements, a deterministic
  gate validates structure, and a human ratifies meaning one statement at a
  time. Named for the elenchus, which attacks unearned confidence in one's own
  understanding. ([`README.md`](../README.md))

- **operator** — the human. The only author who can change a statement's
  state, the only party whose writes enter the store directly, and the scarce
  resource the whole design is built around: comprehension, not generation.
  ([`canon/purpose.md`](../canon/purpose.md), [`01-purpose.md`](01-purpose.md))

- **model** — the LLM. It emits data, never truth and never effect: its output
  is a proposal that must pass the gate and then wait for the operator. In
  entries below, *the model petitions* is shorthand for exactly this.
  ([`02-architecture.md`](02-architecture.md) → *The write asymmetry*)

- **invariant** — the one sentence every design choice serves: *models emit
  data, the gate stands between data and effect, and only the operator changes
  a statement's state.* ([`README.md`](../README.md))

- **ratify** — the operator's act of accepting a statement's meaning, moving
  it from `proposed` to `ratified`. Ratification is not a check that the
  structure is well-formed (the gate did that mechanically); it is the human
  judgment of truth and fidelity that the gate deliberately refuses to make.
  Only the operator can perform it. (`socrates ratify` in
  [`spec/cli-v0.md`](../spec/cli-v0.md))

- **comprehension event** — the unit socrates denominates progress in. One
  ratification is one comprehension event; the count of them, not tokens
  generated, is the velocity metric the system claims.
  ([`01-purpose.md`](01-purpose.md) → *The bet socrates makes*)

- **representation ratification** — the canonical coined term, and `def_0` of
  the seed example: *the operator verifying the agent's socrates rendering of
  operator intent before any work is done.* Its decomposition is the
  acceptance fixture for the build.
  ([`canon/representation-ratification.md`](../canon/representation-ratification.md))

- **deference** — the failure mode socrates exists to prevent: once model
  output outruns the operator's ability to check it, the cheap move is to
  assume the model knows what it is doing, and approval becomes theater.
  Canon's name for its surface form is *"sounds like you know what you are
  doing."* ([`canon/purpose.md`](../canon/purpose.md),
  [`01-purpose.md`](01-purpose.md))

- **rubber-stamping** — deference made habitual: approving without reading.
  The system does not claim immunity — it instruments the symptom
  ([canary](#instrumentation)) and doses the ceremony
  ([restate](#composition-and-measurement)) instead.

- **forcing function** — the design register socrates works in: a mechanism
  that physically prevents an error rather than warning against it. The
  bracket notation is drier than prose on purpose; fluency is the anesthetic
  the system counteracts. ([`01-purpose.md`](01-purpose.md) → *The cost is the
  feature*)

## The language

- **loadout** — the language itself as a versioned, editable object: the type
  list, the field rules, the term rule, the API schema, and the system prompt
  assembly. Prose form in [`spec/loadout-v0.md`](../spec/loadout-v0.md), data
  form in `Socrates.Loadout` — where they could diverge, the module is what
  runs and the spec is what the operator ratified.

- **growth rule** — how the language changes: a new type or field is a loadout
  edit made *through use* — proposed, ratified, journaled. Nothing from the v1
  vocabulary is imported wholesale.
  ([`spec/loadout-v0.md`](../spec/loadout-v0.md) → *Types*)

- **statement** — the atom: one small unit of meaning carrying a type, a body,
  deps, a state, an author, and app-stamped bookkeeping. Statements are
  immutable once written; change is
  [supersession](#identity-and-state). ([`02-architecture.md`](02-architecture.md))

- **type** — what kind of move a statement makes. Six, ratified as D5, carved
  at *functional roles* rather than confidence levels:

  | Type | The move it makes |
  |---|---|
  | `def` | stipulates a *term*, `local` or `global` in scope |
  | `ref` | anchors a pointer to something outside the store, content-hashed |
  | `attest` | asserts something as holding — facts, reports, first-person wants |
  | `infer` | draws a conclusion from its deps |
  | `act` | prescribes something to do — the only ought-type |
  | `did` | records something done |

  `attest → infer → act → did` is the practical loop (know, conclude, intend,
  execute), which makes the is/ought boundary *typed*: an `act` is legitimate
  when its deps trace back to an attested want, not to facts alone.
  ([`canon/practical-syllogism.md`](../canon/practical-syllogism.md),
  [`spec/loadout-v0.md`](../spec/loadout-v0.md))

- **body** — the statement's own sentence: the text being asserted, defined,
  concluded, or prescribed.

- **deps** — the statements this one rests on, recorded as edges. See
  [the graph](#the-graph).

- **implicit conjunction** — the ratified rule that multiple deps bind
  *jointly*: a statement depending on `(attest_1, attest_2)` takes both as
  premises together. Consequence: conjunction-only statements ("A and B")
  decompose away instead of being written.
  ([`spec/loadout-v0.md`](../spec/loadout-v0.md))

- **term** — a word or phrase with a stipulated meaning, coined by a `def` and
  used by writing it between asterisks: `*representation ratification*`. The
  asterisk surface is **reserved** — a span `*x*` is a use of the term `x` and
  nothing else, so emphasis is normalized away by whoever enters the statement
  (the app never strips asterisks itself: it cannot tell emphasis from a
  term). Matching is exact string equality — no case folding, no stemming.
  ([`spec/loadout-v0.md`](../spec/loadout-v0.md) → *The term rule*)

- **coinable** — a note marking a term the author intends to define later. It
  is an IOU, and *the gate refuses IOUs*: a used term with no `def` in scope
  is `E_TERM_UNDEF`, a hard error, whoever wrote it.
  ([`canon/representation-ratification.md`](../canon/representation-ratification.md)
  carries the canonical example)

- **scope** — a `def`'s reach: `local` (this exchange's argument) or `global`
  (the store's shared vocabulary). Ratifying a `global` def promotes it into
  the [glossary](#the-store), where future model calls can see it. Required on
  every `def` — a scopeless def is `E_DEF_NO_SCOPE`.

- **origin** — a `ref`'s anchor: `{kind, locator}` where kind is `file`,
  `url`, `exchange`, or `quote`. File origins are sha256'd by the app at write
  time — *measured, never trusted* — and re-hashed by `verify`. A ref without
  one is `E_REF_NO_ORIGIN`.

- **notes** — the `{}` meta-channel: a list of free strings on any statement,
  carrying commentary that is not part of the assertion (`{coinable local}`,
  filing hints, a rejection reason). Notes render trailing the body and are
  never parsed for meaning.

- **basis** — a render slot, `[basis: …]`, trailing the body. Reserved and
  currently empty: no v0 field produces it, and it first earns content in plan
  0004's verifier findings. Listed here because it appears in the render
  format and is otherwise unexplained. (`Socrates.Render`,
  [`spec/cli-v0.md`](../spec/cli-v0.md); flagged as future in
  [`plans/0001-audit.md`](../plans/0001-audit.md) §D)

## Identity and state

- **sid** — the real identifier: a ULID, permanent, assigned by the app, never
  reused. Dep edges are stored as sids, so the graph is unaffected by any
  renaming at the display layer.

- **display id** — the human-facing name, `<type>_<n>` (`attest_3`).
  App-assigned at acceptance, next free index per type, store-global and
  unique for the life of the store (D7). A `revises` chain shares one display
  id, which resolves to the chain's live head — so `attest_3` keeps meaning
  "the current version of that statement" across amendments. Every CLI
  argument takes display ids (sids are accepted anywhere too).

- **artifact id** — the model's own numbering inside one artifact. Treated as
  scratch: the gate reports findings against it (it is the id the model can
  follow through a repair), and the app rewrites it to a real display id on
  acceptance. *Models emit data; the app stamps identity.*
  ([`plans/0001-mvp-harness.md`](../plans/0001-mvp-harness.md) → D7)

- **state** — where a statement stands with the operator. Four values, and
  only the operator moves between them:

  | State | Meaning |
  |---|---|
  | `proposed` | entered through the gate, awaiting the operator — renders without `⊢` |
  | `ratified` | the operator has accepted its meaning |
  | `rejected` | the operator has refused it (with an optional note) |
  | `superseded` | replaced by a later statement that `revises` it |

  State lives in `state_changed` events, never as a mutation of the statement
  record; the model's output schema has no state field at all.

- **author** — `operator` or `model`. Determines which door a statement came
  through, and therefore what it cost to get in — see
  [write asymmetry](#the-harness).

- **amend** — the command that changes a statement: it writes a *new*
  statement with a `revises` edge and flips the original to `superseded`. The
  display id stays with the chain. Nothing is ever edited in place.

- **revises** — the edge from a replacement statement to the one it
  supersedes. The record of what you used to believe stays readable.

- **supersession** — the general principle behind `amend`, `audit`
  changesets, and hand-edits in a future editor surface: *change is a new
  statement, not a rewrite.* An append-only record means the history of belief
  is itself part of the record.

- **seq** — a statement's position within its exchange (1-based), stamped by
  the app at write time. Bookkeeping, not identity.

## The store

- **store** — `.socrates/` in the working directory: the journal, the write-once
  sources, and the derived definitions export. Commands operate on the store
  in the current directory only — no ancestor walking in v0.

- **journal** — `journal.jsonl`, the record: an append-only stream of events,
  never rewritten. Four kinds: `exchange_opened`, `statement_added`,
  `state_changed`, `intake_rejected`. Everything else in the store is derived
  from it.

- **fold** — replaying the journal from the first event to compute current
  state (which statements are live, what each one's state is, which global
  defs exist). The fold is the authority; anything on disk beside the journal
  is a cache of it. Property-tested: folding twice yields identical state.

- **exchange** — one unit of intake, numbered from 1. `init` opens exchange 1,
  the operator's *standing exchange*, which `add` and `amend` stamp; each
  `intake` opens the next integer. Exchanges scope a decomposition's sources
  and give `@<n>` selectors something to name.

- **sources/** — write-once archives, one directory per exchange: the input
  prose byte-exact (`source.txt`), every raw model response
  (`response-<n>.json`), and every artifact the gate refused
  (`rejected-<n>.json`). Rejected artifacts are kept deliberately — they are a
  free evaluation corpus.

- **provenance** — what was journaled about a model call: the sha256 of the
  exact request bytes sent, the model id, the request id, token usage, and a
  timestamp. The request body is hand-assembled without an SDK precisely so
  the digest covers exactly the bytes that went out.

- **definitions.json** / **glossary** — a derived index of live ratified
  `global` defs, regenerated from the fold and read by nobody internally: the
  gate and the model prompt read the fold itself, so a stale or hand-edited
  file cannot silently change behavior. *Derived, never authoritative.*

- **digest** **(0002)** — a sha256 over a statement's canonical serialization,
  extending tamper-evidence from sources to every statement in the journal.
  Covers the immutable fields only; `state` is excluded, because state lives in
  its own events. ([`plans/0002-statement-digests.md`](../plans/0002-statement-digests.md))

- **verify** — the zero-network, zero-inference check: re-hash every archived
  source and ref origin against recorded digests, exit `3` on any mismatch. A
  small, dumb, independent checker over the whole record.

- **de Bruijn criterion** — the principle `verify` embodies, borrowed from
  proof assistants: the trustworthiness of a large system should rest on a
  kernel small and dumb enough to be checked independently. ([`README.md`](../README.md)
  → *Lineage*)

## The graph

- **graph** — the store viewed through dep edges: statements as nodes,
  dependencies as directed edges. It must be acyclic — circular reasoning is
  a mechanical error (`E_CYCLE`), not a matter of taste — and because it is,
  a topological order always exists.

- **dep** — one edge: "this statement rests on that one." Stored as sids,
  written and displayed as display ids. In a model artifact, deps resolve
  against artifact-local ids plus the global defs listed in the prompt —
  exactly what the model was shown; a dep on anything else is a hallucination
  and dangles. Operator writes resolve against the whole live store, because
  the operator can see it.

- **deps / rdeps** — the two interrogation commands. `deps <id>` answers
  *what does this rest on?*; `rdeps <id>` answers *what rests on this?* —
  i.e. *what breaks if this is wrong?* as a keystroke. `--all` takes either to
  the transitive closure. This is the property that makes the record
  interrogable rather than merely stored.

- **topological order** — dependency order: nothing appears before what it
  depends on. Renders use it (defs and refs first) and compute it locally, so
  ordering is never something the model is asked for.

- **selector** — the small grammar for naming a piece of the graph: nothing
  (the whole graph), `<id>`, `<id>+deps` (with its transitive dependencies),
  `<id>+rdeps` (with everything depending on it), `@<exchange>`. Nothing else
  in v0; the grammar grows through use. ([`spec/cli-v0.md`](../spec/cli-v0.md))

- **notation** — the bracket syntax: `⊢ [attest_4](attest_1, attest_2) body
  {note}`. It is a **view**, produced from the journal and never parsed back
  in — the JSON is canonical.

- **render** — the command (and the act) of producing that view for a
  selection, in topological order.

- **judgment stroke (⊢)** — the prefix marking `state: ratified` in renders.
  Frege's sign, and display-only by ratified decision (D4): nothing ever
  parses the glyph, the journal stores the word `ratified`, and `--ascii`
  substitutes `|-`.

## The gate

- **gate** — the language compiled into executable checks: the deterministic
  program standing between model output and the record. It is *the compiler
  front-end prose never had*. It runs on every model proposal and, minus the
  repair loop, on every operator write. What it checks is **structure, not
  truth** — fidelity and meaning are the operator's job at ratification, and
  no amount of inference is allowed to take that over: *inference can inform
  the gate; it can never be the gate.*

- **artifact** — one model response as a unit: `{"statements": [...]}`,
  gated as a whole and either accepted whole or refused whole. (Note the
  collision with D6's use of the word — see [Collisions](#collisions).)

- **hard error** — a gate finding that refuses the artifact: `E_ID_FORM`,
  `E_DUP_ID`, `E_DANGLING_DEP`, `E_CYCLE`, `E_TERM_UNDEF`, `E_DEF_NO_SCOPE`,
  `E_REF_NO_ORIGIN`. Each is one rule of the language made mechanical; the
  table with plain-language readings is in
  [`02-architecture.md`](02-architecture.md) → *The gate*.

- **warning** — a finding that is reported but does not refuse. `W_DEF_ATOMICITY`
  is the only one in v0: a def body that reads multi-sentence or
  clause-conjoined is probably saying two things at once.

- **lint** — the structural check applied to an operator write (`add`,
  `amend`): the same shape rules, but no repair loop and no inference. Failing
  it journals nothing and exits `1`.

- **repair loop** — what happens when a model artifact fails the gate: the
  structured error list (`{"gate_errors": [{code, subject, detail}, …]}`) goes
  back as a follow-up turn and the model re-emits the **complete corrected
  artifact**, never a diff. At most **two** repair turns; then the run fails
  loudly — exit `1`, the rejected artifact archived, `intake_rejected`
  journaled. Never silently accepted.
  ([`spec/loadout-v0.md`](../spec/loadout-v0.md) → *The repair protocol*)

## The harness

- **harness** — the orchestration around everything else: assemble the
  context, call the model, run the gate, write the journal, drive the surface.
  Concretely a single `socrates` escript, run per-invocation, with no server
  and no long-lived processes.

- **write asymmetry** — the two unequal doors into the store. `add` (operator)
  is direct: lint only, and the statement enters **`ratified`**, because
  authorship is assent. `intake` (model) goes through the gate, enters
  **`proposed`**, and waits. *The human is direct; the model petitions.*

- **intake** — the one generative door in v0: prose in, archived verbatim, one
  model call against the loadout schema, gate with up to two repairs,
  survivors journaled as `proposed`.

- **deterministic command** — every command that is a pure function over the
  store: `init`, `add`, `amend`, `show`, `deps`, `rdeps`, `graph`, `render`,
  `ratify`, `reject`, `verify`, `log`. No network, no model.

- **inference command** — a command that calls a model. Exactly one in v0
  (`intake`); plan 0003 adds `re-prose`, `compile`, `audit`, and `roundtrip`.
  Always marked as such at the boundary.

- **boundary footer** — the last line on stderr of every command, declaring
  which kind it was: `[deterministic]`, or
  `[inference: <model> · <request-id> · <n> in / <m> out]`. The point is that
  you never have to wonder whether a model touched a result.

- **output discipline (D6)** — stdout carries only the artifact — renders,
  ids, query results — so everything pipes cleanly; footers, progress, gate
  errors, and confirmations go to stderr; status goes in exit codes.

- **exit code** — the status channel: `0` ok · `1` gate-rejected (including a
  human `add` failing lint) · `2` usage or environment error · `3` verify
  mismatch.

- **fixture client** — the canned client selected by `SOCRATES_CLIENT=fixture`:
  no key, no network, and *honest provenance* — it reports `model: fixture`
  rather than borrowing a model id. Every test and the acceptance walk run on
  it.

## Composition and measurement

Plan 0003's vocabulary — designed, not built. This is where **patch** and
**changeset** are settled, and the two are worth reading together.

- **patch** **(0003)** — *a named routing configuration over the graph.* A
  saved selector: which statements, which filter — patch cables over the
  graph, not a diff. `socrates patch new auth-story "claim_0+deps --state
  ratified"` defines one; `socrates patch auth-story` shows it and its
  compilation history.

- **changeset** **(0003)** — *a proposed set of graph changes*: new
  statements, plus the `revises` edges retiring what they replace, journaled
  as `proposed` and applied only on ratification. This is what `audit`
  produces. The word exists because the operator's earlier usage overloaded
  *patch* for it and split them in the master thread — **two concepts, two
  words**:

  > a **patch** is a named routing configuration over the graph. My earlier
  > usage (a proposed set of graph changes from `audit`) gets renamed
  > **changeset**. Two concepts, two words.

  So: a *patch* names a view and changes nothing; a *changeset* proposes a
  change and names nothing. Ratifying a changeset applies it — new statements
  enter `ratified`, the superseded one flips, edges are recorded, and nothing
  is deleted, ever.
  ([`plans/0003-composition-and-measurement.md`](../plans/0003-composition-and-measurement.md)
  → *Naming*)

- **re-prose** **(0003)** — the mirror inference: send a selected subgraph out
  and get prose back, display it, archive it, and pointedly *do not* write it
  into the store as truth.

- **compile** **(0003)** — resolve a patch's selector *now*, run `re-prose` on
  the result, and **append** a compilation instance to the patch's file: a
  header (date, selector, resolved sid set, graph digest, model, prompt
  digest, token usage) plus the prose body. Two properties fall out of the
  header — a longitudinal record of how the same argument *sounds* as the
  graph evolves, and a built-in experiment: same graph digest with different
  prose is model variance; a different digest means the argument actually
  changed.

- **audit** **(0003)** — the command that asks whether one statement is
  overloaded, and if so proposes its decomposition as a changeset. It gates
  the proposal exactly like intake output, plus one extra check: apply the
  changeset to a *copy* of the live graph and validate the result, so
  everything currently depending on the statement provably survives the split.
  Nothing in the live graph moves until ratification.

- **halt rule** **(0003)** — the discipline `audit` mechanizes: a statement
  you cannot grasp is a fault to stop on, not something to wave through
  ("ungrasped node is a hard fault"). Referred to in
  [`plans/0003`](../plans/0003-composition-and-measurement.md) and
  [`plans/0005`](../plans/0005-surfaces.md) rather than restated in full; the
  source is the master thread.

- **roundtrip** **(0003)** — the first instrument: re-prose a selection, take
  the prose back in as a shadow exchange, and structurally diff original
  against shadow (counts by type, edge counts, depth, and a statement-matching
  pass). It is regression testing for the methodology itself — the number
  moves when the spec, prompt, or model changes.

- **shadow exchange** **(0003)** — an intake flagged synthetic: gated and
  journaled like any other, but never part of the truth line. The lane that
  makes roundtrip and graded restatement possible without polluting the
  record.

- **stability score** **(0003)** — roundtrip's deterministic output: how much
  of the original graph survives the trip through prose and back. Deterministic
  by construction, so it can be trended.

- **judge-as-annotator** **(0003, docs/05)** — the settled posture on judge
  models: a judge renders opinions on unmatched pairs as *evidence attached to
  the report, never folded into the deterministic score.* A judge that
  **chooses** is rejected outright — it would put a model in judgment over the
  operator's comprehension, which is the deference dynamic rebuilt one level
  up. ([`docs/05-restatement.md`](05-restatement.md) §5)

- **restate** **(docs/05)** — the proposed command in which the *operator*
  writes a selection back into prose from memory, and it is journaled as
  evidence of comprehension. The missing quadrant beside `intake` (model
  reads, model writes) and `re-prose`.

- **reconstitute** **(docs/05)** — the operator's own word, kept for the
  general concept: rebuilding prose from the graph, in either author's hands.
  `re-prose` is the model's arm of it, `restate` the operator's.

- **closed book** **(docs/05)** — the default and the point of `restate`: the
  render is *not* shown while the operator writes. What a diff then finds is
  located comprehension debt — statements forgotten, dep edges never
  registered, a want recalled as a fact, or **confabulation** (a commitment in
  the operator's head that the ledger never made).

- **anti-parrot lint** **(docs/05)** — a deterministic, deliberately dumb
  check on a restatement: refuse it when token overlap with the rendered
  bodies exceeds a threshold. It catches transcription and is honest about not
  catching paraphrase-without-understanding.

## Agency

Plan 0004's vocabulary — designed, not built.

- **policy table** **(0004)** — the deterministic decision layer for proposed
  acts: **a table, not a model**, versioned as data in the repo, keyed by
  effect class, journaled when it changes. It decides auto-execute /
  require-ratify / reject, and it sees only proposals the gate has already
  validated.

- **effect class** **(0004)** — what an act *does*, as a type rather than an
  opaque string: read, store-append, workspace write, external-irreversible.
  The distinguishing claim against string-approval harnesses: a policy engine
  can key on a typed effect, but nobody can inspect `bash -c "..."` — which is
  why existing tools have no choice but to ask a human to eyeball it.

- **plan-envelope ratification** **(0004)** — the answer to approval-prompt
  hell: the operator ratifies a *set* of dependency-linked proposed acts once,
  up front; the loop then runs autonomously inside that envelope, and only a
  proposal *outside* it pauses for a new ratification.

- **verifier** **(0004)** — a second model with no pen: fresh context,
  adversarial by system prompt ("attempt to refute; when uncertain, refute"),
  given the proposal, the intent statements it claims to serve, and the source
  prose — and deliberately *not* the proposer's reasoning. Its findings enter
  the graph with dep edges to what they assess, so verification lives in the
  graph rather than beside it. A verifier that wants to agree is a rubber
  stamp with extra tokens.

- **byte-surface minimization** **(0004)** — the rule that the less
  model-generated text becomes bytes on disk, the less can be silently
  corrupted: never have the model *re-say* content that exists — have it
  *point at* what should change. For the store, stronger: the model produces
  objects, and dumb code turns objects into bytes.

## Surfaces

Plan 0005's vocabulary — designed, not built.

- **view** **(0005)** — the governing rule for every editor surface: *the
  buffer is a view over the store, never the truth.* Buffers like
  `socrates://staging` and `socrates://exchange/7` render the store; the store
  changes only through the app's own writes.

- **extmark** **(0005)** — nvim's editor-maintained annotation, moved with the
  text through every edit. Load-bearing because it binds a screen line to a
  `sid` in a way that survives editing — which is what makes "press a key on
  this line to ratify *this statement*" possible at all. Files have no
  analogue; the language-server equivalent is a view-position-to-sid mapping,
  the same problem source maps solve.

## Instrumentation

Plan 0006's vocabulary — designed, not built.

- **canary** **(0006)** — the rejection rate, watched as the system's alarm
  against its own hollowing-out: *if sustained rejection rate falls to ~zero,
  either the model became perfect or the reading stopped — and only one of
  those is plausible.* Collapsing ratification latency (bulk-instant
  approvals) is the same tell. When it trips, the honest response is not more
  friction but surfacing the number: *you have stopped reading.*

- **stats** **(0006)** — the deterministic command reporting the instrument
  series: gate-pass rate, error-code distribution, repair-loop convergence,
  per-type acceptance rates, ratification latency — with canary thresholds as
  config, not judgment. Cheap to build because the journal already records
  everything it reads.

## Repo vocabulary

- **canon/** — operator-authored, verbatim, canonical. Purpose and the two
  seed examples; never normalized, condensed, re-wrapped, or repaired.
  Annotations sit outside the verbatim block.

- **plans/** — where decisions are made. Numbered by through-line (0001–0006),
  each carrying a status: **ratified** (0001, the first build), **proposed**
  (0003, next), or **deferred**.

- **spec/** — what binds the build: the CLI interface and the worked scenarios,
  read together. Normative for v0.

- **docs/** — this folder: explanation and research, explicitly non-normative.
  It translates decisions; it does not make them.

- **analyses/** — dated write-ups answering a specific operator question
  against the repo as it stands. Neither canon nor plan.

- **master thread** — the founding session this repo descends from, captured
  verbatim outside it (`direction → socrates_2/threads/2026-08-05-master-thread.md`).
  Blocks quoted from it in the plans are marked `<!-- verbatim: master-thread -->`
  and are the authority for the design language they carry — including the
  patch/changeset split.

- **decision (D*n*)** — a numbered, ratified build decision in plan 0001,
  cited by number throughout (D4: `⊢` is display-only · D5: the six-type set ·
  D6: output discipline · D7: app-assigned, store-global display identity).
  Decisions the build itself surfaced are logged in
  [`plans/0001-build-notes.md`](../plans/0001-build-notes.md), proposed for
  ratification.

- **milestone (M*n*)** — a build stage within plan 0001: M0 scaffold and
  loadout · M1 journal and human write path · M2 graph, gate, verify · M3
  client and intake · M4 amend and finish. Notably, the human door ships
  before any API key is needed.

## Collisions

Words this repo uses in more than one sense, and how to tell which is meant.

- **patch** — in socrates, a *named selector* (0003), which changes nothing.
  In ordinary engineering talk about this repo's own code — "the R-findings
  patch," "a workspace-file patch" — the git sense, a diff. The socrates sense
  is the one that needed the *changeset* rename to protect it; when a document
  is discussing the store, read it as the selector.

- **artifact** — the model's one JSON response, as the gate sees it; but under
  D6, "stdout carries only the artifact" means the *useful output* (a render,
  an id, query results). Gate-speak versus output-discipline-speak.

- **audit** — [`plans/0001-audit.md`](../plans/0001-audit.md) is a *document*:
  the adversarial pre-build review of plan 0001. `socrates audit` **(0003)**
  is a *command* that proposes decomposing an overloaded statement. Unrelated,
  beyond both being skeptical.

- **verify / verifier** — `verify` is deterministic, offline, and built: it
  re-hashes archives. The **verifier** **(0004)** is a second model, adversarial
  and inferential. One never calls a model; the other is nothing but.

- **def** — a statement type, and also the LSP verb (`go-to-definition`) plan
  0005 maps onto it. The pun is intentional and noted there: the protocol verb
  and the socrates noun are literally the same word.

- **definition** — a `def` statement in the store versus `definitions.json`,
  the derived export of ratified *global* defs only. Local defs are real defs
  and never appear in the file.

- **claim** — the type name used throughout `canon/`, superseded by `attest`
  under D5. Canon is preserved verbatim rather than updated, so `[claim_2]`
  there intakes as an `attest` today. Expect the older word in canon and in
  master-thread quotes; expect `attest` everywhere else.

- **note** — three uses: a statement's `{}` meta-channel; `--note` on
  `reject`, which journals the operator's reason; and "build notes," a plan
  document. Only the first is a field on a statement.

- **plan** — a numbered document in `plans/`, and also **(0004)** a ratified
  envelope of proposed acts. The second sense only appears in agency contexts.
