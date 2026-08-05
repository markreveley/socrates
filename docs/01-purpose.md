---
title: "Docs — why socrates exists, from first principles"
status: explanatory — non-normative; on any conflict, canon/, plans/, and spec/ win
authorship: agent-drafted for operator review; quotes from canon are verbatim, everything else is paraphrase
date: 2026-08-05
---

# Why socrates exists

This document explains the purpose of this repo in plain language, starting
from the problem rather than the feature list. It is a companion to
[`canon/purpose.md`](../canon/purpose.md) (the operator's own words, verbatim)
and to the [architecture doc](02-architecture.md) (how the system works). The
[research doc](03-research-spike.md) tests the claims made here against
outside evidence.

## The one-paragraph version

When you build something by talking to an AI, the AI produces text much faster
than you can understand it. Your picture of what you're building drifts away
from what actually exists, and because keeping up feels impossible, you start
approving things you haven't really read. socrates is a tool built on the
opposite trade: it deliberately slows the conversation down to the speed of
your understanding. The AI's prose is broken into small typed statements; a
dumb, deterministic checker validates their structure; and nothing counts as
settled until you, the human, have ratified it — statement by statement.
Progress is measured in statements you have actually understood and accepted,
not in tokens generated.

## The problem, from first principles

Start with three observations about building things through a chat window with
a capable model. Each is stated in the operator's words in
[`canon/purpose.md`](../canon/purpose.md); here they are unpacked.

**1. Generation outruns comprehension.** A model can produce a plausible
design, plan, or module in seconds. Reading it carefully takes minutes;
genuinely understanding it — well enough to catch a subtle error, or to build
the next thing on top of it — takes longer still. In a chat loop you are
always downstream of a firehose. The operator's image is a jet engine strapped
to a motorcycle: "suddenly the user and agent are going 300 and the user is
scared to even touch the controls."

**2. The mental model drifts.** The thing you are building exists twice: once
in the repo, and once in your head. Software only stays steerable while those
two stay close. Chat-paced building pulls them apart — "the mental model an
operator creates of the system they are building is inevitably out of step
with the reality" — and the backlog of things you'd need to unpack to catch up
grows faster than you can unpack it.

**3. Drift decays into deference.** Once you can no longer check the model's
output against your own understanding, the cheap move is to assume the model
knows what it's doing. Canon names this failure precisely: dense, opaque
output that is "expensive to unpack is left unpacked in favor of assuming the
agent 'knows what its doing', incentivizing the easier path of default
approving." At that point the human is still clicking approve, but is no
longer meaningfully in the loop. The approval is theater.

Note what the root problem is *not*. It is not that models write bad code or
false prose (they sometimes do, but review can catch that). It is that the
**reading side** of the loop — human comprehension — is the scarce resource,
and every existing interface optimizes the writing side. A better model makes
this worse, not better: more fluent output is more expensive to distrust.

## Why the usual answers don't fit

- **"Use a better model."** Raises the quality of the output; does nothing for
  the operator's grasp of it. The deference dynamic feeds on fluency.
- **"Add guardrails / approval prompts."** Existing harnesses gate *actions*
  (run this command? edit this file?), and they gate them as opaque strings a
  human is asked to eyeball. They do not gate *meaning*, and a stream of
  yes/no prompts is exactly the surface on which rubber-stamping evolved.
- **"Review the output like code review."** Whole-artifact review of dense
  prose is precisely the task humans default-approve. The unit of review is
  too big, and nothing tracks which parts you actually understood.

## The bet socrates makes

socrates re-denominates velocity. The unit of progress is not tokens generated
but **statements ratified** — comprehension events. Four commitments follow,
and everything in the architecture serves them:

1. **Meaning gets a type system.** Prose is decomposed into small statements,
   each carrying a type — is this a definition, an assertion, an inference, a
   proposed action, a record of one? — and explicit dependency links to the
   statements it rests on. Small typed units are checkable and ratifiable in a
   way paragraphs are not, and the dependency graph makes "what does this rest
   on?" and "what breaks if this is wrong?" mechanical questions
   (`deps` / `rdeps`) instead of archaeology.

2. **A deterministic gate stands between the model and the record.** Model
   output is data, never truth and never effect. Before anything is recorded,
   a dumb, deterministic checker validates structure: no dangling references,
   no circular reasoning, no coined terms without definitions, no duplicate
   ids. The gate is the compiler front-end prose never had. It deliberately
   checks *structure, not truth* — judging meaning is reserved for the human,
   and the repo is explicit that a model "can pass the gate while being
   unfaithful to the prose."

3. **Only the operator changes a statement's state.** Model proposals enter as
   `proposed` and wait. The transition to `ratified` (or `rejected`) exists
   only as a human command. Ratification converts "sounds like you know what
   you're doing, keep going" into discrete decisions made one at a time —
   which is the whole point.

4. **The record is append-only, with provenance.** Statements are never
   edited in place; change is a new statement that supersedes the old one,
   with the edge recorded. Every model call journals exactly what was sent and
   received (request digest, model id, token usage). Source prose is archived
   byte-exact. A zero-network `verify` command re-checks the whole record. You
   can always answer: what did we believe, when, on what basis, and who
   committed to it.

The write paths are deliberately asymmetric: the operator writes directly
(authoring a statement *is* assenting to it), while the model petitions
through the gate and waits. The human is direct; the model petitions.

## The cost is the feature

socrates is intentionally slower and less powerful than chatting with a model:

> what i am trying to do is build a system that takes longer to use and is
> less powerful, so that you are forced to move at the pace of approvals and
> ratification after proper comprehension. socrates is not as fun to read as
> prose. that's partially the point

This is a forcing function, in the original human-factors sense: a design that
physically prevents the error (here: unread approval, unearned confidence)
rather than warning against it. The bracketed notation is drier than prose
*on purpose* — fluency is the anesthetic this system exists to counteract.

The obvious objection is that friction decays: people habituate to warnings,
rubber-stamp approvals, and abandon slow tools. The design does not dispute
this — it plans for it. Plan 0004's "plan-envelope ratification" exists so
routine work doesn't become approval-prompt hell, and plan 0006 instruments
the failure directly: **rejection rate is the canary**. If the operator's
sustained rejection rate falls to ~zero, "either the model became perfect or
the reading stopped — and only one of those is plausible." The honest response
is not more friction but surfacing the number: *you have stopped reading.*

## What socrates is not

- **Not a proof assistant.** It borrows the shape (small kernel, mechanical
  checking, explicit dependencies — see the lineage notes in the
  [README](../README.md)) but checks structure, not validity. `infer` records
  that *you* concluded something, not that it follows.
- **Not a guardrails or safety product.** Guardrails gate what a model may
  *do*; socrates governs what gets *recorded as understood*. (The
  architecture does overlap with LLM-security designs that treat model output
  as untrusted data — see the [research doc](03-research-spike.md).)
- **Not a note-taking or knowledge-base app.** The store is a record of
  commitments, not a pile of notes: every entry has a type, dependencies, a
  state, and an author, and the history is never rewritten.
- **Not an agent framework — yet.** Acts and their execution machinery are
  designed (plan 0004) but explicitly deferred; the MVP has exactly one
  generative door (`intake`) and no effects beyond the store.

## How we'd know if it works — or doesn't

The purpose claims above are hypotheses, and the repo treats them that way.
The system is designed to measure itself (plan 0006): the gate's pass/fail
statistics are a free, deterministic partial grader; every ratify/reject is a
human label captured by normal use; roundtrip stability (plan 0003) tests
whether the decomposition actually preserves meaning; and the canary watches
for the return of rubber-stamping. The load-bearing untested assumption is
adoption itself — whether an operator will keep using a deliberately slower
tool long enough for the benefits to arrive. Canon calls this "the dream,"
which is the right epistemic register. The [research spike](03-research-spike.md)
collects the outside evidence for and against each of these bets.
