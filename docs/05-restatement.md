---
title: "Docs — restatement: the operator's mirror"
status: >
  explanatory — non-normative; a design response to an operator prompt, filed
  for operator review. Nothing here is ratified; plans decide. Citation rule
  as in the spike: every citation new to this document was verified against
  the publisher or primary page on 2026-08-05; citations carried from
  docs/03-research-spike.md are referenced by claim id (T-number) rather than
  re-cited, and inherit that document's verification.
authorship: agent-drafted for operator review; the §0 block is operator-verbatim
date: 2026-08-05
companion: >
  operator_next_steps.md (failure mode 2 — the prompt's subject),
  docs/03-research-spike.md (T5, T6, §7 findings 2–3),
  plans/0003-composition-and-measurement.md (re-prose, compile, roundtrip),
  plans/0006-instrumentation.md (the canary)
---

# Restatement — the operator's mirror

## 0. The prompt, verbatim

Operator message, 2026-08-05, received against this repo. Everything inside
the rules is verbatim — not normalized, not repaired. The first content line
quotes `operator_next_steps.md` failure mode 2 back at the repo; "documented
at least as an intention" is plan 0003's `re-prose`.

---

See repo, and consider:

Ratification fatigue — the decomposition is fine but the pace collapses into rubber-stamping (T5 at volume).

What if the way to avoid this is to force prose sunmaries of status, festures, intent as part of the socrates process? There is a point in the process that was documented at least as an intention where socratic patches and statements could then be reconstituted by the model. What of part of the process was the operate being forced to reconstitute themselves, and it being commited to the ledger as evidence of comprehension (or lack thereof? An ongoing eval could be operator reconstituted, then 2-3 model generations also being done, than a judge model choosing. Maybe thats over engineering for many uses but viable for high impact

---

The verdict in one line: **sound, and better than sound — it is the missing
fourth quadrant of the system's own symmetry, and it closes the two gaps the
research spike names and leaves open; but the judge-model version inverts the
invariant and must be corrected to judge-as-annotator, and dosage is
everything — applied per statement it would re-create T5-at-volume in a more
expensive key.**

## 1. The gap it names: ratification asserts comprehension; nothing demonstrates it

Ratification is a **recognition task**: the operator reads a statement the
model produced and judges it. The spike's T5 verdict is precisely about
recognition at volume — "supported as mechanism, resisted as sufficient" —
and the resistance evidence (Ye et al.'s 94% missed sabotage,
Grunde-McLaughlin's confidence-without-accuracy, Mackworth's vigilance
decrement; all spike-verified under T5) is evidence about a human *judging a
stream of mostly-correct items*. The decay curve belongs to the task class.

What the system never asks for, anywhere, is **production**: the operator
saying, in their own words, what the graph says. The `⊢` records that the
operator judged; it cannot record whether the judging was reading.
"Authorship is assent" has a quieter twin the build leans on without
checking — *assent implies comprehension* — and canon §3's own phrase, "the
pace of approvals and ratification **after proper comprehension**," is
enforced by the build only in its first half. The pace is forced; "proper
comprehension" is taken on the operator's word.

The instrumentation plan knows this. The canary detects **stopped** reading
(rejections at zero, latency collapse); the spike's §7 finding 3 concedes it
cannot detect **shallow** reading, and finding 2 warns that the canary's own
alert, repeated identically, gets tuned out by the second exposure. The two
named gaps are exactly the ones an operator restatement closes: it is a
direct probe of shallow reading (not "did you click slowly enough" but "can
you say it back"), and it is a different stimulus class from a banner — the
varied surface finding 2 asks for.

One more framing, from the README's own lineage line: the elenchus "attacks
unearned confidence in one's own understanding." As built, the system aims
that attack only at the model's output. The operator — the one participant
whose comprehension the whole system exists to protect — is never once
questioned. Restatement turns the elenchus on the operator. That is arguably
what the name promised.

## 2. The evidence: production is both the better learning event and the better measurement

The spike already carries the foundation under T4: the generation effect
(Slamecka & Graf 1978) and Gajos & Mamykina's finding that only people made
to reach their own conclusion learned. Four additions, each verified against
the primary page for this document:

- **The illusion of explanatory depth.**
  [Rozenblit & Keil 2002](https://onlinelibrary.wiley.com/doi/abs/10.1207/s15516709cog2605_1)
  (*Cognitive Science* 26, 521–562): people believe they understand systems
  "with far greater precision, coherence, and depth than they really do,"
  and the illusion is strongest for exactly the kind of mechanistic,
  explanatory knowledge a statement graph encodes. The measurement
  instrument in those studies is the intervention proposed here: *asking for
  the explanation*. Canon's claim_2 names "sounds like you know what you're
  doing" as the operator's failure about the **agent**; Rozenblit & Keil
  document the same failure about **oneself**. Ratification without
  restatement leaves the second failure untouched.
- **The testing effect.**
  [Roediger & Karpicke 2006](https://journals.sagepub.com/doi/10.1111/j.1467-9280.2006.01693.x)
  (*Psychological Science*): free-recall testing beats restudying for
  delayed retention. A test is simultaneously a measurement and a
  strengthening of the thing measured — a restatement is not overhead beside
  comprehension work, it *is* comprehension work, of the highest-yield kind.
- **Self-explanation.**
  [Chi et al. 1989](https://onlinelibrary.wiley.com/doi/abs/10.1207/s15516709cog1302_1)
  (*Cognitive Science* 13, 145–182): good learners generate explanations and
  monitor their own understanding accurately; poor learners generate few and
  monitor *inaccurately* — precisely the pairing that makes self-assessed
  comprehension ("I read it, I get it, ratify") untrustworthy and produced
  explanation informative.
- **Teach-back, at stakes.**
  [Schillinger et al. 2003](https://pubmed.ncbi.nlm.nih.gov/12523921/)
  (*Arch Intern Med* 163(1):83–90, "Closing the loop"): physicians assessed
  patient recall or comprehension of new concepts in 12% of new concepts
  (20% of visits); patients whose physicians did were markedly more likely
  to have glycemic control below the mean (adjusted OR 15.15, *P* < .01;
  observational, not causal). Medicine institutionalized restate-in-your-
  own-words — the teach-back method — where misunderstanding kills. The
  asymmetry to copy: the standard of proof is *own words*, not read-back;
  verbatim parroting is the degenerate form.

The mechanism claim, stated plainly: recognition at volume decays
(vigilance); production does not inherit that decay because it is a
different task on a different channel — but it costs proportionally more
per unit, which is why §6 (dosage) is where this proposal is won or lost.

And one property recognition can never have: a recognition task audits only
**what is shown**. A restatement exposes the operator's whole working model,
including its fabrications — commitments the operator believes were made
that the ledger never recorded. That is T1's drift caught in the act, from
the side ratification cannot see (§4's last diff class).

## 3. The missing quadrant

Two directions × two authors. Three quadrants exist or are designed; the
prompt names the fourth:

| | prose → statements | statements → prose |
|---|---|---|
| **model** | `intake` — gated, enters `proposed`, waits | `re-prose` (plan 0003) — archived, "pointedly does *not* write it into the store as truth" |
| **operator** | `add` — direct, enters `ratified`; authorship is assent | **`restate` — this proposal**: journaled, archived, *evidence of comprehension (or lack thereof)* |

The symmetry is not decorative. Each row keeps its author's asymmetry: the
model's mirror output is archived and powerless; the operator's is evidence
that binds. Each column keeps its direction's honesty rule: nothing enters
the truth line rightward, nothing *is* truth leftward.

Name: `restate` is used throughout this document — `re-prose` is taken by
the model's mirror, and "restate" carries the own-words connotation
teach-back requires. The operator's word *reconstitute* is kept for the
concept: rebuilding prose from the graph, in either author's hands.

On the prompt's "status, festures, intent": the type system already carves
these. Status is the `did` layer; intent is the `act` layer with its
conative deps; features are the ratified `attest`/`infer` mass. Plan 0003's
selector grammar anticipates `--type` — *"restate the acts of @4"* is
plan-envelope comprehension as a command, and the strongest high-impact
form: before acts execute (plan 0004's horizon), the operator saying in
their own words what is about to be done and why.

## 4. Mechanics: what "committed to the ledger" means

Nothing here needs machinery the plans don't already draw. Sketch, in 0003's
vocabulary:

```
socrates restate <selector> [--grade]
```

1. Resolve the selector; snapshot the resolved sid set and graph digest —
   exactly `compile`'s header fields.
2. Collect operator prose (stdin or `$EDITOR`), **with the render not
   shown** — closed book is the default and the point.
3. Archive it write-once beside the exchange's sources; journal a
   `restated` event: selector, sid set, graph digest, archive digest,
   author operator. Deterministic; footer `[deterministic]`.
4. `--grade` (one inference, footered as such): shadow-intake the
   restatement — 0003's synthetic lane, never the truth line — and run the
   **deterministic structural diff** against the source subgraph. This is
   roundtrip with inference one replaced by the operator: *cheaper than
   roundtrip* (one model call, not two), on machinery 0003 fully specifies.

The prompt's parenthesis — "(or lack thereof" — is the load-bearing half,
and the diff is what makes lack-thereof *located* rather than felt:

| Diff finding | Reading |
|---|---|
| statement in graph, absent from restatement | forgotten — not in the working model |
| dep edge absent | a connection never registered — "what does this rest on?" failed silently |
| type mismatch (an `act` recalled as an `attest`; a want recalled as a fact) | modal smuggling in recall — the is/ought discipline applied to memory |
| `E_TERM_UNDEF` on the shadow intake | a term the operator uses but did not define — the gate refusing the operator's own mental IOU |
| statement in restatement, absent from graph | **confabulation** — the mental model carries commitments the ledger never made; drift caught in the act |

Every row points at sids. This is `operator_next_steps.md` §4's
clarification-event log, mechanized and aimed at the operator's own state —
and every restatement is a new entry in 0006's labeled dataset, this time
with a human-*generation* arm, not just human judgment.

Two placement rules, both already settled elsewhere: restatements are
journal events plus archives, **never statements in the truth graph**
(next_steps §4 deferred meta/object mixing; this stays deferred), and their
shadow intakes live in 0003's explicitly-synthetic lane. Longitudinally,
restatements of the same patch sit beside its compilations in the
append-only history — 0003 prizes "how the same argument *sounds* as the
graph evolves"; this adds *how the operator's understanding of it sounds*,
diffable on the same timeline.

## 5. The eval, corrected: judge as annotator, models as ceiling

The prompt's eval — operator reconstitution, then 2–3 model generations,
then "a judge model choosing" — is roundtrip plus an operator arm, which is
why it is *not* over-engineering: most of it is already designed. But two
corrections, one fatal and one reframing:

**A judge model must not choose.** "Inference can inform the gate; it can
never be the gate" (plan 0004; spike T11) — and a judge *choosing* puts a
model in judgment over the operator's comprehension, which is the deference
dynamic rebuilt at the meta level: the operator learns to write for the
judge. The judge biases are documented (Zheng et al., spike T11 —
verbosity, style, position); a judge grading prose grades prose-ness.
Plan 0003 already holds the correct posture in its own `--judge` clause:
opinions rendered on unmatched pairs, "evidence attached to the report,
never folded into the deterministic score." The eval inherits that
verbatim. **The deterministic structural diff is the score for every arm;
the judge annotates residue.**

**The model generations are not competitors; they are the open-book
ceiling.** The model arms get the graph in context; the operator restates
closed-book from memory. 2–3 generations at the same graph digest is
0003's own variance experiment ("same digest, different prose = model
variance") — they calibrate the noise floor: how much structural loss does
even an open-book reconstitution incur? The instrument is then the **gap
between the operator's stability score and the model ensemble's,
trended** — a comprehension-debt gauge with its control arm built in. If
the operator tracks the model floor, the mental model is close; a widening
gap is T1's drift, measured.

So the corrected eval, in full: operator `restate --grade`, plus N model
`re-prose` runs at the same digest, all shadow-intaken and structurally
diffed by the same deterministic machinery, judge annotations on unmatched
pairs as evidence only. Run it rarely — calibration, high-impact patches,
canary fires — exactly the register the prompt's own hedge ("viable for
high impact") proposes. Routine use gets §6's cheap tiers; the full
three-arm instrument is the occasional deep sounding.

## 6. Dosage: where the force applies

The failure to design against: restatement per ordinary statement would
re-create T5-at-volume at higher unit cost. The spike's alarm-management
evidence (T6) prescribes the shape — reduce volume, raise stakes. Four
ceremony points, escalating:

| Ceremony point | Trigger | Weight | Machinery |
|---|---|---|---|
| **exchange close** | an intake exchange's proposed queue reaches zero — v0 has no close event, but Q8 (next_steps §3) already computes the condition | 3–6 sentences, always-on | journal event + archive; zero inference |
| **patch compile** | first compilation of a patch; again when the graph digest moves | one operator instance beside the model's, in the append-only patch history | 0003 compile, operator arm |
| **canary fire** | 0006 thresholds trip | restate the last exchange | *replaces* the banner — the varied stimulus class finding 2 asks for |
| **ratify, dangerous types** | `act` and `:global` def transitions | a `--restate <text>` gloss journaled with the `state_changed` | anti-parrot lint (below); the only per-statement tier, reserved for the statements that bite |

On the canary tier, versus the spike's finding-3 candidate (seeded-defect
probes): seeding requires the system to place falsehoods in front of the
operator and watch, an adversarial move that sits oddly in a ledger whose
currency is trust, and it yields one bit (caught/missed). A restatement
yields a located gap list and deceives no one. Not exclusive — but this is
the probe that fits the system's character.

On the last tier, the anti-parrot lint is deterministic and dumb in the
gate's proud sense: reject a restatement whose token overlap with the
rendered statement bodies exceeds a threshold. It catches transcription; it
is honest about not catching paraphrase-without-understanding. That is T9's
honest limit, one layer up: **the ledger can verify that a restatement
happened and is not a copy; it cannot verify that it was closed-book, or
understood.** Cultural precedent for prose-as-signature at exactly this
tier: instruments that demand the amount written out in words — the
handwriting is not information, it is evidence of passage through a mind.

## 7. Costs, honestly

1. **Operator time — the scarcest resource, spent on the least fun task.**
   T10's cost note already budgets policy labor to the operator; this
   spends more. And T4's preference penalty applies at full strength: the
   evidence predicts this will be the most disliked feature in proportion
   to its benefit. The dosage table is the entire answer; if restatement
   leaks beyond its ceremony points it becomes the sludge Sunstein audits
   (spike T4), and plan 0006 must read restatement-skipping the way it
   reads rejection-rate collapse: a signal, surfaced, not punished.
2. **The system gates the operator for the first time.** The write
   asymmetry to date: the human is direct, the model petitions. A forced
   restatement makes the operator petition their own record at named
   moments. Defensible — "forced" is canon §3's own word, and the check is
   deterministic, no model in judgment — but it is a real change of
   character and should be ratified deliberately as such, not slipped in as
   a flag. If ratified, the asymmetry's clean phrasing becomes: *the model
   petitions the operator; the operator petitions only their own record.*
3. **Closed-book is unverifiable.** Reads (`render`, `show`) are not
   journaled, so the ledger cannot prove the render wasn't open in another
   pane. Journaling reads would make closed-book checkable and is declined
   here: read surveillance changes what the journal is. Same posture as
   authorship-is-assent — make honesty cheap and dishonesty visible-ish,
   and stop.
4. **A restatement is a snapshot.** It is evidence about the graph *at its
   header's digest*, staling exactly as compilations do; the digest field
   is the whole answer, and trend analysis must compare like digests.
5. **Meta/object separation must hold.** Restatements never enter the
   truth graph (§4); the moment they do, the store grows a second,
   self-referential layer the sync burden of which docs/04 §6 already
   priced for design statements.

## 8. The zero-build version — inside week one

`operator_next_steps.md`'s posture is *stop building and run the loop*, and
this proposal obeys it. The week-one form needs no code:

After each corpus sitting (next_steps §2), close the laptop lid and write
3–6 sentences in `dogfood-log.md` from memory: what entered, what it rests
on, what was rejected and why. Next morning, `render @<exchange>` and diff
by eye; log every miss as a clarification event — they are clarification
events, of the operator's own state, and the confabulation class (§4) is
the one to watch for.

The §7 decision point then gains a fourth question:

4. **Comprehension, directly:** did closed-book restatements surface gaps
   that ratification missed? (The morning-after diffs are the evidence.)

If yes, plan 0003's build order changes: `restate` lands with `re-prose`
rather than after it — the base command is deterministic, and its grading
costs one inference to roundtrip's two, so the operator's mirror is the
*cheaper* of the two mirrors to instrument. If no — if saying it back
surfaces nothing reading didn't — then T5's volume warning has a cheaper
answer than anyone hoped, and this document records a good idea the data
declined.

## 9. Open questions

1. Does restate-to-ratify actually *gate* `act`/`:global` def transitions,
   or remain ceremony without precondition? This is the operator-gating
   decision (§7.2) — canon-register, the operator's alone.
2. The anti-parrot lint: which overlap measure, what threshold, and what
   does its refusal display teach rather than scold?
3. Should reads ever journal? Declined in §7.3; revisit only if the
   honesty affordance visibly fails in practice.
4. Do operator restatements enter the 0006 dataset as a human-generation
   arm — and eventually serve as the reference voice `re-prose` is evaluated
   against, rather than the other way around?
5. Naming: `restate` vs the operator's `reconstitute` — settle at 0003
   ratification, with the own-words connotation as the criterion.
