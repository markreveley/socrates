---
title: "Analysis — LLM proposals, ratification, and how a file edit would fit"
date: 2026-08-06
authorship: agent
fidelity: verbatim
status: filed as answered — non-normative; nothing here edits a ratified document
question: "When an llm gives a proposal, to be ratified by the user? How might that relate to, say, editing a file?"
---

# LLM proposals and file edits

Agent answer to the operator's question, filed verbatim. Everything below
the rule is the reply as given — do not normalize, condense, re-wrap, or
repair it. Line references are to the tree at `b26ea76`.

---

Inspected. Here's what the repo actually does today, and where a file edit fits.

## Today: a proposal is a statement, ratification is a state transition

There's exactly one generative door — `intake` (`lib/socrates/cli.ex:770`). The path:

1. Model returns structured output against a closed schema (`lib/socrates/loadout.ex:25`) — `{"statements": [...]}`, `anyOf` per-type branches, `additionalProperties: false` everywhere. **The schema has no `state` field**, so a model literally cannot express "this is ratified."
2. Strict decode (`cli.ex:975`) refuses anything outside the model-suppliable field set.
3. `Gate.check_artifact/2` (`lib/socrates/gate.ex:24`) — id form, duplicate ids, dangling deps, cycles, undefined terms, per-type shape. Structure only; deliberately not truth. Hard errors go back as `{"gate_errors": [...]}` for at most 2 repair turns, then exit 1 with the rejected artifact archived.
4. `accept_artifact/4` (`cli.ex:924`) stamps `state: "proposed"`, `author: "model"`, provenance with request/response digests and token usage, assigns store-global display ids, resolves deps to sids, and journals each one. Renders without `⊢`.
5. `ratify` / `reject` (`cli.ex:48`, `cmd_transition/3` at `cli.ex:557`) are the only transitions. They refuse anything not currently `proposed` (`cli.ex:568`) and append a `state_changed` event — state is a fold over the journal, never a mutation.

The asymmetry is the point: operator `add` enters `ratified` directly (`cli.ex:347`) because authorship is assent. The human is direct; the model petitions.

## A file edit: the same shape, one layer further out

`act` and `did` are already in the ratified type set (`loadout.ex:9`) and taught to the model (`loadout.ex:132-134`) — "a prescription, something to do" / "a record of something done." But they carry **no fields beyond `body`/`deps`/`notes`** (`loadout.ex:67`, and `Statement.shape_errors` falls through to `[]` for them at `statement.ex:66`), and no executor exists anywhere in `lib/`. So a proposed file edit today is a prose sentence a human ratifies — a commitment, not an effect.

`plans/0004-agency.md` is the machinery, deferred out of the first build. Its loop (`0004:19-25`) is your ratification loop with two boxes inserted:

```
model proposes:   [act_0] write file X with content C   (data, not effect)
gate validates:   path inside workspace? op on the allowlist? matches ratified plan?
policy decides:   auto-execute | require ratify | reject     (a table, not a model)
app executes:     deterministically, byte-preserving ops preferred
journal records:  [did_0](act_0) executed; result R; digest of bytes written
```

The four claims that distinguish this from Claude Code's approval prompt are at `0004:39-42`, and the sharpest one is #2: `bash -c "..."` is an opaque string, so a harness has no choice but to ask a human to eyeball it — which is exactly the surface rubber-stamping evolved on (`docs/01-purpose.md:69-72`). A typed `act` lets a deterministic policy table key on *what the action is* (workspace patch vs. external POST), so most edits never need to reach you at all. The anti-fatigue answer for the ones that do is plan-envelope ratification (`0004:49`): ratify a dependency-linked set of acts once, run autonomously inside it, pause only outside it.

## The connective tissue that already exists

Two pieces of the file-edit story are built:

- **Binding a statement to exact bytes.** A `ref` with `origin.kind: "file"` is sha256'd *by the app at gate time* (`gate.ex:128-137`) — "measured, never trusted," never accepted from the model — and re-checked with zero network by `verify` (`cli.ex:618-638`). A `did` recording "digest of bytes written" is that same primitive aimed at the after-state.
- **The known trap.** `docs/04-transfer-study.md:197-204` already found it: do *not* `ref` living code files. Pinning bytes is right for canon and archived sources, wrong for `lib/**`, where every future edit turns `verify` red. Code anchors belong in bodies/notes or as refs to stable objects (commit hashes as `url`/`quote`). An `act`/`did` pair over file edits has to record the digest as *history* — what the effect was — not as a standing invariant, or `verify` becomes noise.

The genuinely open questions are in `0004:98-103`, and the one that decides how much ratification you actually do is #3: what counts as "inside" a ratified envelope when an act's parameters differ slightly — exact match, schema match, or policy-defined tolerance. Too strict and you're back to prompt-per-edit; too loose and the envelope is a blank check.

Nothing changed on disk; `claude/llm-proposals-ratification-ncu43m` is checked out and clean if you want any of this filed as statements or a plan amendment.
