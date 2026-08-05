---
title: "Scenarios v0 — usage with expected behavior"
status: normative for the 0001 build; acceptance walks scenarios 4–7
date: 2026-08-05
---

# Scenarios v0

Command-line usage paired with expected behavior, for the session building
plan 0001. Conventions: lines starting `$` are invocations; unprefixed lines
are **stdout**; lines starting `!` are **stderr**; `exit:` is the exit code;
`<angle-brackets>` mark nondeterministic values (sids, request ids, token
counts, dates). Everything else is exact — including error codes, the footer
format, and the `⊢` prefix. M4 may wire these as integration tests;
hand-walking them satisfies acceptance. Scenarios 4–5 run under the fixture
client (`SOCRATES_CLIENT=fixture`) and are exact end to end; a live-model run
of scenario 4 satisfies acceptance under the disjunction in plan 0001 →
Acceptance.

## 1 — init, and the store refuses to be assumed

```
$ socrates show attest_1
! no .socrates here (run: socrates init)
! [deterministic]
exit: 2

$ socrates init
! initialized .socrates/
! [deterministic]
exit: 0
```

## 2 — the pen: the practical syllogism, authored directly (M1)

The corrected canon #2, built by hand — no API key, no model. Note the
implicit-conjunction rule applied: `infer_1` deps on both attests directly;
no conjunction statement exists.

```
$ socrates add --type attest --body "apples are fruits"
attest_1 <sid>
! [deterministic]
exit: 0

$ socrates add --type attest --body "fruits reproduce"
attest_2 <sid>
! [deterministic]
exit: 0

$ socrates add --type infer --dep attest_1 --dep attest_2 --body "apples reproduce"
infer_1 <sid>
! [deterministic]
exit: 0

$ socrates add --type attest --body "i want access to more food consistently"
attest_3 <sid>
! [deterministic]
exit: 0

$ socrates add --type act --dep infer_1 --dep attest_3 --body "i should consider planting apple trees"
act_1 <sid>
! [deterministic]
exit: 0
```

The lint refuses a dangling dep — nothing is journaled:

```
$ socrates add --type act --dep infer_9 --body "i should plant now"
! E_DANGLING_DEP act: dep infer_9 not found
! [deterministic]
exit: 1
```

## 3 — reading the graph (M2)

Operator-authored statements are already ratified — authorship is assent —
so `⊢` appears immediately:

```
$ socrates render
⊢ [attest_1] apples are fruits
⊢ [attest_2] fruits reproduce
⊢ [attest_3] i want access to more food consistently
⊢ [infer_1](attest_1, attest_2) apples reproduce
⊢ [act_1](infer_1, attest_3) i should consider planting apple trees
! [deterministic]
exit: 0

$ socrates rdeps attest_1
infer_1
! [deterministic]
exit: 0

$ socrates rdeps attest_1 --all
infer_1
act_1
! [deterministic]
exit: 0
```

stdout is pipe-clean (D6): `socrates render | wc -l` counts statements, never
footers.

## 4 — intake: canon #1, the gate catches the coinage (M3)

`canon-block.txt` holds canon #1's four statements. The def is authored first
(as canon requires); the fixture client — seeded with a canned first response
reproducing the canon findings — trips the known finding, and the repair loop
mints the missing def. Statement bodies are the fixture's, deterministic once
the fixture is authored at M3:

```
$ socrates add --type def --term "representation ratification" --scope global --body "the operator verifying the agent's socrates rendering of operator intent before any work is done"
def_1 <sid>
! [deterministic]
exit: 0

$ SOCRATES_CLIENT=fixture socrates intake canon-block.txt
! exchange 2 opened · source archived <sha256-prefix>
! gate: E_TERM_UNDEF attest_3: term *Sounds like you know what you are doing* has no def in scope
! repair 1/2 …
! gate: pass (5 statements, 0 warnings)
  [def_2] *Sounds like you know what you are doing* {…} : <fixture definition>
  [attest_4](def_1) …
  [attest_5](def_1, attest_4) …
  [attest_6](def_1, def_2) …
  [attest_7](def_1, attest_5, attest_6) …
! [inference: fixture · - · 0 in / 0 out]
exit: 0
```

Proposed statements render without `⊢`. Ratification is the operator's act:

```
$ socrates ratify def_2 attest_4 attest_5 attest_6 attest_7
! 5 ratified
! [deterministic]
exit: 0
```

(`def_1` was already ratified at `add`; its `scope: global` promoted it into
the `definitions.json` export then. Gate and repair lines speak the model's
artifact-local ids — `attest_3` above names the artifact's third attest; the
render shows the final store-global display ids assigned at acceptance, dep
references rewritten to match (D7). `def_2` is unchanged by assignment: the
store's next free def index is already 2.)

## 5 — intake failure fails loudly (M3)

With the fixture client forcing persistent gate errors:

```
$ SOCRATES_CLIENT=fixture socrates intake bad-input.txt
! exchange 3 opened · source archived <sha256-prefix>
! gate: E_DANGLING_DEP attest_2: dep attest_9 not found
! repair 1/2 …
! gate: E_DANGLING_DEP attest_2: dep attest_9 not found
! repair 2/2 …
! gate: E_DANGLING_DEP attest_2: dep attest_9 not found
! rejected after 2 repairs · artifact: .socrates/sources/3/rejected-2.json
! [inference: fixture · - · 0 in / 0 out]
exit: 1
```

Nothing entered the graph; `intake_rejected` is in the journal.

## 6 — verify, clean and tampered (M2)

```
$ socrates verify
! sources: 8 files ok · ref origins: 0 checked
! [deterministic]
exit: 0

$ printf x >> .socrates/sources/2/source.txt
$ socrates verify
! MISMATCH .socrates/sources/2/source.txt
! [deterministic]
exit: 3
```

## 7 — amend is supersession, never mutation (M4)

```
$ socrates amend attest_1 --body "apples are a fruit"
attest_1 <new-sid> revises <old-sid>
! [deterministic]
exit: 0

$ socrates log --limit 3
<ts> intake_rejected @3
<ts> statement_added attest_1 <new-sid> revises <old-sid>
<ts> state_changed <old-sid> superseded
! [deterministic]
exit: 0
```

`render` shows only the current statement; the journal holds both, forever.
