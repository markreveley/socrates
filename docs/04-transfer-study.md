---
title: "Docs — transfer study: the docs and the code's intent, expressed in socrates"
status: explanatory — non-normative; a study, not a plan. Worked examples were walked through the built gate in scratch stores; nothing here writes to any store, and nothing here is ratified.
date: 2026-08-05
companion: plans/0001-post-build-review.md (the review this study was filed with)
---

# Transfer study — could the docs and the code live in socrates?

The question, in two halves: what would a supplementary set of docs look
like that *transfers* some of this repo's documentation into socrates
statements — and could the intent behind the code and architecture be
expressed the same way?

The short answer to both: **yes, for the parts that are commitments; no,
for the parts that are teaching — and the transfer cannot be performed by
an agent at all.** The long answer is this document. Every bracket-notation
example below was authored through the built escript in a scratch store and
gates clean; renders are pasted verbatim.

## 1. The system already answers *how* — there is no bulk import

Before asking what a transfer looks like, notice that the repo's own
constitution dictates the mechanics, and they are not the mechanics of a
migration script:

- There are exactly two doors into a store. `add` — the operator, entering
  `ratified`, because **authorship is assent**. `intake` — the model,
  entering `proposed`, waiting.
- An agent therefore cannot manufacture the ratified layer. A `.socrates/`
  store fabricated by an agent out of the docs would carry
  `author: operator` on statements the operator never wrote — fabricated
  assent, in the one system whose entire point is that assent is the
  scarce, honest resource. (This study's scratch stores are demonstrations
  and were discarded, not committed.)
- So "a supplementary set of docs in socrates" is **not a writing
  deliverable. It is a ratification workload.** Either the operator
  authors statements directly (`add`), or the docs pass through `intake`
  and the operator ratifies the survivors one at a time. Both paths are
  bounded by the operator's real reading speed — and if the transfer goes
  *fast*, that is not efficiency, that is the rubber stamp, and plan
  0006's canary should read a bulk-ratified transfer as its first true
  positive.

Two corollaries worth the price of the whole study:

1. **The transfer is the dogfood start.** Plan 0001's store section pins
   the dogfood store as "this repo, committed"; M1's promise was
   "socrates-in-socrates"; no `.socrates/` exists yet. Transferring the
   purpose argument and the design decisions *is* "start building socrates
   with socrates" — there is no separate, more official beginning waiting.
2. **The transfer is the first experiment.** Intaking real repo prose
   produces the first non-fixture gate-pass rates, repair convergence
   numbers, and ratification labels — plan 0006's instruments get their
   first real data from exactly this workload.

## 2. What transfers, what resists

The repo's content sorts cleanly by fate:

| Content | Fate under transfer | Native form |
|---|---|---|
| Coined vocabulary (gate, loadout, exchange, sid, ratify, supersession, …) | **transfers first, pays most** | `def`, mostly `:global` |
| The invariant and the purpose argument | transfers well | `attest` / `infer` / `act` |
| Ratified decisions D1–D7; build notes N1–N32 | transfers almost mechanically | `act` (+ `did` for what was built) |
| Canon | **never decomposed in place** — verbatim-frozen | `ref` (file origin, sha256'd) + attests depending on it |
| Research-spike claims and verdicts | transfers, expensively | `ref` (url) + `attest`/`infer` |
| The tutorial; docs prose as prose | **stays prose** | — |
| spec/cli-v0, loadout tables | stays spec | — |
| The code | stays code; its *intent* transfers | see §4 |

Three of these rows deserve their reasons spelled out.

**Defs pay compounding interest.** A ratified `:global` def does something
no other statement type does: it enters `definitions.json` and the system
prompt of **every future intake**. Transferring the repo's lexicon is not
bookkeeping — it directly improves every subsequent decomposition the
model performs, and it arms `E_TERM_UNDEF` for design language (the
review's R3 probe shows the term discipline has teeth). This is the one
transfer wave where the tool measurably feeds itself.

**Canon transfers as anchor, not as content.** Canon files are
verbatim-frozen; decomposing them in place is forbidden by their own front
matter. The native move: each canon file becomes a `ref` with a `file:`
origin — which `verify` then re-hashes forever, so **the transfer puts
canon's bytes under tamper-evidence as a side effect** — and the
decomposed claims enter as attests depending on that ref. The canonical
example already models this shape: statements depending on a def minted
elsewhere.

**The tutorial must not transfer.** Its value is sequence, voice, worked
traces — the fluency socrates deliberately trades away. A statement graph
of the walkthrough would be strictly worse at the walkthrough's job.
socrates re-denominates *commitments*, not *teaching*; the honest design
is a two-layer documentation system (prose that explains, over a graph
that commits), not a conversion of one into the other.

Note also what the repo's filing culture already is: the audit's A1–E, the
build notes' N1–N32, the spike's T1–T12/L1–L6 — numbered findings with
statuses and informal dependency structure. The documents have been
converging on socrates' shape from the start. The transfer formalizes an
existing practice; it does not impose a foreign one.

## 3. Worked example A — the purpose argument

docs/01-purpose.md § "the problem" and § "the bet," decomposed. Authored
through the escript in a scratch store; the render is verbatim:

```
⊢ [attest_1] a model produces a plausible design, plan, or module in seconds
⊢ [attest_2] genuinely understanding such an artifact takes minutes to hours
⊢ [attest_3] the system under construction exists twice: in the repo and in the operator's head
⊢ [attest_4] chat-paced building pulls the two copies apart faster than the operator can reconcile them
⊢ [attest_5] once output can no longer be checked against one's own understanding, the cheap move is assuming the model knows what it is doing
⊢ [attest_6] review can catch bad output; nothing tracks whether the reader understood it
⊢ [attest_7] i want to remain the author of the systems i build
⊢ [infer_1](attest_1, attest_2) in a chat loop the operator is permanently downstream of a firehose
⊢ [infer_2](attest_3, attest_4) the operator's mental model drifts from the reality
⊢ [infer_3](infer_1, infer_2, attest_5) drift decays into default approval; the approval is theater
⊢ [infer_4](infer_1, infer_3, attest_6) the scarce resource is human comprehension, not model output quality
⊢ [act_1](infer_4, attest_7) build the tool that moves at the pace of ratified comprehension: typed statements, a deterministic gate, operator-only state
⊢ [act_2](act_1) denominate progress in statements ratified, not tokens generated
```

(⊢ appears because the scratch walk used `add`; through `intake` the same
statements would render unmarked and wait.)

What the decomposition exposed that the prose kept implicit:

- **The typed is/ought rule forced a confession.** `act_1` is the bet —
  and under the loadout's rule that an act's deps should trace to an
  attested want, it would not stand on `infer_4` alone. The prose of
  docs/01 rides from diagnosis to prescription on rhetoric; the type
  system demanded the conative premise, and `attest_7` ("i want to remain
  the author of the systems i build") had to be surfaced from canon's
  subtext and *attested*. The transfer did to the purpose doc exactly what
  the research spike's L5 says the type system does: it made the is/ought
  boundary visible and lintable — and the purpose argument is stronger
  with its want on the record.
- **`rdeps` works as advertised on real content.** In the scratch store,
  `rdeps attest_5 --all` (the deference observation) returns `infer_3,
  infer_4, act_1, act_2` — "if default-approval turns out to be wrong or
  fixable some other way, the entire bet is downstream" is now a query,
  not a paragraph. That is the *Phaedrus* answer applied to the repo's own
  founding argument.
- **Authoring friction is real and informative.** Hand-authoring thirteen
  dep-linked statements required tracking per-type indices across
  interleaved adds; this study's first walk mis-numbered a dep and the
  lint refused it (`E_DANGLING_DEP`, nothing journaled). The tool prints
  each assigned id precisely because the author must read them back.
  Thirteen statements took roughly as long as reading docs/01 §problem
  twice — the cost the system promises, delivered on its own material.

Cost extrapolation: docs/01 in full decomposes to roughly 40–60 statements
(the sections not shown add the usual-answers rebuttals, the four
commitments, the falsifiability claims). At ratification-pace that is an
afternoon, not a script run — and per §1, that is the feature.

## 4. Worked example B — code intent: the D7 cluster

The architecture question — could the intent behind the code be expressed
in socrates? — tested on the deepest decision the audit produced, D7
(display identity is app-assigned and store-global; deps are sid-edges).
Scratch-store render, verbatim:

```
⊢ [def_1] *sid* : the permanent identity of one statement: a ULID the app mints at write time
⊢ [def_2] *display id* : the human-facing name of a statement, formed type_n, assigned by the app
⊢ [attest_1] models name their artifact statements with ids meaningful only inside that artifact
⊢ [attest_2] two artifacts can carry the same statement names over different content
⊢ [attest_3] only the app sees every name ever used in the store
⊢ [infer_1](attest_1, attest_2) model-chosen names cannot serve as store identity
⊢ [act_1](infer_1, attest_3, def_2) at acceptance the app assigns each statement its final *display id*, next free index per type, and journals the artifact-to-store mapping
⊢ [act_2](infer_1, def_1, def_2) dep edges are stored as *sid* edges resolved at write time; a *display id* is view-layer and stays with a revises chain
⊢ [did_1](act_1, act_2) plan 0001 ratified D7 on 2026-08-05 and the build implemented it: acceptance renumbering in the intake path, sid resolution at both write doors
```

- **"Why is the code shaped this way" becomes a closure query.** In the
  scratch store, `deps did_1 --all` walks from the build record back
  through both design acts to the audit's diagnosis and the two
  definitions — nine statements that answer, mechanically, the question a
  new contributor currently answers by reading audit §A1 (a page) plus
  plan 0001 §Store plus the D7 decision text. The prose stays the better
  *teacher*; the graph is the better *witness*.
- **The defs export worked immediately:** the two `:global` defs entered
  ratified at `add` (authorship is assent) and were promoted into
  `definitions.json` on the spot — meaning the very next `intake` could
  dep on `def_1`/`def_2` by id. Code-intent defs and prose-decomposition
  defs land in the same lexicon; the two halves of the transfer share one
  foundation.
- **`did` is the type that makes code intent honest.** Design intent
  without a record of what was actually done is aspiration. The
  `act → did` pair — already ratified in D5, waiting for plan 0004's
  machinery — works *today* for build history: the act is the commitment,
  the did is the receipt, and the did's body names the code surfaces
  (`accept_artifact`, `resolve_deps`) that discharge it.
- **One wrinkle the example surfaced: do not `ref` living code files.**
  A ref's `file:` origin is sha256'd and re-checked by `verify` — pinning
  bytes is exactly right for canon and archived sources, and exactly wrong
  for `lib/**`, where every future edit would turn `verify` red. Anchors
  into code should be carried in bodies and notes (function names, as
  `did_1` does), or as refs to *stable* objects — plan sections, commit
  hashes as `quote`/`url` origins — never as digests of files that are
  supposed to change.

The natural corpus for a fuller code-intent transfer already exists:
`plans/0001-build-notes.md` is **thirty-two numbered statements filed "for
operator ratification"** — N1–N32 are socrates statements in prose
clothing, down to the status field. A build-notes intake would be the
least-forced first use of the model door on real material. The invariant's
three clauses, the write asymmetry, the client-honesty rules (raw bytes,
never `json:`; footer reports what ran), and the journal's
never-silently-skip rule complete the load-bearing set — roughly 25
statements before granularity stops paying.

## 5. The supplementary layer, concretely

What "a supplementary set of docs in socrates" would physically be:

1. **The store**: `.socrates/` at repo root, committed — precisely as plan
   0001 already pins. The transfer does not need a new mechanism, a new
   plan number, or new syntax. Everything below runs on the shipped v0.
   (One toggle: `.gitignore` currently excludes `/.socrates/`, with a
   comment correctly reserving initialization to the operator; when the
   store starts, that line comes out, or the plan's "committed" cannot
   happen.)
2. **Wave 1 — the lexicon** (~20 defs, operator-authored, `:global` where
   the term is repo-wide). Candidates, harvested from the docs: statement,
   exchange, gate, loadout, harness, store, journal, sid, display id,
   ratification, supersession, provenance, intake, repair loop, operator,
   the canary, plan envelope, byte-surface minimization — plus canon's own
   *representation ratification*, the def the acceptance walk already
   mints. Ordering note from the review (R3): as built, a def body cannot
   use its own term at `add`, and mutually-referring defs need
   add-then-amend — author term-free bodies first.
3. **Wave 2 — the purpose argument** (§3's example completed, ~40–60
   statements): either operator-authored or intaken from docs/01 slices
   and ratified. Canon files enter as sha256'd refs here, putting their
   verbatim guarantee under `verify`.
4. **Wave 3 — decisions and code intent** (~25 statements): D1–D7 as
   act/did pairs (§4's shape), the invariant, the write asymmetry, and the
   ratification-worthy subset of N1–N32 — which doubles as finally
   dispatching the build notes' "proposed" status through the system they
   describe.
5. **Wave 4 — optional, expensive**: research-spike scorecard rows as
   attests with url-refs. Defer until the store has proven itself; ninety
   citations is completionism, and only defs feed the prompt anyway.
6. **Views, not files**: the "supplementary docs" a reader browses are
   renders — `socrates render @2 > docs/…` snapshots at first, and plan
   0003's patches (named selectors, compiled prose, append-only history)
   as soon as they exist; the patch mechanism is *literally* this
   feature. Like `definitions.json`, rendered views are derived exports:
   regenerated, never hand-edited, never authority.
7. **Prose cites the graph**: docs/ keeps explaining, and starts citing
   display ids where it states a commitment. A cheap deterministic lint —
   every cited id exists and is live — gives the docs the property nothing
   else can: **mechanical staleness detection.** A doc that cites a
   superseded statement fails the lint the moment the graph moves. That
   is the mental-model-drift defense, turned on the repo's own prose.

## 6. What the graph buys — and what it costs

**Buys:**

- Interrogability of purpose and design: "what rests on this?" as a query
  (§3's `rdeps`, §4's `deps --all`) instead of archaeology.
- A lexicon that compounds: every ratified global def improves every
  future intake (§2).
- Decision history with supersession: when 0002 amends the journal's
  field set, the D-cluster statements are amended, the old intent stays
  queryable, and "why did we believe that in August" is `show` on a
  superseded sid.
- The term discipline on design language: `E_TERM_UNDEF` refuses undefined
  jargon in future design statements the way it refuses coinage IOUs.
- Instrument data from day one (§1, corollary 2).
- Prose-to-graph staleness lint (§5.7).

**Costs, honestly:**

- **The sync burden is real and is the risk.** An intent layer that is not
  amended when decisions change rots into exactly the drift this system
  exists to fight — a second mental model to keep honest. Mitigations, in
  order of cheapness: keep the core small (~25 load-bearing statements,
  not 100+); the citation lint; the amend-on-change discipline that
  supersession makes cheap. The tutorial's defense (executable exercises)
  does not apply here; only use does.
- **Ratification fatigue at transfer scale.** T5's volume warning applies
  to the transfer itself: waves exist so no session ratifies a hundred
  statements. If wave 2 gets bulk-approved in minutes, the canary fired —
  see §1.
- **Shadow normativity.** Once ratified statements about design exist, a
  precedence question appears: plans decide, or the store does? The clean
  rule for now, consistent with the repo's layering: **plans decide; the
  store records the deciding** — acts/dids point at plan sections, and the
  store becomes the queryable index of decisions, not a rival authority.
  Revisit when plan 0003's changesets make graph-first decisions natural.
- **Prompt growth**: every global def rides in every intake's system
  prompt. Twenty-five defs is nothing; hundreds would need scoping
  discipline (`:local`, or 0003 selectors). A def is a small tax on every
  future inference — one more reason wave 1 is curated, not exhaustive.

## 7. Summary

The transfer is possible, valuable, and already fully specified by the
system's own rules. Its natural form is not a parallel documentation set
but the long-promised dogfood store plus derived renders: defs first
(they feed the tool), the purpose argument and the decision record next
(they are the load-bearing commitments), canon as tamper-evident anchors,
the tutorial and specs left as the prose they should remain. The mechanics
are the two doors that exist today; the cost is the operator's reading, by
design; the first measurable benefit is a lexicon every future intake
inherits; and the deepest one is that the repo's founding argument and its
architecture become things you can *ask questions of* — which is the claim
this system was built to make good on.
