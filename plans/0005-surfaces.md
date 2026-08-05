---
title: "Plan 0005 — surfaces: neovim, then a language server"
status: deferred — NOT part of the first build
date: 2026-08-05
source: master thread (direction → socrates_2/threads/2026-08-05-master-thread.md)
---

# Plan 0005 — surfaces

**Not part of the 0001 build.** Richer ratification surfaces over the same
store. The governing rule, verbatim from the master thread:

<!-- verbatim: master-thread -->
> The one rule that keeps everything intact: the buffer is a *view* over the store, never the truth.

## Neovim

The app owns the RPC socket; models never touch it. What RPC buys over plain
file reads/writes — the load-bearing advantage:

<!-- verbatim: master-thread -->
> **Identity that survives editing.** This is the load-bearing one. In a file, "line 14" goes stale the moment anything above it changes. An extmark is an annotation nvim *moves with the text* through every edit — so the binding between screen position and `sid` survives, which is what makes "press `<leader>r` on this line to ratify *this statement*" possible at all. Files have no analogue.

Plus: edit events (per-edit deltas → live lint, human edits become attributed
supersession events), enforceable read-only on verbatim views, out-of-band
annotation (virtual text carries state/provenance without polluting bytes),
coupled views, transactional attributed operations. Summed in-thread:

<!-- verbatim: master-thread -->
> files give you storage; RPC gives you *interaction* — stable identity, events, overlays, and enforcement at the surface.

The surface design:

<!-- verbatim: master-thread -->
> - `socrates://source` — the operator's prose, read-only, verbatim.
> - `socrates://staging` — model proposals land here, rendered, state `proposed`.
> - `socrates://exchange/7` — the canonical view; statements arrive only via accept.
> - Extmarks bind lines to `sid`s so the mapping survives edits; virtual text shows state and provenance; gate errors populate the quickfix list.
> - Keymaps as state transitions: accept/reject on the line under the cursor, visual-select a subgraph → re-prose it, `gd` on a dep jumps to its def, and a hand-edit to a statement body becomes, on save, a human-authored supersession event (linted, journaled, attributed).

## The language server

One server, every editor. The capability mapping, verbatim:

<!-- verbatim: master-thread -->
> - **Go-to-definition** (`gd`): jump from `*representation ratification*` or a dep to its `def`. The LSP verb and the socrates noun are literally the same word.
> - **Find-references**: `rdeps` — every statement that depends on this one. "What breaks if this is wrong" as a keystroke.
> - **Diagnostics**: the gate, live. A dangling dep is a red squiggle *as you type it*; `E_TERM_UNDEF` underlines the coined term in claim_2 before you ever run a command. "Ungrasped node is a hard fault" becomes visible at authoring time, not review time.
> - **Hover**: cursor on a term → its def body, scope, glossary status, state, provenance. The def layer at zero navigation cost.
> - **Rename**: supersession as a refactor — rename a term and the changeset propagating through every use is generated for ratification, not applied.
> - **Code actions**: the contextual lightbulb — "mint def for this coined term," "split this statement" (invokes `audit`), "ratify," "promote def to global."
> - **Document symbols / outline**: the statement graph as a navigable tree; **semantic tokens**: color by type and state — ratified calm, proposed loud.
> - **Completion**: dep ids and glossary terms as you type.

Why it matters beyond convenience:

<!-- verbatim: master-thread -->
> it moves enforcement to the cheapest possible moment. A fault caught while the sentence is being written costs a glance; the same fault at ratification costs a round trip.

One design consequence carried from the thread: LSP speaks in documents, and
socrates documents are rendered views, so

<!-- verbatim: master-thread -->
> the server maintains a mapping from view positions to sids — the same problem source maps solve for compiled JavaScript, solved the same way.

## Sequencing and open questions

1. nvim before LSP: the plugin proves the view/extmark/ratify loop with one
   client before generalizing to the protocol.
2. Server runtime ties to plan 0004's runtime decision (a long-lived process;
   BEAM candidate — elixir-ls is precedent for LSP servers in Elixir).
3. Hover/diagnostic phrasing should reuse the gate's error strings — one
   source of truth for fault language.
