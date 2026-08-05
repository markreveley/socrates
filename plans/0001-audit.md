---
title: "Audit — plan 0001 pre-build check"
date: 2026-08-05
status: applied — verified by a second agent (one counter-finding; §E corrected); D7 ratified as option B and amendments applied on operator instruction, 2026-08-05
scope: plans/0001-mvp-harness.md, spec/cli-v0.md, spec/scenarios-v0.md, canon/*, sibling plans, external technical claims
verdict: hold the build on four defects (A1–A4); everything else is buildable as written
---

# Audit — plan 0001, the last check before the build

Adversarial pass over the first build's full normative surface: plan 0001, the
two normative specs, the canon files it depends on, the five sibling plans
(checked for contradictions only), and every external technical claim (Anthropic
API shapes verified against current reference documentation; Elixir/Req/escript
claims verified against current docs and issue trackers).

Consistent with this repo's own invariant — only the operator changes state —
this audit **proposes** amendments and edits nothing. Ratified decisions D1–D6
were audited and **all stand**; none are relitigated below.

## Verdict

**The build should not start until A1–A4 are resolved.** All four are defects in
the normative documents themselves, not in the architecture: as written, the
normative surface is unsatisfiable (A1, A2), and the acceptance gate is
nondeterministic (A3) or un-runnable (A4). Each has a cheap fix; A1 needs a
ratification decision (proposed as D7). With A1–A4 resolved, the plan is
implementable exactly as written — the ground rules, module map, milestones,
store design, and gate design all survived adversarial review intact.

## Resolution record (2026-08-05)

A second agent adversarially verified this audit against the normative text —
fresh context, the proposer's reasoning excluded — and concurred on every
finding and on D7 option B, filing one counter-finding against §E (corrected
in place below). The operator then instructed application per the audit's
recommendation: **D7 is ratified as option B**, and amendments A2–A4, B1–B5
and the §C notes are applied in the changeset carrying this record, in the
suggested resolution order. The build unblocks on merge.

---

## A. Blocking — resolve before the build

### A1. Display-id resolution is undefined, and the scenarios demand two contradictory resolutions

The deepest finding. Display ids are unique **per exchange** (plan 0001, gate
table: `E_DUP_ID` — "display_ids unique within the exchange"; scenario 4's
annotation: "Display ids above are the exchange's"). CLI arguments resolve
display ids "scoped to the current graph" (cli-v0 § Global contract) — a phrase
defined nowhere. The walkthrough itself then guarantees a store-wide collision:
scenario 2 hand-authors `attest_1..3` (exchange 1); scenario 4's intake emits a
*second* `attest_1..4` (exchange 2).

After that point, three things break:

1. **Scenario 4 vs scenario 7 need opposite resolvers.** Scenario 4 runs
   `ratify … attest_1 …`, which must resolve to exchange 2's *proposed*
   `attest_1` (the exchange-1 one is already ratified — targeting it is exit
   `2` per cli-v0). Scenario 7 runs `amend attest_1 --body "apples are a
   fruit"`, which must resolve to exchange 1's `attest_1` ("apples are
   fruits") — but by then *both* `attest_1`s are live and ratified, so no
   deterministic rule picks it. One command form, one store, two required
   referents. The normative scenarios cannot both pass under any single
   resolution rule.
2. **Stored dep edges inherit the ambiguity.** `deps` is a model-suppliable
   list of display-id strings; nothing says the app resolves deps to sids at
   write time. Once two live `attest_1`s exist, a journaled dep `"attest_1"`
   — and any future `add --dep attest_1` — has no defined referent. The
   graph's *edges* become ambiguous, which is the one thing this system
   exists to prevent.
3. **The rendered artifact is ambiguous to the reader.** After scenario 4,
   `socrates render` (whole graph) prints two `⊢ [attest_1]` lines with
   different bodies, and dep lists that mention `attest_1` no longer name a
   unique statement *in the notation itself*.

There is also a smaller inconsistency inside the same design: `add` numbering
("next free index per type", cli-v0) reads store-global, while intake ids are
exchange-scoped — two write paths, two numbering scopes. And scenario 4's model
output is internally split: its `def_2` avoids the store's `def_1` (visible via
the definitions block) while its `attest_1..4` collide with the store's
attests (invisible to the model) — coherent mechanically, but proof that
per-exchange ids leak collisions wherever the model can't see.

**Proposed decision — D7, two options; recommendation: B.**

- **Option A — keep per-exchange ids; define resolution; qualify.** Rule:
  a display id in arguments resolves among statements the command can act on
  (ratify/reject: `proposed` only — scenario 4 then works); if still
  ambiguous, exit `2` listing the candidate sids. Add a qualified form
  (`@2/attest_1` or sid) for cross-exchange reference, and make `render`
  qualify ids whenever bare ids would collide. **Scenario 7 must be edited**
  (amend by sid, or show the ambiguity error then the sid retry — the error
  round is arguably better pedagogy). Deps: resolved to sids at write time
  regardless (see below).
- **Option B — store-global display ids, app-assigned (recommended).** The
  model's display ids are treated as artifact-local names: the gate validates
  them intra-artifact (`E_ID_FORM`, `E_DUP_ID`, internal dep resolution), and
  on acceptance the app renumbers each statement to the next free store-wide
  index per type, rewriting internal dep references to match. This is the
  same move the plan already makes for `origin.sha256` ("measured, never
  trusted") applied to naming: models emit data; the app stamps identity.
  Every bare display id everywhere — arguments, deps, renders — is then
  unique for the life of the store; scenario 7 works as written;
  cross-exchange deps become expressible with no new syntax. Edits required:
  the `E_DUP_ID` row rescopes to "within the artifact (pre-assignment)";
  scenario 4's rendered ids become `attest_4..7` (`def_2` is unchanged —
  store-wide next-free is already 2), the ratify line follows, and the
  "display ids are the exchange's" annotation is dropped. Gate/repair
  messages keep speaking the model's artifact-local ids (that is the
  conversation the model can follow); the accept-time mapping is journaled.

**Either way, one line must be added to plan 0001's store section:** *deps are
resolved to sids at write time; display ids are view-layer.* Journaled edges
must be sid-edges, or issue (2) survives any naming policy. Related and folded
in: `amend` gives the replacement the same display id as the original (scenario
7 stdout), which formally violates `E_DUP_ID` within an exchange unless the rule
is scoped to **live** statements — under Option B, state it as: a `revises`
chain shares one display id, which resolves to the chain's live head.

### A2. Scenario 7's `log` output contradicts cli-v0 and the walkthrough's own event history

cli-v0: "Journal events, **newest last**." Scenario 7 shows, after the amend:

```
<ts> statement_added attest_1 <new-sid> revises <old-sid>
<ts> state_changed <old-sid> superseded
<ts> state_changed attest_4 ratified
```

Two independent errors. **Order:** the newest events (the amend pair) appear
first, and an older event last — that is newest-first. **Content:** the
scenarios are cumulative (scenario 6's `sources: 2` counts exchanges 2 and 3),
so the three events preceding the amend are scenario 5's `exchange_opened` (3)
and `intake_rejected` — `state_changed attest_4 ratified` (scenario 4) is five
events back and cannot appear in a limit-3 window under either ordering.

**Proposed amendment** (pinning amend's append order as statement_added →
state_changed, matching the plan's phrasing "new statement + revises edge; old
statement → superseded"):

```
$ socrates log --limit 3
<ts> intake_rejected @3
<ts> statement_added attest_1 <new-sid> revises <old-sid>
<ts> state_changed <old-sid> superseded
```

Also pin the log line format for `exchange_opened` / `intake_rejected` events
(currently unspecified) while editing.

### A3. Acceptance hinges on nondeterministic model behavior stated as exact

Scenario conventions declare everything outside angle brackets exact, and plan
0001's acceptance step 2 requires the gate to find "**exactly** `E_TERM_UNDEF`"
on intake of canon #1. But intake gates the **model's decomposition**, not the
canon block as given (the canon annotation "run through the MVP gate, the
canonical block as given carries two findings" conflates the two). On the live
path, a well-behaved model can legitimately:

- mint the coined-term def in its **first** response (the `{coinable local}`
  note invites exactly that) → zero findings, no repair round → step 2 fails
  on a *correct* system;
- emit `(def_0)` deps verbatim from the prose even though the store's def is
  `def_1` → `E_DANGLING_DEP` fires *despite* step 1, contradicting "…if step
  1 is skipped";
- normalize or preserve claim_2's asymmetric delimiters (`*…"` — see C1),
  changing whether and how the term scanner fires;
- number `attest_0..3` instead of `attest_1..4` (the gate's `\d+` permits
  both; canon itself is 0-indexed).

Scenario 4's exact stderr (`gate: E_TERM_UNDEF attest_3 …`, `repair 1/2`,
`gate: pass (5 statements, 0 warnings)`) can flake all four ways against a
correct implementation.

**Proposed amendment:** make the deterministic form canonical and the live form
a smoke test. Scenario 4 runs against the `Fixture` client seeded with a
captured/authored first response that reproduces the two canon findings
exactly — then every line is honestly exact, and M4 can wire it as a real
integration test. Acceptance step 2 rewords to a disjunction for live runs:
*intake either surfaces gate findings that the repair loop resolves within 2
rounds, or passes clean with the coined term defined (def present, term
satisfied); the fixture walk is the exact acceptance path.* The optional live
smoke test stays optional.

### A4. Acceptance step 5 / scenario 5 cannot be run as specified — and its footer fabricates provenance

Scenario 5 requires "a fixture client forcing persistent gate errors", and
acceptance step 5 requires the forced-failure run. But the CLI surface defines
no way to select the fixture: cli-v0's environment section lists only
`ANTHROPIC_API_KEY` and `SOCRATES_MODEL`. Since "hand-walking them satisfies
acceptance", the walk is impossible as documented.

Second defect in the same block: the footer reads `[inference: claude-opus-5 ·
<request-id> · …]` for a run the fixture served. Journaled into the dogfood
store (the walkthrough is cumulative), that is fabricated provenance in the
system whose ground rule 5 is provenance on every inference.

**Proposed amendment:** add to cli-v0's environment contract:
`SOCRATES_CLIENT=fixture[:<path>]` selects the fixture client (default:
anthropic). Fixture runs journal and print honest provenance:
`[inference: fixture · - · 0 in / 0 out]`; scenario 5's footer changes to
match. (This also gives M3's tests and A3's fixture walk their invocation
path.)

---

## B. Should-fix — will bite during the build if not addressed

### B1. D1 + D2 collide at M4: TLS from the packaged escript fails with Req's default stack

Verified externally: escripts do not ship `priv/` directories, castore (in
Req's default adapter tree) serves its CA bundle from `priv/cacerts.pem`, so an
escript-packaged Req app fails TLS setup at runtime — wojtekmach/req issue
#299, "Elixir Escript does not work with Req default adapter configurations."
`intake` would work under `mix` through M3 and break in the M4 escript — or
worse, never be caught, since the acceptance section doesn't say the run must
use the escript. Neither decision is wrong; the combination needs one line of
mitigation.

**Proposed amendment to plan 0001 (Runtime + Acceptance):** the client passes
explicit CA certs — `connect_options: [transport_opts: [cacerts:
:public_key.cacerts_get()]]` (OS trust store; available because OTP ≥ 27 is
already pinned; bundling a cacert file is the fallback) — and the acceptance
run executes at least one live `intake` **from the built escript**.

### B2. `definitions.json` is unverified, mutable, derived state feeding both the gate and the model

It is written on ratification, read by `E_TERM_UNDEF` and by system-prompt
assembly — yet it is the only store surface that is mutated in place, its
mutation has no journal event kind, `verify` never checks it, and nothing says
what happens when a promoted global def is later amended/superseded. A
hand-edited or stale file silently alters both gating and what the model is
told, defeating "fold the journal twice yields identical state".

**Proposed amendment:** define `definitions.json` as a **derived export** of
the journal fold — `{term → latest live ratified :global def}` — regenerated on
every fold and never read as authority (gate and loadout read the fold). Then
no new event kind and no verify change is needed, and promotion-on-amend falls
out for free. (Alternative if it must stay authoritative: journal its updates
and add it to `verify`.)

### B3. No `stop_reason` handling on the inference path

Verified against current API reference: `claude-opus-5` can return
`stop_reason: "max_tokens"` (truncated JSON — likelier than it sounds, since
thinking is on by default and counts against `max_tokens`) and `"refusal"`
(safety classifiers; empty or partial content). In both cases the body is not
schema-guaranteed. The plan sends output straight to the gate.

**Proposed amendment:** the client checks `stop_reason` before parsing;
anything other than `end_turn` fails loudly — raw response archived (write-once
rule already covers it), a journaled rejection, nonzero exit — never fed to the
gate as if complete. Same section should state transport-failure behavior:
Req does not retry POSTs by default, so an API/network failure is exit `2`
with the error on stderr (retry policy, if any, is the operator's call).

### B4. `verify`'s counting in scenario 6 contradicts ground rule 6

Ground rule 6 archives *and digests* "source prose **and raw model
responses**"; verify "re-hashes every archived source". By scenario 6 the
store holds ~8 archived files (exchange 2: prose + 2 raw responses; exchange
3: prose + 3 raw responses + `rejected-2.json`), yet the exact-normative
output says `sources: 2 ok`. Either "sources" secretly means prose-only (then
raw responses are digested but never verified — a hole in the tamper-evidence
story), or the count is wrong. The archive file layout (`source.txt`?
`response-<n>.json`?) is also unspecified, so no exact count is currently
derivable.

**Proposed amendment:** pin the archive layout in cli-v0 (suggest
`source.txt`, `response-<n>.json`, `rejected-<n>.json`) and make verify count
files: `! sources: 8 files ok · ref origins: 0 checked` — with scenario 6
updated to match.

### B5. `add`'s exchange is implicit and unspecified

Every statement carries an app-stamped `exchange`, and scenario 4's intake
opens "exchange 2" — which only adds up if all operator `add`s share a standing
exchange 1 that something silently opened. Nothing specifies this, yet an
implementer must decide it at M1 (what does `add` stamp? does `init` or the
first `add` journal `exchange_opened`?), and `@1` becomes the selector for all
hand-authored statements.

**Proposed amendment:** one line in cli-v0: `init` opens exchange 1, the
operator's standing exchange; `add`/`amend` stamp it; each `intake` opens the
next.

---

## C. Loadout inputs — decisions the M0 `spec/loadout-v0.md` must make (noted now so they aren't invented mid-build)

- **C1. Term syntax collides with emphasis.** `E_TERM_UNDEF` scans `*term*`,
  but canon uses asterisks as emphasis too: def_0's own body ends "…intent
  *before* any work is done" — entered verbatim, the lint coins the term
  *before* and hard-errors. Scenario 4's `add` already silently strips those
  asterisks without comment. The loadout must state the rule: in statement
  bodies, `*…*` is reserved for terms; emphasis is normalized away on entry.
  (Also worth noting there: claim_2's delimiters in canon are asymmetric —
  `*Sounds like you know what you are doing"` — a term the scanner as
  specced cannot close; only the model's re-emission makes it findable.
  Feeds A3.)
- **C2. Schema subset.** Verified: structured outputs support `anyOf` (so
  per-type required fields are expressible as a discriminated union),
  require `additionalProperties: false` on every object, and do **not**
  support `minLength`/`pattern`/numeric constraints. Either shape works
  because the gate re-checks everything; pick one deliberately. New schemas
  pay a one-time server compile (cached 24 h) — first-intake latency, not a
  bug.
- **C3. What the model sees, and dep scope.** The system prompt is loadout +
  current definitions only. The definitions block must therefore carry each
  def's display id (or the model cannot dep on `def_1`, nor avoid minting a
  colliding def). Model-artifact deps should resolve against exactly what
  the model can see — artifact-local statements ∪ global defs — not the whole
  store; a dep that only resolves against store statements the model never
  saw is a hallucination and should dangle. (Under D7 option B this is where
  that rule lives.)

---

## D. Minor notes — no action required to build

- cli-v0's render format shows a trailing `[basis: …]`; no v0 field produces
  it (`basis` first appears in plan 0004). Drop it or mark it future.
- Scenario 2's dangling-dep refusal is labeled (M1), but dep-existence
  checking implies at least a journal-fold lookup; graph checks land M2.
  Either note that M1's `add` includes the existence check, or move the
  example under scenario 3.
- "No OTP processes in the MVP" is pedantically false — Req/Finch start a
  supervision tree. Intent is clear; "no app-owned long-lived processes"
  would be exact.
- "One dependency: `req`" is true of direct deps; the lock will carry ~8
  transitive entries including Jason (Req's default JSON engine, verified
  current). D3's "no JSON dep" therefore holds for socrates' *own*
  serialization only — which is what matters, since the deterministic
  field-order encoder is hand-rolled either way. D1/D3 stand.
- Because the request body is digested, build the exact JSON binary first and
  send it via Req's raw `body:` (+ explicit content-type) — never `json:`,
  which re-encodes and can diverge from the digested bytes.
- Prompt-cache claims verified: reads ≈ 10% — correct; note the default TTL
  is 5 minutes (a slow ratify-then-reintake loop re-pays the 1.25× write),
  and the minimum cacheable prefix on this model is 512 tokens (favorable).
  `ttl: "1h"` (2× write) is worth considering for dogfooding cadence.
- `amend` semantics on non-ratified statements are unspecified (amend a
  `proposed`? a `superseded`? suggested: error pointing at the live head /
  allowed on proposed as an operator rewrite — decide at M4).
- Journal fold behavior on a torn final line (crash mid-append) is
  unspecified; fsync-per-append makes it rare — suggest: hard error, never
  silent skip.
- `infer` with zero deps and `act` with no attested want are structurally
  legal in v0; canon #2's is/ought reading suggests the loadout may
  eventually want a stance. Growth-rule material, not gate material.
- README's master-thread pointer (`direction → socrates_2/threads/…`)
  resolves nowhere reachable from this repo. Self-containedness holds
  (deliberately), but a word marking it external/private would spare a
  future reader the hunt.

---

## E. Verified correct — the no-change list

Claims checked adversarially that need **no** amendment:

- **All six ratified decisions D1–D6** are sound and consistently applied
  across plan, specs, and scenarios (D4's display-only `⊢` and D6's
  stdout/stderr discipline are honored in every scenario line checked).
- **The Anthropic request shape is right in current terms**, including the
  subtle ones: `claude-opus-5` is the current Opus id; *thinking omitted is
  on-by-default for this model* (correct and recently changed — most
  descriptions of it in the wild are stale); `output_config: {format:
  {type: "json_schema", …}}` is the canonical structured-output shape (the
  older `output_format` is deprecated); `anthropic-version: 2023-06-01`
  stands; `max_tokens: 16000` is exactly the recommended non-streaming
  ceiling; system-array + `cache_control` on the last block is the standard
  caching pattern.
- **Elixir claims**: 1.18 ships stdlib `JSON`; OTP 27 pin makes it
  unconditional; escript needs only Erlang on the host; a ~40-line
  stdlib-only ULID is realistic; the map-key-order hazard is real and the
  plan already owns it with the deterministic encoder + property tests —
  the right call.
- **Internal cross-checks that passed**: exit-code table vs every scenario;
  store-missing behavior; scenario 4's dep structure maps canon #1 faithfully
  up to one model-added edge (claims 0–3 → attests, def_0 → def_1; `attest_3`
  carries a `def_1` dep that canon's bare `claim_2` does not — counter-finding
  by the verifying agent, absorbed by A3's fixture-canonical walk); scenario 2
  correctly applies the implicit-conjunction rule; canon #2's annotated findings
  (`E_DUP_ID`, `E_ID_FORM`) are accurate; sibling plans 0002–0006 contain
  no contradictions with 0001 (0002's digest-field exclusions match the
  journal design; 0004/0005/0006 defer cleanly); all intra-repo links
  resolve; `rejected-<n>.json` naming is consistent between plan and
  scenario.

## Suggested resolution order

1. Ratify D7 (A1) — the one real decision; everything else is mechanical.
2. Apply A2, A4, B4, B5 (small edits to spec/scenarios + cli-v0).
3. Apply A3 (acceptance rewording + fixture-canonical scenario 4 — shaped by
   the D7 choice, so after 1).
4. Add B1, B2, B3 lines to plan 0001; fold C1–C3 into the M0 loadout work.
5. Build.
