---
title: "Analysis — namespaces, fragments, and what a *patch* is not"
date: 2026-08-07
authorship: agent
status: filed as proposed — non-normative; nothing here edits a ratified document, and no code changed
question: "If a decomposition were broken out into reusable fragments — each intake namespaced, the namespace written as an enclosure above the nodes that belong to it — what would that be, and does the repo already call it a patch?"
---

# Namespaces and fragments

The short answer to the last part: **no.** Plan 0003 settled *patch* on a
different meaning, deliberately, and the thing being described here is a
third concept the repo does not yet have a word for. The rest of this is
what it would take, what it buys, what it costs, and the one reason to be
suspicious of it.

Line references are to the tree at `6997c8e`.

## 1. The grouping already exists; it has no name

Every statement carries `exchange` (`lib/socrates/statement.ex:24`), stamped
at acceptance from the intake that produced it. `exchange_opened` journals
the source path and its sha256 (`lib/socrates/journal.ex:41-51`). There is
already a selector for it — `@<exchange>` (`lib/socrates/cli.ex:425-430`,
`spec/cli-v0.md:41-44`) — so `socrates render @7` today prints exactly the
statements one intake produced.

So the container is built. What it lacks is three things:

1. **A name.** It is an integer, assigned by counting. `@7` says when, not
   what.
2. **A visible boundary in the render.** `Render.document/3`
   (`lib/socrates/render.ex:26`) emits a flat topologically-ordered list;
   nothing marks where one intake's work ends and the next begins.
3. **Any bearing on identity.** Under D7 (`plans/0001-mvp-harness.md:300`),
   display ids are app-assigned, store-global, next-free-index-per-type
   (`lib/socrates/journal.ex:321`, `lib/socrates/cli.ex:924-930`). The
   exchange a statement came from is metadata that no id reflects.

Point 3 is where the friction in the question actually lives, and it is
worth making concrete.

## 2. What the example decomposition actually looks like after ratification

As authored, the decomposition is self-contained and legible:

```
[attest_1] I want to name a recurring operator failure.
[attest_2] Dense, opaque communication that would be expensive to unpack gets left unpacked.
[attest_3](attest_2) The operator leaves that communication unpacked because the operator assumes the agent knows what it is doing.
[def_1](attest_2, attest_3) *sounds like you know what you're doing* : …
[infer_1](attest_2, attest_3) Default-approval is the path of least resistance.
```

Those ids are artifact-local names — the model's, or the author's, scoped to
the page. Run it through `intake` into a store that already holds, say, the
~20 lexicon defs of the transfer study's wave 1 (`operator_next_steps.md`
§1) and eleven attests, and the gate accepts it, and `accept_artifact/4`
renumbers:

```
attest_1 → attest_12    attest_2 → attest_13    attest_3 → attest_14
def_1    → def_21       infer_1  → infer_4
```

Deps are rewritten to sids, so the graph is exactly right and nothing is
lost. But the *page* is gone. `[def_21](attest_13, attest_14)` is correct
and unreadable, and there is no id-level trace that those five statements
were ever one thought. `render @7` recovers the set; nothing recovers the
numbering, and nothing labels it.

This is not a defect — D7 was ratified as option B knowing exactly this
(`plans/0001-audit.md:85`), because the alternative was ambiguous ids across
a growing store. The namespace proposal is the way to get the locality back
without giving up the uniqueness.

## 3. Three words, not one

The repo has settled two of the three, in-thread, verbatim
(`plans/0003-composition-and-measurement.md:14-18`):

> a **patch** is a named routing configuration over the graph. My earlier
> usage (a proposed set of graph changes from `audit`) gets renamed
> **changeset**. Two concepts, two words.

Held to the modular-synth analogy the naming came from:

| Word | What it is | Cardinality | When |
|---|---|---|---|
| **namespace** *(new)* | where a statement was born; its home module | one per statement, permanent | at write |
| **patch** (0003) | a saved selector — which statements route into a view | many per statement, revisable | after the fact |
| **changeset** (0003) | a proposed set of graph edits, awaiting ratification | transient | at `audit` |

A patch is the *cable*. It selects across the whole graph, can pull three
statements from one intake and two from another, is redefinable without
touching anything it selects, and its whole point is the compilation history
that accumulates as the graph moves underneath it. A namespace is the
*module on the rack*: assigned once, never reassigned, and the thing a
cable reaches into.

Both are wanted, and conflating them loses the property that makes each
useful. If the namespace were revisable, statements would migrate between
groups and the journal would stop being a record of where thoughts came
from. If a patch were exclusive, you could not route one statement into two
arguments — which is the entire reason to have selectors.

**Reordering is already free, and is a patch's job, not a namespace's.** The
graph carries no order; document order is *computed* by
`Graph.topo_sort/3` (`lib/socrates/graph.ex:19`) — layered by longest-path
depth, defs and refs first, journal order only as a tiebreak. Nothing about
namespacing would make statements more reorderable than they are today, and
the proposal should not be justified on that. What it makes possible is
**recombination across stores** — which is genuinely absent, and is §6.

## 4. Notation: the enclosure, and bare-inside / qualified-across

The instinct in the question — an enclosure above the nodes rather than a
prefix on every node — is the right shape, and it earns its keep through one
rule:

> **A dep inside the enclosing namespace renders bare. A dep crossing a
> namespace boundary renders qualified.**

That is what makes the enclosure load-bearing instead of decorative: the
common case pays nothing, and every long name on the page marks a real
cross-module edge. Applied to the example, in a store where
*representation ratification* is an already-ratified global def:

```
{2026-08-07-operator-failure-sounds-like}
⊢ [attest_1] I want to name a recurring operator failure.
⊢ [attest_2] Dense, opaque communication that would be expensive to unpack gets left unpacked.
⊢ [attest_3](attest_2) The operator leaves that communication unpacked because the operator
  assumes the agent knows what it is doing.
⊢ [def_1](attest_2, attest_3) *sounds like you know what you're doing* : The recurring operator
  failure in which communication that would be expensive to unpack is left unpacked because
  the operator assumes the agent knows what it is doing.
⊢ [infer_1](attest_2, attest_3) Default-approval is the path of least resistance.
```

A statement elsewhere depending across the boundary writes the qualified
form:

```
{2026-08-14-approval-envelopes}
  [act_1](2026-08-07-operator-failure-sounds-like/infer_1) Require a restatement before approving …
```

Ergonomics, so the canonical form's length never has to be typed:

- **Prefix resolution, git-style.** Any unambiguous prefix of the namespace
  name resolves: `sounds-like/infer_1`, and an ambiguous prefix is an error
  listing the candidates — never a guess. The store is small; this is a
  `String.starts_with?` filter with an arity check.
- **A single-statement namespace follows the identical pattern**, as the
  question expects — an enclosure with one node under it. No special case.
- **The name is a name, not a content hash.** A hash-as-identity fails on an
  append-only graph: amend one statement and the namespace's content digest
  moves, so every reference to it rots. Digests belong where 0003 already
  puts them — in a compilation header, as a *witness* of what the graph was
  at a moment (`plans/0003-composition-and-measurement.md:33-37`), which is
  the property that lets you tell model variance from argument drift. Keep
  the two roles apart.
- **Suggested default form** — `YYYY-MM-DD-slug`, as written in the
  question; derived from the intake filename or given as `intake … --as
  <slug>`, and journaled either way. Dates sort, slugs recall.

## 5. Two options, one recommendation

The audit's own pattern for a decision of this shape (`plans/0001-audit.md:85`)
is two options with a recommendation, so:

### Option A — namespace as a label

The `exchange_opened` event gains a `name`; `Statement` gains nothing;
display ids stay store-global exactly as D7 ratified. `render` prints the
enclosure by grouping on `exchange`, and `{name}` joins the selector
grammar as an alias for `@n`.

- **Gets:** the name, the visible boundary, `render {sounds-like}`, a
  grouped `graph`, and a durable record of what each intake was *about*.
- **Does not get:** the local numbering back; portable fragments.
- **Costs:** one optional journal field, one selector clause, one render
  header. No identity change, no migration, no gate change, no amendment to
  a ratified decision. Roughly an hour, and it is additive-only — old
  journals fold unchanged, because a missing name falls back to `@n`.

### Option B — namespace as an identity scope

Display ids become namespace-local: `next_index/2`
(`lib/socrates/journal.ex:321`) counts per `(namespace, type)`, uniqueness
becomes `(namespace, display_id)` — including the revises-chain key in
`fold/1` (`lib/socrates/journal.ex:277-289`) — and the model's artifact-local
ids can be *kept* rather than rewritten, since the artifact is the
namespace. `E_DUP_ID`'s global-collision check (`lib/socrates/gate.ex:41`)
becomes namespace-relative. `display_fun/1` (`lib/socrates/cli.ex:1071`)
qualifies a dep whose namespace differs from the rendering context.

- **Gets:** everything in A, plus the page-local numbering that survives
  ratification, plus the precondition for export/import of fragments.
- **Costs:** a D7 amendment (an amendment, not a repeal — "unique for the
  life of the store" becomes "unique within its namespace, for the life of
  the store"); a migration decision for ids already assigned; and §6 has to
  be settled first, because import is the only reason to pay for it.

Deps are stored as **sids**, not display ids (`plans/0001-mvp-harness.md:117`),
which is why B is far cheaper than it looks: renaming the view layer cannot
break an edge. The graph does not notice.

**Recommendation: A now, B when there is a second store to import into —
and journal the name from day one either way.** Two facts drive this. First,
there is no store yet: acceptance step 6 is still pending and the dogfood
store is uninitialized (`operator_next_steps.md` §0–§1), so fragment reuse
is speculative in a way that a named intake is not. Second, A is
forward-compatible with B — if every exchange carries a name from its first
day, B is later a *re-interpretation of data already recorded*, not a
migration. That is cheap insurance against the expensive version of this
decision, and it is the only part of this document worth acting on before
the week of live intakes.

## 6. The hard part: what a *fragment* has to answer

Reuse across stores is the only thing that makes B pay, and it raises three
questions the notation does not touch.

**6.1 A fragment is not self-contained.** The example's `def_1` will, if
scoped `:global`, ride in the system prompt of every subsequent intake
(`spec/loadout-v0.md:110-125`) — which means the repo *already has* a unit
of reuse: the ratified global def. It is one line, not a subgraph, and it is
the only thing that currently crosses exchange boundaries by design. A
subgraph fragment, by contrast, drags dependencies: an `infer` is worthless
without its premises, and a body using `*a term*` is refused outright unless
that term has a def in scope (`E_TERM_UNDEF`, `lib/socrates/gate.ex:98-103`).
So import must compute a closure and then, for each cross-namespace dep,
either bind to an equivalent statement already present, copy it in as its
own namespace with provenance, or refuse. Never dangle. This is the module
system's import problem in full, and it is the bulk of B's real cost — not
the renaming.

**6.2 Ratification does not travel.** `ratified` is a claim by *an*
operator, at a time, after comprehension. The invariant the whole system
serves is that only the operator changes a statement's state; a fragment
arriving pre-ratified from another store — or from the same operator six
months earlier — would be a state change no one performed here. The only
consistent rule: **imported statements enter `proposed`**, whatever they
were where they came from, and their prior ratification is recorded as
provenance, never as state. Anything else makes import a laundering channel
for the one thing the store is built to make expensive.

**6.3 The feature is a described failure mode.** The prose that prompted
this asks for a name for the failure where *dense, opaque communication that
would be expensive to unpack gets left unpacked because the operator assumes
the agent knows what it is doing.* A library of pre-packaged, pre-ratified,
recombinable fragments is a machine for producing exactly that input:
dense, opaque, expensive to unpack, and carrying a ratification glyph that
says someone already checked. It would make default-approval the path of
least resistance — the example's own `infer_1`.

That is not an argument against the feature. It is an argument that import
must cost at least what intake costs — statement-by-statement, at reading
pace, with rejection notes — and that if it ever gets a bulk mode, plan
0006's canary should watch it first. The one thing to refuse outright is an
`import --all --ratified`.

## 7. What would change in code, if B were built

Named for scoping, not as a work order:

| Site | Change |
|---|---|
| `journal.ex:41-51`, `154-162` | `exchange_opened` gains `name`; strict-key list extended |
| `statement.ex:15-31`, `to_pairs/1`, `from_map/1` | one `namespace` field, canonical order, strict decode |
| `journal.ex:321` `next_index/2` | per `(namespace, type)` |
| `journal.ex:277-289` chain validation | chain key becomes `(namespace, display_id)` |
| `gate.ex:26,41` | `E_DUP_ID` global-collision check becomes namespace-relative |
| `cli.ex:924-930` `accept_artifact/4` | keep artifact ids when the namespace is fresh |
| `cli.ex:1071` `display_fun/1` | qualify across namespaces, bare within |
| `cli.ex:423-430` `select/2` | `{name}` and prefix resolution |
| `render.ex:26` `document/3` | group by namespace, emit the enclosure |
| `spec/cli-v0.md`, `spec/loadout-v0.md` | selector grammar, notation, dep-scope wording |

`verify` and `definitions.json` are untouched — the first hashes archived
bytes, the second is a term-keyed fold export. Neither reads display ids.

## 8. Open questions — the ones a week of use should answer

1. **Does the operator ever want a cross-namespace dep at all?** If real
   graphs turn out to be thickets of them, the enclosure's bare-inside rule
   stops paying and the flat store-global form was right. If they are rare,
   every qualified name on the page is a signal worth reading. This is
   measurable from the first ten intakes and should decide B.
2. **Does `def scope: local` mean "namespace-private"?** It is the obvious
   reading and it would sharpen a scope that is currently fuzzy — note that
   `check_operator/2` (`lib/socrates/gate.ex:82-88`) resolves terms against
   every live def regardless of scope, while `check_artifact/2` restricts
   the model to artifact-local ∪ global. Namespaces would give that
   asymmetry a principled boundary, or expose it as a defect.
3. **Is the namespace the intake, or can the operator open one by hand?**
   `add` writes into no exchange today. A `--ns` flag, or a notion of a
   current namespace, is a small surface with a large habit attached.
4. **Amendment across namespaces.** A `revises` chain currently shares one
   display id; if display ids are namespace-local, may an amendment live in
   a different namespace from the statement it supersedes? Saying no keeps
   chains inside modules and is the conservative default.
