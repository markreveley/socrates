---
title: "Docs — explanatory layer"
status: explanatory — non-normative; canon/, plans/, and spec/ win on any conflict
date: 2026-08-05
---

# docs/

Plain-language explanation of this repo, plus a research spike testing its
core claims against outside evidence. Nothing here is normative: these files
explain decisions, they do not make them. Canon states purpose verbatim,
plans decide, specs bind the build — this folder only translates.

Read in order:

1. [**01-purpose.md**](01-purpose.md) — why socrates exists, from first
   principles: the problem (generation outruns comprehension; drift decays
   into deference), the bet (progress denominated in ratified statements),
   the cost as a feature, and what would falsify it.
2. [**02-architecture.md**](02-architecture.md) — how it works, in plain
   words: the invariant, statements and the six types, the graph, the
   append-only store, the gate, the harness, the write asymmetry, and a
   worked life-of-a-statement.
3. [**03-research-spike.md**](03-research-spike.md) — the repo's core
   theories and assertions, each tested against external literature and
   prior art: what supports them, what resists them, and honest verdicts.
4. [**04-transfer-study.md**](04-transfer-study.md) — could the docs and
   the code's intent be expressed in socrates itself? What transfers
   (defs, the purpose argument, decisions), what must stay prose (the
   tutorial), and why the transfer is a ratification workload, not a
   migration. Filed with [`plans/0001-post-build-review.md`](../plans/0001-post-build-review.md),
   the post-build review of the code, docs, and tutorial.
5. [**05-restatement.md**](05-restatement.md) — a design response to an
   operator prompt on ratification fatigue: the operator restating the
   graph in their own words, closed-book, committed to the ledger as
   evidence of comprehension — the missing quadrant beside
   `intake`/`add`/`re-prose`, the judge-eval corrected to
   judge-as-annotator, the dosage that avoids T5-at-volume, and a
   zero-build version that fits inside week one.

Alongside the reading order:
[**code-walkthrough.md**](code-walkthrough.md) — the tutorial: the 0001
code module by module, two end-to-end traces (`add` and `intake`), the
tests as executable spec, and exercises. Read it with the built escript in
hand.
