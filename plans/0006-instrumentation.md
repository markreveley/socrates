---
title: "Plan 0006 — instrumentation: evals and the canary"
status: deferred — NOT part of the first build; the journal captures the needed data from M1
date: 2026-08-05
source: master thread (direction → socrates_2/threads/2026-08-05-master-thread.md)
---

# Plan 0006 — instrumentation

**Not part of the 0001 build** — and deliberately cheap when it lands: the
journal already records everything this plan reads (events, states, timestamps,
provenance, rejected artifacts). This plan is mostly queries. Quoted blocks are
verbatim from the master thread.

## The gate is a free, deterministic partial grader

<!-- verbatim: master-thread -->
> gate-pass rate, error-code distribution, and repair-loop convergence (fixed on retry 1? retry 2? never?) are exact numbers computed by code, reproducible to the byte.

Watch these across model versions, prompt revisions, and spec revisions — a
failure taxonomy for free.

## Decompose-then-judge

<!-- verbatim: master-thread -->
> This is exactly the move factuality evals in the literature make — decompose prose into atomic claims, verify each — except they have to *construct* that decomposition as a preprocessing step, and socrates' output already is one, with dependencies and provenance attached. The system's native format is the eval field's intermediate representation.

## The ratification stream is a labeled dataset

<!-- verbatim: master-thread -->
> Every ratify/reject — with rejection notes, timestamps, and the exact journaled context the model saw — is a human label on a model output, captured by normal use. Most teams pay for labeling; your workflow *is* labeling.

Derived series: per-type acceptance rates; which gate warnings predict
rejection; calibration over time. Rejected intake artifacts are the hard
negatives. Roundtrip stability (plan 0003) is the label-free regression metric
alongside.

## The canary — the system watching its own hollowing-out

The deference dynamic's way back in is the rubber stamp. Instrumented:

<!-- verbatim: master-thread -->
> **rejection rate is the canary.** Journal every ratify/reject with a timestamp; if sustained rejection rate falls to ~zero, either the model became perfect or the reading stopped — and only one of those is plausible. Bulk-instant approvals (latency distribution collapsing) are the same tell. When the canary triggers, the honest response isn't more friction; it's surfacing the number to the operator: *you have stopped reading.*

Implementation: a `socrates stats` command (deterministic) reporting the
series above, with the canary thresholds as config, not judgment.

## The honest limit

<!-- verbatim: master-thread -->
> the gate measures conformance to *your* schema, not capability — a model can pass the gate while being unfaithful to the prose.

Layer one is cheap and exact; layer two (fidelity) is judged — by the operator
via ratification, optionally by the plan-0004 verifier — and the ratification
labels are what keep layer two honest.

## Open questions

1. Decode-cost proxy: is ratification latency a usable stand-in for the
   founding thread's "operator decode time," and what confounds it?
2. Per-statement disagreement metric: define numerator/denominator before
   trusting trends.
3. Canary thresholds: sustained window length and rate floor — pick from the
   first months of real journal data, not a priori.
