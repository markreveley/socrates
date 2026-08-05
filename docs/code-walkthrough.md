---
title: "Tutorial — walking the 0001 code"
status: companion documentation for the 0001 build; descriptive, not normative
date: 2026-08-05
---

# Tutorial — walking the 0001 code

A guided walk through the MVP harness as built — module by module, then two
end-to-end traces: one deterministic write (`add`) and the one inference
write (`intake`). Written against the build at the tip of
`claude/build-0001` (line references are approximate beyond that commit;
function names are stable). The normative documents remain
[`spec/cli-v0.md`](../spec/cli-v0.md),
[`spec/scenarios-v0.md`](../spec/scenarios-v0.md), and
[`plans/0001-mvp-harness.md`](../plans/0001-mvp-harness.md) — this file
explains *how the code does it*, never *what it must do*.

**Follow along.** Everything below is runnable without an API key:

```
mix deps.get && MIX_ENV=prod mix escript.build
mkdir /tmp/walk && cd /tmp/walk
export PATH=$PATH:/path/to/socrates_   # or invoke ./socrates by path
socrates init
```

The invariant to keep in view, because every module is shaped by it:
**models emit data; the gate stands between data and effect; only the
operator changes a statement's state.**

## 1. The shape of the build

Nine modules plus the CLI, ~2,500 lines, one dependency (`req`, used only
by the live client). Data flows one way:

```
  operator ── add / amend ──▶ Gate.check_operator ──▶ journal  (enters ratified)
  prose ──── intake ──▶ Client ──▶ Gate.check_artifact ──▶ journal  (enters proposed)
                                                              │
  operator ── ratify / reject ──────────────────────────────▶ journal  (state_changed)
                                                              │
                       journal.jsonl ── Journal.fold ──▶ in-memory state
                                              │
              ┌───────────────┬───────────────┼──────────────────┐
              ▼               ▼               ▼                  ▼
        definitions.json   render/show   deps/rdeps/graph     verify
        (derived export)   (Render)      (Graph)              (re-hash archives)
```

| Module | File | One line |
|---|---|---|
| `Socrates.Statement` | `lib/socrates/statement.ex` | the struct, its lint, its canonical serialization order |
| `Socrates.Sid` | `lib/socrates/sid.ex` | ULID generation, 22 lines, stdlib only |
| `Socrates.Journal` | `lib/socrates/journal.ex` | append/fold + the deterministic JSON encoder |
| `Socrates.Graph` | `lib/socrates/graph.ex` | topological order, cycles, closures — context-neutral |
| `Socrates.Gate` | `lib/socrates/gate.ex` | the check table, run on every write |
| `Socrates.Loadout` | `lib/socrates/loadout.ex` | the v0 language as data: types, API schema, system prompt |
| `Socrates.Client` | `lib/socrates/client.ex` | transport behaviour + the hand-assembled request |
| `Socrates.Client.Anthropic` | `lib/socrates/client/anthropic.ex` | the live door (Req) |
| `Socrates.Client.Fixture` | `lib/socrates/client/fixture.ex` | the canned door (tests, acceptance) |
| `Socrates.Render` | `lib/socrates/render.ex` | bracket notation, the `⊢` |
| `Socrates.CLI` | `lib/socrates/cli.ex` | dispatch, exit codes, stderr footers — where everything meets |

Reading order matters less than knowing the layering: `Journal` is the
spine (everything folds through it), `Graph`/`Gate`/`Render` are pure
functions over fold output, `Client` is a transport, and `CLI` is the only
module that touches all of them.

## 2. One statement, at rest

Before the code, the data. Run:

```
$ socrates add --type attest --body "apples are fruits"
attest_1 01KZ9N1NYRFW7DME6E51YRXC2X
$ cat .socrates/journal.jsonl | tail -1 | jq .
```

You get one `statement_added` event (shown pretty; the file is one compact
line):

```json
{
  "event": "statement_added",
  "statement": {
    "sid": "01KZ9N1NYRFW7DME6E51YRXC2X",   // permanent identity (ULID)
    "display_id": "attest_1",              // view-layer name, store-global (D7)
    "type": "attest",
    "body": "apples are fruits",
    "deps": [],                            // sid-edges when present, never display ids
    "notes": [],
    "exchange": 1,                         // operator's standing exchange
    "seq": 1,                              // ordinal within the exchange
    "state": "ratified",                   // authorship is assent
    "author": "operator",
    "inserted_at": "2026-08-05T19:05:14Z"
  },
  "ts": "2026-08-05T19:05:14Z"
}
```

Three things to notice, because the whole design hangs on them:

- **`sid` vs `display_id`.** The sid is permanent and meaningless; the
  display id is the human name. Deps are stored as sids, so renaming and
  supersession never corrupt edges — display ids are resolved back out at
  render time.
- **Absent fields are absent** (`term`, `scope`, `origin`, `revises`,
  `provenance`, `artifact_id` don't appear on this statement). The encoder
  skips nils; there are no nulls in the journal.
- **`state` is data the model can never produce.** The model's output
  schema (§8) has no state field. States change only through
  `state_changed` events, which only `ratify`/`reject`/`amend` write.

The four event kinds are `exchange_opened`, `statement_added`,
`state_changed`, `intake_rejected` — that is the complete journal
vocabulary.

## 3. `Socrates.Journal` — the spine

`lib/socrates/journal.ex`. Read it in three passes.

### 3a. The encoder owns byte determinism

Stdlib `JSON.encode!` on a map gives unspecified key order, and the store's
promises (reproducible digests, `encode |> decode |> encode` byte-identical)
need bytes, not structures. So the encoder is hand-rolled around one small
idea — `emit/1` (line ~116):

```elixir
def emit({:obj, pairs}) do            # explicit order, nils skipped
  inner =
    pairs
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> [JSON.encode!(k), ":", emit(v)] end)
    |> Enum.intersperse(",")

  IO.iodata_to_binary(["{", inner, "}"])
end

def emit(%{} = map) do                # plain maps: sorted keys
  ...
end
```

Two object forms: `{:obj, pairs}` keeps the given order — used for journal
events and statements, whose field order is canonical — and plain maps emit
sorted keys — used for the API request body, the schema, and
`definitions.json`, where any *fixed* order is enough. Scalar and list
encoding delegates to stdlib `JSON` (which handles escaping), so the
hand-rolled part is exactly the part stdlib doesn't promise: order.

Who decides statement field order? Not the Journal —
`Socrates.Statement.to_pairs/1` does, next to the struct definition, so
the struct and its serialization can't drift apart.

The property test (`test/journal_test.exs`, "properties") throws 300
seeded-random events at this — tricky strings included (quotes,
backslashes, newlines, `⊢`, emoji) — and asserts
`encode |> decode |> encode` is byte-identical every time.

### 3b. Append is tiny and paranoid

```elixir
def append(store, event) do
  line = [encode(event), "\n"]

  File.open!(Path.join(store, @journal), [:append, :raw, :binary], fn io ->
    :ok = :file.write(io, line)
    :ok = :file.sync(io)               # fsync on every append
  end)

  :ok
end
```

One line per event, fsync before returning. The decode side is equally
strict: a torn final line (no trailing newline), a malformed line, an
unknown event kind, an unknown field — each is a raised `Journal.Error`,
never a silent skip. The CLI catches it and exits `2`. A journal you can't
fully parse is a journal you don't act on.

### 3c. Fold: the journal is the database

`fold/1` (line ~231) reads every line and reduces to:

```elixir
%{statements: %{sid => %Statement{}},
  order:      [sid],                  # journal insertion order
  chains:     %{display_id => [sid]}, # revises chains; live head is last
  exchanges:  [n],
  events:     [event]}                # parsed, for `log`
```

`chains` is the D7 machinery in data form: every display id maps to the
list of sids that have carried it, oldest first. `amend` appends to the
chain; `Journal.head/2` returns the last entry — the live head — which is
what every display-id lookup in the CLI resolves to. The fold also
*validates* chain shape while replaying: a reused display id without a
`revises` pointing at the current head is a hard error.

There is no cache and no index; every command re-folds. At MVP scale that
is milliseconds, and it buys the property the plan demands: **folding twice
yields identical state** (also property-tested — fold is a pure function of
the file).

Three derived views sit at the bottom of the file:

- `global_defs/1` — live ratified `:global` defs, display order. This is
  what the gate's term scanner and the system prompt read. Note what they
  do *not* read: `definitions.json`.
- `next_index/2` — next free display index per type, computed over **every
  id ever journaled**, any state. Rejected and superseded ids stay
  consumed; display ids are unique for the life of the store.
- `export_definitions/2` — writes `definitions.json` as
  `{term → {body, display_id, sid}}`. It is a derived export, regenerated
  after every fold, and never read back as authority (audit B2). Delete it;
  the next command rewrites it. Hand-edit it; nothing changes, because
  nothing trusts it.

## 4. `Socrates.Sid` — identity in 22 lines

```elixir
def generate(ms \\ System.system_time(:millisecond)) do
  encode(<<0::2, ms::48, :crypto.strong_rand_bytes(10)::binary>>)
end

defp encode(bits), do: for(<<index::5 <- bits>>, into: "", do: <<Enum.at(@alphabet, index)>>)
```

A ULID: 48-bit millisecond timestamp, 80 random bits, two zero pad bits →
130 bits → 26 characters of Crockford base32. The timestamp prefix makes
sids sort by creation time; the 80 random bits make collision a
non-concern. `valid?/1` is how the CLI tells a sid argument from a display
id — the two surface forms can't overlap (display ids match
`^(def|ref|attest|infer|act|did)_\d+$`; sids are 26 chars of an alphabet
with no lowercase and no underscore).

## 5. `Socrates.Statement` — the struct and its lint

One struct carries both operator and model statements; the difference is in
which fields are filled and by whom. Two fields deserve a pause:

- `artifact_id` — the display id **the model used inside its artifact**.
  Kept forever on accepted statements, so the D7 renumbering is a journaled
  mapping (`attest_1 → attest_4`), not a lost translation.
- `provenance` — `%{calls: [...]}`, the full call history of the intake
  that produced the statement (request digest, request id, model, usage,
  response digest, per call). Operator statements carry `nil`.

`lint/1` is the *store-independent* shape check: defs declare a valid scope
(`E_DEF_NO_SCOPE`), refs carry a well-formed origin (`E_REF_NO_ORIGIN`),
def bodies that read multi-sentence or clause-conjoined warn
(`W_DEF_ATOMICITY`, advisory). Checks that need the store — dangling deps,
term resolution, cycles — live in the Gate.

`terms_in/1` is the term scanner, one regex: `\*([^*\n]+)\*`. Every
asterisk-delimited span in a body **is** a term usage — that's the loadout's
reserved-surface rule (`spec/loadout-v0.md` § the term rule). The app never
strips asterisks and never guesses at emphasis; an undefined term is
`E_TERM_UNDEF`, full stop. Canon's asymmetric `*…"` case doesn't scan (the
regex can't close it), which is exactly the documented behavior: only a
symmetric re-emission makes the term findable.

## 6. `Socrates.Graph` — order, cycles, closures

Deliberately context-neutral: every function takes `key` (statement → node
key) and `deps_of` (statement → keys), so the same code serves the store
graph (keys = display ids, deps resolved from sids) and a raw model
artifact (keys = artifact-local ids, deps as emitted). Edges leaving the
selection are treated as satisfied — that's how an exchange renders cleanly
while depending on `def_1` outside it.

`topo_sort/3` is a **layered** order, not a queue-based Kahn:

```elixir
statements
|> Enum.with_index()
|> Enum.sort_by(fn {s, i} -> {depths[key.(s)], class(s), i} end)
```

Sort by longest-path depth (memoized DFS, `depth/4`), then defs/refs first
within a layer (`class/1`), then input order. Any edge forces
`depth(dependent) > depth(dep)`, so the result is always a valid
topological order — and layering is the one rule consistent with both
normative renders: scenario 3 shows *all* premises before the first
conclusion; scenario 4 shows the repair-minted `def_2` first. (A
plain extract-min Kahn satisfies scenario 4 but not 3; the test
`test/graph_test.exs` pins both.)

`cycle/3` is a DFS with an on-path set that throws the closed path when it
bites (`["a_1", "b_1", "a_1"]`) — the gate prints it verbatim. `reach/2` is
a BFS used by `deps --all`, `rdeps --all`, and the `+deps`/`+rdeps`
selectors; discovery order makes `rdeps attest_1 --all` print `infer_1`
then `act_1`, closest first.

## 7. `Socrates.Gate` — one table, two doors

The check table, in fixed order:

```
E_ID_FORM · E_DUP_ID · E_DANGLING_DEP · E_CYCLE · E_TERM_UNDEF ·
E_DEF_NO_SCOPE · E_REF_NO_ORIGIN · W_DEF_ATOMICITY (warning)
```

Two entry points, and their difference is the design's asymmetry made
executable:

**`check_artifact/2`** — every model proposal. Subjects are the model's
artifact-local ids (the conversation the model can follow — repair messages
say `attest_3`, meaning *the artifact's* third attest). Deps resolve
against **artifact-local ids ∪ live ratified global defs** — exactly what
the model was shown. A dep on a store statement the model never saw is a
hallucination and dangles. Terms resolve against artifact defs ∪ ratified
global defs. Reusing a listed global def's display id is `E_DUP_ID`.

**`check_operator/2`** — every `add`/`amend`. The operator sees the store,
so terms resolve against *any* live def in it, local or global. (Dep
resolution for operators lives in the CLI, because the operator's argument
surface accepts sids — a form the gate never sees from models.)

Both doors share `shape_pass/2`, which also does the one *mutating* thing
the gate is allowed: hashing `file` origins
(`hash_origin/1` — read the file, stamp `origin.sha256`). Measured, never
trusted: the model schema has no sha256 field to lie in.

All checks run and all findings return at once — the repair loop sends the
model the complete list, not the first failure.

## 8. `Socrates.Loadout` — the language as data

The prose twin is `spec/loadout-v0.md`; this module is what runs. Three
surfaces:

- `types/0` and `id_pattern/0` — the six ratified types and the display-id
  form the gate checks.
- `schema/0` — the structured-output schema: `{"statements": [...]}` where
  each item is an `anyOf` of six per-type shapes. Every object has
  `additionalProperties: false`; closed sets are `enum`s; `deps`/`notes`
  are required-but-may-be-empty (a model must say "no deps" explicitly);
  and there are no `minLength`/`pattern` constraints because the
  structured-output subset doesn't support them — the gate re-checks
  everything anyway. Look for what's *absent*: no `state`, no `sid`, no
  `sha256`. `test/loadout_test.exs` pins all of this, including "no
  app-stamped fields leak into any branch".
- `system_blocks/1` — the system prompt: block 1 is `spec_text/0` (the
  language taught to the model — types, the term rule, dep scope, the
  repair protocol), block 2 is `definitions_block/1` (live ratified global
  defs, **with display ids** — without them the model could neither dep on
  `def_1` nor avoid colliding with it), carrying
  `cache_control: {"type": "ephemeral"}` as the last block.

## 9. `Socrates.Client` — transport honesty

The behaviour is deliberately dumb:

```elixir
@callback call(body :: binary(), config :: map()) :: {:ok, response()} | {:error, term()}
```

A client takes **already-encoded bytes** and returns **raw response
bytes**. Request assembly lives above the behaviour
(`Client.build_request/2` + `encode_request/1`), shared by both
implementations — so the sha256 in provenance covers exactly the bytes
sent, and the fixture's provenance digests are real digests of real
requests. `build_request/2` is the plan's Inference section as a literal:
model (default `claude-opus-5`, `SOCRATES_MODEL` override),
`max_tokens: 16000`, no `thinking` key (on by default for this model),
system blocks from the Loadout, `output_config` with the schema.

**`Client.Anthropic`** is ~60 lines of Req configuration where each option
is a decision from the audit:

```elixir
body: body,                # raw digested bytes — never json: (re-encoding could diverge)
retry: false,              # Req doesn't retry POSTs; transport failure exits 2
decode_body: false,        # raw bytes back — archives are byte-exact
receive_timeout: 600_000,
connect_options: [transport_opts: [cacerts: :public_key.cacerts_get()]]
```

The `cacerts` line is audit B1: escripts don't ship `priv/` directories,
castore serves its CA bundle from one, so the packaged escript would fail
TLS with Req's defaults. The OS trust store (available because OTP ≥ 27 is
pinned) sidesteps it — and it's why acceptance requires one live intake
*from the built escript*, not `mix`. `HTTPS_PROXY` is honored when set.

**`Client.Fixture`** answers the question "how do you test a gated
inference pipeline deterministically?" It parses the request it's given
and serves canned API-shaped responses — `model: "fixture"`, zero usage,
no request id (honest provenance, never a real model's name). The built-in
keying: a source containing canon #1's `*representation ratification*`
marker gets the acceptance sequence — first a decomposition whose coined
term has no def (the gate finds exactly `E_TERM_UNDEF` on `attest_3`),
then, on the repair turn, the corrected artifact with `def_2` minted.
Any other source gets a persistently-broken artifact (a dep on `attest_9`
that nothing defines) so the failure path is walkable. `fixture:<path>`
serves your own JSON array of responses by call index — that's how the
`stop_reason: max_tokens` test forces a truncation.

Which call is round N? The fixture derives it from the conversation shape:
`div(length(messages) - 1, 2)` — 1 message = first call, 3 = after one
repair, 5 = after two.

## 10. `Socrates.CLI` — where everything meets

`main/1` is one line: `System.halt(run(argv))`. `run/1` wraps dispatch
with the two universal behaviors:

```elixir
def run(argv) do
  Process.put(:socrates_footer, :deterministic)
  code =
    try do
      dispatch(argv)
    catch
      {:abort, code} -> code            # abort/2 printed and threw
    end
  IO.write(:stderr, footer_line() <> "\n")
  code
end
```

- **The boundary footer is unconditional** — every command, success or
  failure, ends with `[deterministic]` or `[inference: …]` on stderr. The
  footer starts deterministic and flips only when an inference call
  actually completes (`set_inference_footer/1` inside the intake loop) — so
  a failed intake that never reached the model honestly says
  `[deterministic]`, and a gate-rejected intake that did call says
  `[inference: fixture · - · 0 in / 0 out]`.
- **`abort/2`** prints to stderr and throws; usage errors anywhere
  short-circuit to the footer with exit `2`.

Every store command goes through `with_store/2`: check `./.socrates`
exists (else the exact `no .socrates here (run: socrates init)` line), fold
the journal, regenerate `definitions.json` (derived export, every fold),
hand the command a `%{dir, fold}` context. Commands that write call
`refresh/1` — fold again, export again — before printing results.

### Trace 1 — `socrates add --type infer --dep attest_1 --dep attest_2 --body "apples reproduce"`

1. **Parse** (`cmd_add` → `parse!`): strict `OptionParser`; unknown flags,
   flags on the wrong type, a missing `--term` on a def — all usage errors,
   exit `2`, before any content check.
2. **Build** (`statement_from_flags/3`): body from `--body` or stdin
   (stdin strips exactly one trailing newline); `%Statement{}` candidate
   with type, body, notes, parsed origin.
3. **Resolve deps** (`resolve_deps/3`): each `--dep` arg goes through
   `resolve/2` — display id → chain live head, or sid → exact statement.
   Missing target: `E_DANGLING_DEP … dep infer_9 not found`. A dead target
   (rejected/superseded head): also `E_DANGLING_DEP`, with the state named.
   Survivors become **sids** — this is the "deps are sid-edges, resolved at
   write time" rule (D7) in code.
4. **Gate** (`Gate.check_operator/2`): shape lint + term scan against the
   store's live defs + file-origin hashing. Any error: findings print as
   `<CODE> <subject>: <detail>` (subject is the bare type — no id is
   assigned yet), exit `1`, **nothing journaled**.
5. **Stamp** (`finalize_operator/3`):

   ```elixir
   | sid: Sid.generate(),
     display_id: s.display_id || "#{s.type}_#{Journal.next_index(ctx.fold, s.type)}",
     exchange: exchange,          # 1 — the operator's standing exchange
     seq: ...,                    # ordinal within exchange 1
     state: "ratified",           # authorship is assent
     author: "operator",
   ```

6. **Journal + refresh + print**: one `statement_added` append (fsynced),
   re-fold, re-export definitions (a `:global` def add is promoted here —
   no special case needed), then the only stdout of the command:
   `infer_1 <sid>`.

### Trace 2 — `SOCRATES_CLIENT=fixture socrates intake canon-block.txt`

`cmd_intake` (line ~713) then `intake_loop` (~772). Numbered as it runs:

1. **Client selection first** (`client_from_env/0`): `fixture`,
   `fixture:<path>`, or `anthropic` — and the anthropic path demands
   `ANTHROPIC_API_KEY` *before anything mutates* (env failure = exit `2`,
   store untouched).
2. **Open the exchange**: `max(exchanges) + 1` → `2`. If
   `sources/2/` already holds files (crash debris from a torn intake), the
   command refuses rather than violate write-once.
3. **Archive the source verbatim**: bytes as read — no trimming, no
   normalization — to `sources/2/source.txt`; sha256 into the
   `exchange_opened` event; stderr line
   `exchange 2 opened · source archived 8ebf9776be36`.
4. **Build the request** (`Client.build_request` + `encode_request`):
   system blocks carry the loadout spec and the current global defs
   (`def_1` with its display id). The request bytes are digested —
   `request_sha256` — before anything is sent.
5. **Call, archive, record** (`intake_loop`): the response body bytes are
   archived as `response-1.json` *before* parsing; the call record
   (`n`, `model`, `request_id`, `request_sha256`, `response_sha256`,
   `usage`, `ts`) is appended to the running `calls` list; the footer
   flips to inference.
6. **`stop_reason` check** (audit B3): anything but `end_turn` —
   truncation, refusal — journals an `intake_rejected` with a
   `stop_reason` finding and exits `1`. The archived raw response is never
   fed to the gate as if complete.
7. **Decode the artifact** (`artifact_statements/1`): the last text
   block's text, parsed and strictly shape-checked (exactly the
   model-suppliable fields, string-typed). Statements get `artifact_id`
   from the model's `display_id`; `display_id` stays empty — the store
   hasn't named them yet.
8. **Gate**: round 1 on canon finds exactly one error. Stderr:

   ```
   gate: E_TERM_UNDEF attest_3: term *Sounds like you know what you are doing* has no def in scope
   repair 1/2 …
   ```

9. **Repair turn**: the conversation grows by the model's artifact text
   (assistant) and `{"gate_errors": [{code, subject, detail}, …]}` (user)
   — the loadout told the model to expect exactly this and to re-emit the
   complete artifact. Loop back to step 4; the fixture serves the
   repaired artifact with `def_2` minted; round 2 gates clean:
   `gate: pass (5 statements, 0 warnings)`.
10. **Acceptance** (`accept_artifact/4`) — D7 in one function, read it
    (line ~924): sids generated; final display ids assigned per type in
    artifact order (`attest_1..4 → attest_4..7`, `def_2 → def_2` because
    the store's next def index was already 2); then dep rewriting:

    ```elixir
    by_artifact_id = Map.new(assigned, &{&1.artifact_id, &1.sid})
    ...
    Enum.map(s.deps, fn dep ->
      by_artifact_id[dep] || Journal.head(ctx.fold, dep).sid
    end)
    ```

    An artifact-local dep resolves to a sibling's new sid; anything else
    can only be a global def (the gate guaranteed it) and resolves to the
    def's live head sid. Every statement enters `proposed`,
    `author: "model"`, carrying the full `calls` provenance and its
    `artifact_id` — the journaled mapping.
11. **Render to stdout**: the new exchange's statements, topologically
    ordered, no `⊢` anywhere — nothing is ratified yet. That's the
    operator's move, and the only remaining one:
    `socrates ratify def_2 attest_4 attest_5 attest_6 attest_7`.

The failure path (scenario 5) is the same loop with the exits taken:
three rounds of the same `E_DANGLING_DEP`, then `reject_intake/6` — the
last artifact saved as `rejected-2.json`, an `intake_rejected` event
carrying the errors, all call records, and the rejected file's digest,
exit `1`. Rejected artifacts are kept deliberately: they are the free eval
corpus.

### `amend` — supersession, never mutation

`cmd_amend` reuses `statement_from_flags` with the type fixed, then does
the one check `add` can't need — `revised_cycle/3`: rebuild the live graph
with the chain's edges swapped for the candidate's and run `Graph.cycle`.
(Amending `attest_1` to dep on `infer_1`, which deps on `attest_1`, is the
textbook case — refused with the printed path.) On success: a
`statement_added` with the **same display id** and `revises: <old sid>`,
then a `state_changed` superseding the original — that exact order is
pinned by scenario 7's `log` output. The replacement is operator work:
`ratified`, exchange 1, even when the original was a model proposal.

### `verify` — the de Bruijn move

`cmd_verify` + `archive_records/1`: walk the fold's events and collect
every digest the journal has ever recorded — `exchange_opened.source`,
each provenance call's `response-<n>.json`, each `intake_rejected`'s calls
and rejected artifact. Re-hash every file; `MISMATCH`/`MISSING` per
problem; files under `sources/` that no record vouches for are
`UNRECORDED` (a foreign object in the verbatim area is a tamper signal).
Then re-hash `file`-kind origins of live refs. Zero network, zero
inference — a small, dumb, independent checker, which is the point.

## 11. The tests as executable spec

`mix test` — 98 tests, all against the fixture. The layout mirrors the
walk you just did:

- `test/journal_test.exs` — encoder canon, fold semantics, chain
  validation, the two required property tests (seeded `:rand`, stdlib-only
  generators — no property-testing dep, because D1 allows only `req`).
- `test/graph_test.exs` — the layered-order pins from scenarios 3 and 4.
- `test/gate_test.exs` — one test per table row, subjects and details
  exact, including the scenario 4 finding verbatim.
- `test/loadout_test.exs` — the schema pins (try adding a `state` field to
  a branch and watch it fail).
- `test/client_test.exs` — request assembly, fixture honesty, digest
  reproducibility (`Journal.emit(JSON.decode!(bytes)) == bytes`).
- `test/cli_scenarios_test.exs` and `test/intake_test.exs` — scenarios 1–7
  as byte-exact integration tests, cumulative store and all. When the spec
  says a line is exact, the assertion is `==` on the whole stream, sids
  and timestamps pattern-matched.

## 12. Exercises

1. **Read your own journal.** After a session:
   `jq -r '.event' .socrates/journal.jsonl | sort | uniq -c`. Then find an
   amend chain: `jq 'select(.statement.revises != null)' …`.
2. **Trip each gate code by hand.** `E_DANGLING_DEP` and `E_TERM_UNDEF`
   fall out of scenarios 2 and 4; get `E_CYCLE` from `amend` (see §10);
   `E_DEF_NO_SCOPE` from `add --type def` without `--scope`;
   `W_DEF_ATOMICITY` from a two-sentence def body.
3. **Force a truncation.** Write a one-element `responses.json` with
   `"stop_reason": "max_tokens"`, run
   `SOCRATES_CLIENT=fixture:responses.json socrates intake anything.txt`,
   then read what the journal recorded about it.
4. **Tamper and get caught.** Append a byte to any
   `.socrates/sources/**` file → `verify` exits `3`. Then create a file
   the journal never recorded (`touch .socrates/sources/2/extra.txt`) and
   see `UNRECORDED`.
5. **Check the D7 mapping.** After an intake:
   `jq -r 'select(.statement != null) | [.statement.artifact_id, .statement.display_id] | @tsv' .socrates/journal.jsonl`
   — the model's names beside the store's.
6. **Prove the digest is reproducible.** Take any provenance
   `request_sha256`; the request bytes aren't archived, but
   `Client.build_request` + `encode_request` on the same fold and source
   reproduce them exactly — that's what the determinism buys.
