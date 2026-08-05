---
title: "Canonical example (proposed) — practical syllogism"
authorship: operator
fidelity: verbatim
status: proposed — supplements or revises the v0 type set; see plans/0001 → Open question
source: master thread, 2026-08-05
---

# Proposed canonical example — the practical syllogism

**Operator-authored. Offered as a supplement to the first canonical example and
as perspective on the type set.** Everything below the rule is verbatim — do not
normalize, condense, re-wrap, or repair it.

---

attestation [attest}
inference [infer]
prescription [act]
recorded [did]

[attest_1] apples are fruits
[attest_2] fruits reproduce
[attest_3](attest_1, attest_2) apples are fruits and fruits reproduce
[infer_1](attest_3) apples reproduce
[attest_3]i want access to more food consistently. 
[act](infer_1, attest_3) i should consider planting apple trees

---

## Known gate findings (annotations, not part of the artifact)

The pattern from the first canonical example holds — the second one also carries
mechanical findings, which is the system's argument made by its own examples:

1. **`E_DUP_ID`** — `attest_3` is minted twice (the conjunction and the want).
   The want would renumber to `attest_4`, and `[act]`'s dep on it follows.
2. **`E_ID_FORM`** — `[act]` carries no index; it would be `act_1`.
3. **Spec observation (not an error):** the first `attest_3` is a pure
   conjunction of `attest_1` and `attest_2`. Because multiple deps already bind
   jointly — a statement depending on `(attest_1, attest_2)` takes both as
   premises — the conjunction node is redundant: `infer_1` could depend on the
   two directly. Candidate rule for the loadout: *multiple deps are implicit
   conjunction; conjunction-only statements decompose away.*

## What the example settles (if ratified)

- Types carve at **functional roles** (assert / conclude / prescribe / record),
  not epistemic gradations — v1's claim/belief/evidence/observation collapse
  into `attest` + fields.
- The **is/ought boundary becomes typed**: `act` is the only ought-type, and it
  is bridged here correctly — its deps trace to an attested *want* (a
  first-person desire report is an attestation about the speaker), not to facts
  alone.
- `act`/`did` are the same pair the agentic extension needs (proposal-to-do /
  record-of-done): the practical loop — know, conclude, intend, execute — in
  four types.
