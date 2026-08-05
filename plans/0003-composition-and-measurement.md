---
title: "Plan 0003 — composition & measurement: re-prose, patches, audit, roundtrip"
status: proposed — the build after 0001; NOT part of the first build
date: 2026-08-05
source: master thread (direction → socrates_2/threads/2026-08-05-master-thread.md)
---

# Plan 0003 — composition & measurement

**Not part of the 0001 build.** This is the v1 command surface: the loop closes
(graph → prose → graph), statements become composable into named views, and the
system grows its first instruments. Quoted blocks are verbatim from the master
thread.

## Naming (settled in-thread)

<!-- verbatim: master-thread -->
> a **patch** is a named routing configuration over the graph. My earlier usage (a proposed set of graph changes from `audit`) gets renamed **changeset**. Two concepts, two words.

## `re-prose` — the mirror inference

<!-- verbatim: master-thread -->
> `re-prose` works the mirror direction — `socrates re-prose claim_0+deps` sends the selected subgraph out, displays the returned prose, archives it, and pointedly does *not* write it into the store as truth.

Second inference command after `intake`; same client behaviour, its own system
prompt (render statements → prose), full provenance, output archived under the
exchange's sources.

## Patches — named selectors with compilation history

<!-- verbatim: master-thread -->
> - `socrates patch new auth-story "claim_0+deps --state ratified"` — saves a named selector. The patch is the *routing*: which statements, which filter — patch cables over the graph.
> - `socrates compile auth-story` — resolves the selector *now*, runs re-prose on the resolved subgraph, and **appends** a compilation instance to `patches/auth-story.md`: a header (date, selector, resolved sid set, graph digest, model, prompt digest, token usage) and the prose body.
> - `socrates patch auth-story` — shows the definition plus its compilation history at the CLI; tab-completes.

Why the feature earns its place:

<!-- verbatim: master-thread -->
> Two properties fall out that are better than the feature itself. First, the longitudinal record: the same patch compiled across weeks is a diffable history of how the same argument *sounds* as the graph evolves — several instances side by side really would be instructional. Second, an experiment design hiding in the header: because each compilation records the graph digest, you can distinguish *why* two compilations differ — same digest, different prose = model variance; different digest = the argument actually changed.

Patch files are append-only like everything else; compilations are archived
inference outputs, never truth.

## `audit` — the halt rule as a command

Third inference command. The steps, as designed in-thread (ids read as `attest`
under D5):

<!-- verbatim: master-thread -->
> 1. Resolve the id; load the statement plus its dep closure (context it needs to be understood).
> 2. Assemble the prompt: system = spec + the halt rule; user = statement + context; schema = an AuditReport — `{decomposable: bool, reasoning, proposed: [Statement], revises: [sid]}`.
> 3. One inference call (footered as such).
> 4. Gate the proposed statements exactly as intake output — same checks — plus one more: apply the changeset to a *copy* of the live graph and validate the result, so anything that currently depends on claim_2 provably survives the split.
> 5. Journal the changeset in state `proposed`. Nothing in the live graph moves.
> 6. Render side-by-side: current statement vs proposed split.
> 7. `socrates ratify <changeset>` — the app applies it: new statements enter ratified, the old one flips to `superseded`, `revises` edges recorded. Nothing is deleted, ever — which means your `examples/` directory, today hand-curated verbatim files, becomes a *byproduct of normal operation*: the staged emergence chains just accumulate in the journal.

## `roundtrip` — the first instrument

<!-- verbatim: master-thread -->
> 1. Resolve the selector; snapshot the sid set and graph digest.
> 2. Re-prose it (inference one) → prose P, archived.
> 3. Intake P as a *shadow exchange* (inference two) — flagged synthetic, never part of the truth line.
> 4. Deterministic structural diff, original vs shadow: statement counts by type, edge counts, graph depth, and a statement-matching pass — v1 matching is structural (type + topological position + dep signature), with unmatched statements listed for your eyes rather than guessed at.
> 5. Report a stability score plus the diff; journal it.
> 6. Optional `--judge`: a third, explicitly-marked inference call renders semantic-equivalence opinions on the unmatched pairs — evidence attached to the report, never folded into the deterministic score.

<!-- verbatim: master-thread -->
> The point of the number: it moves when the spec, prompt, or model changes. It's regression testing for the methodology itself — the first mechanical grip on value claims the repo currently holds as untested beliefs.

## Open questions

1. Selector grammar growth (`--type`, `--state`, boolean combinations) — grow
   through use, per the loadout growth rule.
2. The structural-matching algorithm's exact signature (type + topo position +
   dep signature) and its failure display.
3. Whether `compile` should support `--offline` (render-only, no re-prose) as a
   deterministic patch view.
