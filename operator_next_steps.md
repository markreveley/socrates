---
title: "Operator next steps — running the loop on real prose"
status: advisory — agent-filed, follow-up to plans/0001-post-build-review.md and docs/04-transfer-study.md; nothing here is ratified, and only the operator can walk it
date: 2026-08-05
---

# Next steps

The recommendation in one line: **stop building and run the live loop on
dense prose you actually need to understand.** The system is verified —
98/98 tests, scenarios byte-exact from the escript — but it has never done
its job: every intake ever run was fixture-served. Acceptance step 6 (one
live intake from the built escript) is still pending, so the central
question — *does a real model produce decompositions worth ratifying?* —
has no data. Everything below is ordered around getting that data
honestly, in one week, without building anything new.

The stated intention — clarify dense technical writing for the operator —
has three distinct failure modes, and a useful exploration must separate
them:

1. **Model infidelity** — the decomposition passes the gate but betrays
   the prose (the T9 limit).
2. **Ratification fatigue** — the decomposition is fine but the pace
   collapses into rubber-stamping (T5 at volume).
3. **No comprehension gain** — the loop works but doesn't beat reading
   carefully twice (the adoption risk, T4 — the spike's weakest link).

Each corpus in §2 isolates one.

## 0. Close acceptance step 6 (~10 minutes, first)

In a scratch directory, from the built escript — the TLS path is
escript-specific (audit B1), which is the whole reason this step exists:

```
cd socrates_ && mix deps.get && MIX_ENV=prod mix escript.build
mkdir ~/live-walk && cd ~/live-walk
export ANTHROPIC_API_KEY=…
script -q acceptance-live.txt          # capture the transcript
…/socrates_/socrates init
…/socrates_/socrates add --type def --term "representation ratification" --scope global \
  --body "the operator verifying the agent's socrates rendering of operator intent before any work is done"
# put canon #1's four statements in canon-block.txt (canon/representation-ratification.md, the block between the rules)
…/socrates_/socrates intake canon-block.txt
```

Passing, per the ratified disjunction (plan 0001 → Acceptance, step 2): the
gate surfaces findings the repair loop resolves within 2 rounds, **or** the
artifact passes clean with the coined term defined. Then `ratify` what
deserves it, `verify`, `log`. Save the transcript and note the result in
`plans/0001-build-notes.md` § Acceptance (the one-line edit is yours to
make — the notes currently say, honestly, that no live run existed).

While you are there, the first real numbers fall out for free: did the
live model trip `E_TERM_UNDEF` as the fixture scripts it, or mint the def
unprompted (the audit's A3 predicted both are plausible)? Either answer is
the first calibration point for everything below.

## 1. Start the real store

The dogfood store is plan-pinned as this repo, committed. Two moves:

1. Remove the `/.socrates/` line from `.gitignore` (its comment already
   says initialization is yours, after accepting the build — this is that
   moment).
2. `socrates init` at repo root; commit the store with a message that says
   dogfooding starts.

Then **wave 1 of the transfer study** (docs/04 §5): author the lexicon
directly — ~20 `add --type def` commands, `:global` for repo-wide terms
(statement, exchange, gate, loadout, journal, sid, display id,
ratification, supersession, provenance, intake, repair loop, the canary…).
Authorship is assent; this is an afternoon of writing definitions you
already hold. Ordering note from the review (R3): a def body cannot use
its own term at `add`, and mutually-referring defs need add-then-amend —
author term-free bodies first. Every def ratified here rides in the system
prompt of every intake in §2.

## 2. The three-corpus experiment (one slice each, one sitting each)

| Corpus | What it tests | Slice |
|---|---|---|
| **Familiar** — a docs/01 section (transfer study wave 2) | calibration: you can judge fidelity instantly on prose you reviewed | § "the problem" |
| **Your backlog** — a master-thread slice | the intended use (canon §4's dream: unpack the master thread progressively); clarification value on your own dense material | one insight-cluster |
| **Foreign** — dense prose you need but didn't write | the honest test: does decompose-and-ratify beat reading it twice? | e.g. the OTP/GenServer material plan 0004 will need, or one spike-cited paper's core section |

Slicing rules (intake takes whole files; there is no partial-file
selector): 300–800 words, one topic per slice, plain text, saved anywhere
outside `.socrates/` (the store archives the bytes verbatim regardless — a
`corpus/` directory at root works if you want re-runnable slices in the
repo). For each slice: `intake`, read the render, then ratify or reject
**statement by statement, with `--note` on every reject** — early honest
rejections are not failure, they are the canary's baseline, and rejection
notes are the labeled dataset plan 0006 wants.

Model comparison, if curiosity strikes: re-run the same slice under
`SOCRATES_MODEL=<other-id>` in a *scratch* store, not the dogfood store —
provenance stays honest either way, but the committed graph should carry
one canonical decomposition per slice, not near-duplicates.

## 3. Measure — a tested crib sheet

All from the journal, no new code. Each of these was run against a real
walk store before being written down. From the store root:

```
# Q1 — event counts (the week at a glance)
jq -r '.event' .socrates/journal.jsonl | sort | uniq -c

# Q2 — canary baseline: state transitions
jq -r 'select(.event=="state_changed") | .state' .socrates/journal.jsonl | sort | uniq -c

# Q3 — ratification bursts: same-second runs are the latency-collapse tell
jq -r 'select(.event=="state_changed") | "\(.ts) \(.state) \(.sid)"' .socrates/journal.jsonl

# Q4 — repair convergence: k calls = k-1 repairs
jq -r 'select(.event=="statement_added" and .statement.provenance != null) | "@\(.statement.exchange) \(.statement.provenance.calls | length) calls accepted"' .socrates/journal.jsonl | sort -u
jq -r 'select(.event=="intake_rejected") | "@\(.exchange) \(.calls | length) calls rejected"' .socrates/journal.jsonl

# Q5 — gate-error distribution on rejections
jq -r 'select(.event=="intake_rejected") | .errors[].code' .socrates/journal.jsonl | sort | uniq -c

# Q6 — cost per call (model, tokens)
jq -r 'select(.event=="statement_added" and .statement.provenance != null) | .statement.exchange as $e | .statement.provenance.calls[] | "@\($e) call \(.n) \(.model) \(.usage.input_tokens) in / \(.usage.output_tokens) out"' .socrates/journal.jsonl | sort -u

# Q7 — D7 mapping: the model's names beside the store's
jq -r 'select(.event=="statement_added" and .statement.artifact_id != null) | [.statement.artifact_id, .statement.display_id] | @tsv' .socrates/journal.jsonl

# Q8 — the proposed queue still awaiting you
jq -s -r '[.[] | select(.event=="state_changed") | .sid] as $moved | .[] | select(.event=="statement_added" and .statement.state=="proposed") | select([.statement.sid] | inside($moved) | not) | .statement.display_id' .socrates/journal.jsonl
```

A cautionary tale from the review's own walk: Q3 run against the scenario
walkthrough shows five ratifications in the same second — because the walk
was reproducing a spec, not reading. When Q3 shows that pattern on *your*
store, the canary fired. (This is also why `socrates stats` — plan 0006 —
should eventually own these queries; the crib sheet is the bridge, not the
instrument.)

## 4. Record clarification events

The purpose claim made countable: a **clarification event** is a statement
whose decomposition surfaced something reading had glided over — a
dependency you hadn't registered, a want smuggled under an ought, a term
used without a definition. (The transfer study logged one on the repo's
own material: the is/ought rule forcing "i want to remain the author of
the systems i build" into the open before the bet would stand.)

Week one: keep a plain `dogfood-log.md` beside the store — one line per
event, citing the display id. Tallying these against hours spent is the
first honest read on whether clarification is real. (The in-store
alternative — attesting the observation with a dep on the statement that
prompted it — is more socratic and makes the log queryable, but mixes
meta- and object-level statements in one graph; defer that choice until
the store has shape.)

## 5. Frictions to expect (from the review's probes)

- **Per-type index bookkeeping.** Hand-authoring dep chains means reading
  back the ids the tool prints; the review's first worked-example walk
  mis-numbered a dep and was refused (`E_DANGLING_DEP`, nothing
  journaled). The refusal is the system working.
- **Self-referential defs** (review R3): refused at `add`, allowed from
  the model — an unratified asymmetry. Until decided, term-free def
  bodies first, add-then-amend for mutual reference.
- **Whole-file intake.** Slicing is on you (§2); dense sources need it.
- **`show` vs `rdeps` counts** (review R1): `show`'s rdeps number includes
  dead dependents until the R-findings patch lands; trust the `rdeps`
  listing.

## 6. Deferred, deliberately

- **Plan 0003** (re-prose, patches, roundtrip). It is the right
  measurement machinery, but building more before using what exists is
  the v1 pattern canon names ("40 open plans"). A week of journal data
  will also tell you what roundtrip should actually measure. Revisit at
  the §7 decision point.
- **Waves 3–4 of the transfer** (decisions, spike claims). After the
  three-corpus week, not before — the foreign-text result may reshape how
  much transfer the store deserves.
- **The R-findings patch** (review §E): small, real, and not urgent;
  batch it whenever the code is next touched.

## 7. The decision point (end of week one)

Sit down with Q1–Q8 and the clarification log, and answer three questions
the data now speaks to:

1. **Fidelity:** did live decompositions deserve their ratifications?
   (Q5's error mix and your rejection notes are the evidence.)
2. **Pace:** did ratification stay reading-paced, or did Q3 show bursts?
   (If bursts — the canary's first true positive is *you*, and the honest
   response is the one plan 0006 scripts: surface the number, not more
   friction.)
3. **Value:** did clarification events per hour justify the slowdown on
   the *foreign* corpus — the one where socrates competes with plain
   careful reading?

If the answers are yes / yes / yes: wave 3 of the transfer, then plan
0003 — roundtrip becomes worth building because there is now a graph
worth measuring. If fidelity failed: the loadout spec block and the
repair protocol are the levers, and the rejected artifacts are your eval
corpus. If value failed on the foreign corpus only: socrates may be a
tool for *your own* dense writing rather than others' — which canon §4
would recognize, and which the store you now have can keep testing.
