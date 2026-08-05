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
hand-walking them satisfies acceptance.

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
(as canon requires); intake then trips the known finding, and the repair loop
mints the missing def:

```
$ socrates add --type def --term "representation ratification" --scope global --body "the operator verifying the agent's socrates rendering of operator intent before any work is done"
def_1 <sid>
! [deterministic]
exit: 0

$ socrates intake canon-block.txt
! exchange 2 opened · source archived <sha256-prefix>
! gate: E_TERM_UNDEF attest_3: term *Sounds like you know what you are doing* has no def in scope
! repair 1/2 …
! gate: pass (5 statements, 0 warnings)
  [def_2] *Sounds like you know what you are doing* {…} : <model-authored definition>
  [attest_1](def_1) …
  [attest_2](def_1, attest_1) …
  [attest_3](def_1, def_2) …
  [attest_4](def_1, attest_2, attest_3) …
! [inference: claude-opus-5 · <request-id> · <n> in / <m> out]
exit: 0
```

Proposed statements render without `⊢`. Ratification is the operator's act:

```
$ socrates ratify def_2 attest_1 attest_2 attest_3 attest_4
! 5 ratified
! [deterministic]
exit: 0
```

(`def_1` was already ratified at `add`; its `scope: global` promoted it to
`definitions.json` then. Display ids above are the exchange's — exact bodies
come from the model and are `<nondeterministic>` in content, deterministic in
structure.)

## 5 — intake failure fails loudly (M3)

With a fixture client forcing persistent gate errors:

```
$ socrates intake bad-input.txt
! exchange 3 opened · source archived <sha256-prefix>
! gate: E_DANGLING_DEP attest_2: dep attest_9 not found
! repair 1/2 …
! gate: E_DANGLING_DEP attest_2: dep attest_9 not found
! repair 2/2 …
! gate: E_DANGLING_DEP attest_2: dep attest_9 not found
! rejected after 2 repairs · artifact: .socrates/sources/3/rejected-2.json
! [inference: claude-opus-5 · <request-id> · <n> in / <m> out]
exit: 1
```

Nothing entered the graph; `intake_rejected` is in the journal.

## 6 — verify, clean and tampered (M2)

```
$ socrates verify
! sources: 2 ok · ref origins: 0 checked
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
<ts> statement_added attest_1 <new-sid> revises <old-sid>
<ts> state_changed <old-sid> superseded
<ts> state_changed attest_4 ratified
! [deterministic]
exit: 0
```

`render` shows only the current statement; the journal holds both, forever.
