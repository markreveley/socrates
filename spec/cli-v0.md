---
title: "CLI v0 — the complete interface"
status: normative for the 0001 build
date: 2026-08-05
---

# CLI v0 — the complete interface

Every command, argument, and flag in the first build. Anything not listed here
is not in the build. `spec/scenarios-v0.md` shows these commands in use with
expected behavior; the two documents are read together.

## Global contract

- **Store discovery:** commands operate on `./.socrates/` in the current
  working directory — no ancestor walking in v0. Missing store → exit `2` with
  `no .socrates here (run: socrates init)` on stderr.
- **Output discipline (D6):** stdout carries only the artifact (renders, ids,
  query results). The boundary footer, progress, gate errors/warnings, and
  confirmations go to stderr. stdout is always pipe-clean.
- **Boundary footer (stderr, last line of every command):**
  - `[deterministic]`
  - `[inference: <model> · <request-id> · <n> in / <m> out]`
- **Exit codes:** `0` ok · `1` gate-rejected (after retries, or human `add`
  failing lint) · `2` usage / environment error · `3` verify mismatch.
- **Environment:** `ANTHROPIC_API_KEY` (required by `intake` only).
  `SOCRATES_MODEL` overrides the model (default `claude-opus-5`).
- **Ids in arguments** are display ids (`attest_3`) scoped to the current
  graph; sids are accepted anywhere a display id is.

## Selectors

Where `[selector]` is accepted: nothing (= the whole graph) · `<id>` ·
`<id>+deps` (the statement and its transitive dependencies) · `<id>+rdeps`
(the statement and everything depending on it) · `@<exchange>` (all statements
of one exchange). Nothing else in v0.

## Statement rendering (one line per statement)

```
⊢ [attest_1] apples are fruits
  [attest_4](attest_1, attest_2) …body…   {note}   [basis: …]
```

`⊢` prefix on `state: ratified` (D4, display-only; `--ascii` renders `|-`);
two-space indent continuation for wrapped bodies; deps comma-separated in one
parenthesis group; `{notes}` and `[basis]` trail the body. Renders are in
topological order, defs and refs first.

## Commands — deterministic

### `socrates init`
Creates `.socrates/` (empty journal, `definitions.json`, `sources/`). Errors
exit `2` if the store already exists. No flags.

### `socrates add`
Author one statement directly. Enters `ratified` (authorship is assent).
Display id is auto-assigned (next free index for the type).

```
socrates add --type <def|ref|attest|infer|act|did>
             [--body <text>]            # or body on stdin when --body absent
             [--dep <id>]...            # repeatable
             [--note <text>]...         # repeatable
             [--term <text>]            # def only (required for def)
             [--scope <local|global>]   # def only (required for def)
             [--origin <kind>:<locator>]# ref only (required for ref);
                                        # kinds: file | url | exchange | quote
                                        # file origins are sha256'd at add time
```

stdout: the new statement's display id and sid, one line: `attest_5 <sid>`.
Lint failure: nothing journaled, errors to stderr, exit `1`.

### `socrates amend <id>`
Same flags as `add` (type is fixed to the original's). Journals a new
statement carrying a `revises` edge; the original flips to `superseded`.
stdout: `attest_5 <new-sid> revises <old-sid>`.

### `socrates show <id>`
Full record for one statement: rendered line, then field: value pairs
(sid, exchange, state, author, deps, rdeps count, provenance, revises).

### `socrates deps <id>` / `socrates rdeps <id>`
Direct dependencies / direct dependents, one display id per line.
`--all` extends to the transitive closure.

### `socrates graph [selector]`
Indented dependency tree of the selection, statements rendered per the format
above.

### `socrates render [selector]`
The bracket-notation document for the selection: topological order, defs/refs
first. `--ascii` substitutes `|-` for `⊢`.

### `socrates ratify <id>...` / `socrates reject <id>... [--note <text>]`
State transitions on `proposed` statements; journaled with timestamps.
Ratifying a `def` with `scope: global` promotes it into `definitions.json`.
Transitioning a non-`proposed` statement: error, exit `2`, nothing journaled.

### `socrates verify`
Re-hashes every archived source and every ref origin against recorded digests.
Reports per-file status to stderr; any mismatch → exit `3`. Zero network.

### `socrates log [--limit <n>]`
Journal events, newest last: timestamp, event kind, ids. Default limit 50.

## Commands — inference

### `socrates intake <file|->`
The one generative door. Archives the prose verbatim (digest recorded), opens
an exchange, calls the model (structured output against the loadout schema),
runs the gate with at most 2 repair retries, journals survivors as `proposed`,
prints the render to stdout. Gate exhaustion: rejected artifact saved under
`sources/<exchange>/`, `intake_rejected` journaled, exit `1`.

## Explicitly not in v0

`re-prose`, `patch`, `compile`, `audit`, `roundtrip`, `stats` (plans
0003/0006); acts execution (0004); any server or editor surface (0005);
`--json` output modes; config files.
