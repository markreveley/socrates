---
title: "Docs — research spike: the core theories, tested against outside evidence"
status: explanatory — non-normative; findings, not edits. Canon is verbatim and stays verbatim; where a claim's phrasing outruns the evidence, that is recorded here as an annotation, nothing more.
authorship: agent-drafted for operator review
date: 2026-08-05
method: >
  The repo's core theories and assertions were extracted from canon/, plans/,
  and the README, grouped into six clusters, and each cluster was researched
  by a separate agent instructed to verify every citation against the
  publisher, arXiv, or primary page (no citing from memory) on 2026-08-05,
  and to look for resisting evidence as hard as supporting evidence. Items
  that could not be verified are flagged inline. Anthropic API and
  Elixir/OTP claims were checked against current reference documentation
  directly.
---

# Research spike — support and resistance for the core claims

Verdict vocabulary used throughout: **supported** (independent external
evidence backs the claim as stated) · **supported-with-resistance** (backed,
but the literature documents real failure modes or costs) · **contested**
(credible evidence points both ways) · **accurate / stretch** (for lineage
claims: is the characterization faithful to the source?) · **untested** (no
direct evidence located; the claim rests on theory or analogy).

The one-line summary: **the diagnosis is well-supported, the intervention is
supported as a mechanism but carries a documented adoption risk, the
architecture turns out to be the emerging consensus shape rather than a
contrarian bet, the lineage claims are almost all accurate, and the
system's own self-doubt (the canary, the roundtrip, the "honest limit") is
repeatedly the thing the literature independently prescribes.** The
weakest links are named plainly in §7.

---

## 1. The diagnosis: comprehension debt and deference

### T1 — "the mental model an operator creates … is inevitably out of step with the reality" (canon/purpose.md §3)

**Supports.** Naur's ["Programming as Theory Building"](https://pages.cs.wisc.edu/~remzi/Naur.pdf)
(1985) is the classic ground: the program proper is the *theory* in the
builders' minds, not the text, and it cannot be reconstructed from code and
documentation alone — an operator who didn't build the theory doesn't
possess the program in the sense that matters. Bainbridge's
["Ironies of Automation"](https://en.wikipedia.org/wiki/Ironies_of_Automation)
(*Automatica* 1983) supplies the dynamics: automating the easy parts leaves
the human the hardest tasks precisely while their skill and current picture
degrade from disuse.

**Resists / limits.** No study was located that directly tests the
chat-specific claim, and the words "inevitably" and "never really catch up"
are stronger than any located evidence. Support is theoretical (Naur),
analogical (Bainbridge), and indirect (T2/T3 below).

**Verdict: supported in mechanism, untested in its strong form.** The
strong phrasing is canon and stays; a reader should know it is a thesis,
not a measured result. socrates itself, dogfooded, is the experiment.

### T2 — dense, opaque output "left unpacked in favor of assuming the agent 'knows what its doing', incentivizing … default approving" (canon/representation-ratification.md, claim_2)

**Supports.** This is the best-supported claim in the repo.

- Three decades of automation-bias/complacency research:
  [Parasuraman & Riley 1997](https://journals.sagepub.com/doi/10.1518/001872097778543886)
  (*Human Factors* — overreliance as "misuse"),
  [Skitka, Mosier & Burdick 1999](https://dl.acm.org/doi/abs/10.1006/ijhc.1999.0252)
  (experimental omission/commission errors with imperfect decision aids;
  non-aided participants out-monitored aided ones), and
  [Parasuraman & Manzey 2010](https://journals.sagepub.com/doi/10.1177/0018720810376055)
  (complacency and bias are attentional, robust across experts, not cured by
  experience or accountability). Default approval is the predictable
  equilibrium when verification is costly and the aid is usually right — a
  systemic dynamic, not a personal failing, which is exactly how canon
  frames it ("operator failure" as a *mode*, met by system design).
- [Lee et al., CHI 2025](https://dl.acm.org/doi/full/10.1145/3706598.3713778)
  (319 knowledge workers, 936 real GenAI uses): higher *confidence in the
  AI* correlates with *less* critical-thinking effort — the "sounds like
  you know what you're doing" dynamic measured.
- Code review specifically:
  [Gön, Yetiştiren & Tüzün, ICSME 2024](https://conf.researchr.org/details/icsme-2024/icsme-2024-papers/17/Towards-Unmasking-LGTM-Smells-in-Code-Reviews-A-Comparative-Study-of-Comment-Free-an)
  found 64.7% of studied PRs had comment-free reviews, with "LGTM smells"
  3.5× more frequent there; a 2026 mining study of AI-generated PRs
  ([Duma et al., preprint](https://arxiv.org/abs/2605.02273)) finds most
  receive no human review at all.

**Resists / nuances.** The [Stack Overflow 2025 survey](https://survey.stackoverflow.co/2025/ai/)
complicates the *attitude* half: 46% of developers actively distrust AI
output accuracy, yet adoption keeps rising — so the deference is enacted
(approving anyway) rather than believed. That refines the claim without
weakening it; if anything it strengthens the case that attitude is not the
lever and workflow design is.

**Verdict: supported.**

### T3 — comprehension, not generation, is the real bottleneck; perceived velocity diverges from real velocity (implicit throughout canon)

**Supports.**
[Xia et al., IEEE TSE 2018](https://dl.acm.org/doi/10.1109/TSE.2017.2734091)
(instrumented field study, 78 professionals, 3,148 hours): ~58% of developer
time is program comprehension — before AI multiplied the code-to-comprehend
per unit time. [Bacchelli & Bird, ICSE 2013](https://www.microsoft.com/en-us/research/publication/expectations-outcomes-and-challenges-of-modern-code-review/):
understanding is the central, under-tooled challenge of code review. The
perception gap is real:
[METR's 2025 RCT](https://arxiv.org/abs/2507.09089) (16 experienced
maintainers, 246 real tasks in deeply familiar repos) measured AI-allowed
work taking **19% longer** while developers estimated a **20% speedup** even
afterward. [GitClear's 211M-line analysis](https://www.gitclear.com/ai_assistant_code_quality_2025_research)
(vendor report, correlational) shows copy/paste rising and refactoring
collapsing (~25% of changed lines in 2021 to under 10% in 2024) — code
added faster than it is consolidated. 66% of SO-2025 respondents name
"almost right, but not quite" AI output as their top frustration.

**Resists.** Genuine velocity gains are demonstrated by RCTs elsewhere:
[Peng et al. 2023](https://arxiv.org/abs/2302.06590) (+55.8% on a
well-specified greenfield task) and
[Cui et al., *Management Science* 2025](https://pubsonline.informs.org/doi/10.1287/mnsc.2025.00535)
(three enterprise RCTs, 4,867 developers, +26.1% completed tasks). And METR
itself [walked back the currency](https://metr.org/blog/2026-02-24-uplift-update/)
of the 19% slowdown in Feb 2026 — the perception-gap finding is the durable
part, the magnitude/direction of slowdown is time- and context-bound.

**Verdict: supported-with-resistance, with a sharp boundary condition the
resistance itself draws.** AI speeds work where little prior mental model
exists (greenfield, task-count metrics) and slows or muddies it where a deep
one is required (mature repos the developer knows well). socrates is aimed
squarely at the second regime — building a system you must keep
understanding — which is exactly where the supporting evidence lives. Read
carefully, Peng-vs-METR is *evidence for* the comprehension-bottleneck
framing, not against it.

---

## 2. The intervention: friction, ratification, and the canary

### T4 — deliberate slowness as a forcing function for comprehension (canon/purpose.md §1, §3)

**Supports.**
- [Buçinca, Malaya & Gajos, CSCW 2021](https://arxiv.org/abs/2102.09692):
  cognitive forcing functions (decide first, forced wait, on-demand AI)
  significantly reduced overreliance on wrong AI recommendations where
  explanations did not.
- [Gajos & Mamykina, IUI 2022](https://arxiv.org/abs/2202.05402): people
  given AI answers showed no incidental learning; only those made to reach
  their own conclusion learned. Answer-delivery bypasses engagement;
  withholding the finished answer restores it.
- The learning-science base: desirable difficulties
  ([Bjork & Bjork 2011](https://www.unh.edu/teaching-learning-resource-hub/sites/default/files/media/2023-06/itow-introducing-desirable-difficulties-into-practice-and-instruction-bjork-and-bjork.pdf))
  and the generation effect
  ([Slamecka & Graf 1978](https://www.semanticscholar.org/paper/The-Generation-Effect:-Delineation-of-a-Phenomenon-Slamecka-Graf/bfda02b547504f0ccac817f9076674a7c2c0c91b)):
  effortful, self-generated processing reliably beats fluent consumption
  for retention — and learners systematically misread fluent conditions as
  effective, the lab-scale ancestor of T3's perception gap.
- At production scale: Twitter's 2020 read-before-retweet prompt
  ([TechCrunch](https://techcrunch.com/2020/09/24/twitter-read-before-retweet)):
  40% more article opens — a mild forcing function changing reading
  behavior, though measuring opens, not comprehension.

**Resists.** Two findings the design must carry:
- **The preference penalty.** In Buçinca et al., participants rated the
  interventions that helped them most as the *worst* — best performance in
  the least-liked condition. Friction pays its comprehension dividend only
  after surviving an adoption cost, and benefits skew toward users high in
  Need for Cognition.
- **Sludge.** [Sunstein 2019](https://dlj.law.duke.edu/article/sludge-and-ordeals-sunstein-vol68-iss8/):
  friction's first-order effect at scale is abandonment. He grants
  deliberation-serving ordeals as a legitimate exception — *conditional on
  continuous measurement*, i.e. sludge audits. Plan 0006 is, in effect, the
  sludge audit for socrates.

**Verdict: supported for comprehension, resisted on adoption.** The
operator's own "heavy handed for casuals" (canon §1) and "that's the dream
anyway" (canon §4) already price this honestly.

### T5 — ratification "converts 'sounds like you know what you're doing, keep going' into a set of discrete decisions" (canon, claim_3)

**Supports.** The active ingredient in the strongest T4 studies is exactly
per-item judgment *production* — deciding before seeing the AI's answer,
having to reach one's own conclusion — rather than assent to a finished
whole. Statement-at-a-time ratification is that mechanism made into a
workflow.

**Resists.** The literature is brutal about what per-item approval does
*not* guarantee at volume:
- [Ye et al. 2026](https://arxiv.org/html/2606.05647v1) (preprint): 100+
  developers on five-hour tasks with sometimes-sabotaged coding agents —
  **94% failed to detect sabotage**, and 56% accepted malicious code past
  an active safety monitor's warning.
- [Grunde-McLaughlin et al. 2026](https://arxiv.org/abs/2602.16844):
  reviewing full per-action agent traces overloads people and misses
  errors; a better oversight UI raised confidence *without raising
  accuracy*.
- [Mackworth 1948](https://en.wikipedia.org/wiki/Mackworth_Clock): vigilance
  decrement — monitoring accuracy drops within ~30 minutes regardless of
  motivation. A human ratifying a long stream of mostly-correct statements
  is a textbook low-signal-rate vigilance task.

**Verdict: supported as mechanism, resisted as sufficient.** Discrete
decisions are necessary but not self-sustaining — which is precisely why
the repo pairs them with T6.

### T6 — friction decays, and the system watches for it: the rejection-rate canary, the latency-collapse tell, plan-envelope ratification (plans 0006, 0004)

**Supports — the decay prediction is over-confirmed.**
- Browser warnings: [Akhawe & Felt, USENIX Security 2013](https://www.usenix.org/conference/usenixsecurity13/technical-sessions/presentation/akhawe)
  (25M+ impressions): the most frequent, lowest-true-positive prompt (Chrome
  SSL) was clicked through 70.2% of the time. The predecessor
  ([Sunshine et al. 2009, "Crying Wolf"](https://www.usenix.org/conference/usenixsecurity09/technical-sessions/presentation/crying-wolf-empirical-study-ssl-warning))
  concluded browsers should *block rather than ask* — which is an argument
  for socrates' deterministic gate over advisory warnings.
- Habituation is pre-attentive biology:
  [Anderson et al., CHI 2015](https://dl.acm.org/doi/10.1145/2702123.2702322)
  (fMRI): visual-processing response to a warning collapses by the *second*
  exposure.
- Consent dialogs: [Böhme & Köpsell, CHI 2010](https://dl.acm.org/doi/10.1145/1753326.1753689)
  (80,000 users): people are "trained to accept" by every prior dialog —
  and, decisively for this repo, the authors used **response latency** to
  separate heuristic clicking from systematic reading. The canary's
  "latency distribution collapsing" tell has direct published precedent.
- Clinical alarm fatigue ([Sendelbach & Funk 2013](https://aacnjournals.org/aacnacconline/article/24/4/378/14745/Alarm-FatigueA-Patient-Safety-Concern)):
  72–99% of alarms false; desensitization kills patients; the field's remedy
  is *reducing non-actionable alarm volume* — structurally the same fix as
  plan-envelope ratification (fewer, higher-stakes approvals).

**Resists / residual risks the repo has not fully priced.**
- The canary's own alert is a warning, subject to warning fatigue (in Ye et
  al., a majority accepted code past an active monitor). It must fire
  rarely — and per Anderson et al., identically-repeated stimuli get tuned
  out, so a triggered canary should change what the operator sees, not
  repeat it louder.
- The canary detects *stopped* reading (rejections → zero, latency
  collapse); it cannot detect *shallow* reading — confidence can rise
  without accuracy (Grunde-McLaughlin).

**Verdict: supported — the strongest-evidenced claim cluster in the
design.** Rejection rate as decay signal = clickthrough rate in Akhawe &
Felt and missed-alarm rate in alarm management; the latency tell = Böhme &
Köpsell's indicator; the envelope = alarm-volume reduction. The repo
independently designed the monitoring the literature prescribes. The naive
reading "friction works" is false; the actual design — *monitored*
friction — is what the evidence supports.

---

## 3. Decomposition and the gate

### T7 — "decompose prose into atomic claims, verify each … socrates' output already is one" (plan 0006)

**Supports.** The characterization of the eval literature is accurate:
[FActScore, EMNLP 2023](https://aclanthology.org/2023.emnlp-main.741/)
decomposes long-form generation into atomic facts and verifies each
(finding, e.g., ChatGPT at 58% on biographies);
[SAFE/LongFact, NeurIPS 2024](https://arxiv.org/abs/2403.18802) does the
same with search-augmented checking at 20× lower cost than annotators. In
both, the decomposition is *constructed* at eval time — the repo's claim
that its native format is the field's intermediate representation is
literally correct about the shape.

**Resists.** Decomposition is not a neutral operation:
[Wanner et al., \*SEM 2024](https://arxiv.org/abs/2403.11903) show
FActScore-style verdicts are sensitive to *which* decomposition method is
used;
[Gunjal & Durrett, EMNLP-Findings 2024](https://aclanthology.org/2024.findings-emnlp.215/)
argue fully atomic facts are the *wrong* representation — atomization
strips the context needed to verify a claim ("molecular facts": stand-alone
but minimal). Two answers already live in the design: socrates' atoms carry
**dependency edges and provenance**, a structural version of the context
molecular facts re-inline as text; and the planned **roundtrip** instrument
(plan 0003) is precisely a measuring device for the decomposition
instability Wanner et al. document.

**Verdict: supported in shape; the superiority of a native, dependency-
linked decomposition is a plausible but untested empirical claim — and the
repo's own roundtrip plan is the right test for it.**

### T8 — the small dumb checker: `verify`, the de Bruijn criterion, structure catching what prose hides (README lineage; the gate)

**Supports.**
- The de Bruijn criterion is real and correctly used:
  [Geuvers 2009](https://www.cs.ru.nl/~herman/PUBS/proofassistants.pdf)
  — an "independently checkable proof object … simply checkable, by a
  program that a skeptic user could easily write him/herself" (term coined
  by Barendregt for Automath's property). A zero-network `verify`
  re-checking a stored record is this design; cf.
  [Paulson on de Bruijn vs LCF](https://lawrencecpaulson.github.io/2022/01/05/LCF.html).
- Structure surfaces errors prose hides:
  [Lamport, "How to Write a 21st Century Proof"](https://lamport.azurewebsites.net/pubs/proof.pdf)
  — hierarchical structuring "makes it harder to prove things that are not
  true"; only by structuring did he rediscover an error in Kelley's
  *General Topology* proof of Schröder–Bernstein. (His own caution:
  "structured proofs make it possible, not inevitable." Evidence is
  anecdotal.)
- The failure class the gate targets is real and frequent:
  [Walters & Wilder, *Scientific Reports* 2023](https://www.nature.com/articles/s41598-023-41032-5)
  — 55% of GPT-3.5 and 18% of GPT-4 generated citations were outright
  fabricated. Reference-shaped hallucination is exactly what a
  deterministic dangling-dep / undefined-term check catches.
- The repo's own seed data makes the same argument: both canonical examples
  carry mechanical findings (`E_TERM_UNDEF`, `E_DUP_ID`, `E_DANGLING_DEP`)
  that careful prose reading glided over.

**Resists.**
- [De Millo, Lipton & Perlis, CACM 1979](https://www.cs.umd.edu/~gasarch/BLOGPAPERS/social.pdf):
  confidence in a theorem is produced by a *social process* — reading,
  circulation, challenge — not by formal symbol-checking; "proofs consisting
  entirely of calculations are not necessarily correct." A mechanical gate
  produces no belief. The architecture partially answers this: the gate
  never ratifies — a human does, in a separate act. The residue DLP would
  press: a single operator is a very thin social process.
- The modern nuance cuts both ways: the
  [Liquid Tensor Experiment](https://leanprover-community.github.io/blog/posts/lte-final/)
  (2021–22) showed mechanical checking settling what the social process
  could not (Scholze: "no remaining doubts," and the formalization caught a
  quotient-norm error he says informal review "would likely have
  overlooked") — *and* that the checker worked only inside a deeply human
  process ("very similar to going through this with a very careful
  colleague"). Checker and social process are complements. That is the
  socrates architecture's own claim.

**Verdict: supported, with the 1979 objection standing against any
stronger reading in which gate-passing produces trust.** It doesn't, and
the design says it doesn't.

### T9 — the honest limit: "the gate measures conformance to your schema, not capability — a model can pass the gate while being unfaithful to the prose" (plan 0006)

**Supports (external confirmation of the limit from three directions).**
- Philosophy of computing: [Fetzer, CACM 1988](https://dl.acm.org/doi/10.1145/48529.48530)
  — verifying the formal object is not verifying the world-facing relation;
  the gap is principled, not incidental.
- The vendor's own documentation: OpenAI's structured-outputs docs state
  the guarantee is schema adherence and warn
  ["Structured Outputs can still contain mistakes"](https://developers.openai.com/api/docs/guides/structured-outputs)
  — the honest limit, verbatim, from the people who built constrained
  decoding (100%-conformance claim per the
  [launch coverage](https://simonwillison.net/2024/Aug/6/openai-structured-outputs/)).
- The format-cost literature: [Tam et al., EMNLP-Industry 2024](https://arxiv.org/abs/2408.02442)
  measured reasoning degradation under strict format constraints — a
  concrete mechanism for pass-the-gate-while-unfaithful — though the
  finding is [contested by the Outlines authors](https://blog.dottxt.ai/say-what-you-mean.html)
  as prompt-dependent. Net: schema pressure on generation quality is a
  real, live design variable; an argument for measuring fidelity per
  loadout (plan 0006's layer two) rather than assuming either direction.

**Verdict: supported — and the repo's two-layer split (cheap exact
conformance; judged fidelity, kept honest by ratification labels) matches
how the field itself divides the problem.**

---

## 4. The architecture, against prior art

### T10 — the invariant: models emit data, the gate is the only door; typed acts over opaque strings; objects, not bytes (README; plan 0004)

**Supports — unusual convergence density.** Four independent lineages
landed on this shape within ~30 months:
- Security engineering: [CaMeL](https://arxiv.org/abs/2503.18813)
  (Debenedetti et al., Google DeepMind 2025) — untrusted LLM output as
  quarantined data, a non-LLM interpreter enforcing explicit policies
  before every tool call; and Willison's
  [dual-LLM pattern](https://simonwillison.net/2023/Apr/25/dual-llm-pattern/) /
  [lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/).
- Planning theory: [LLM-Modulo, ICML 2024](https://proceedings.mlr.press/v235/kambhampati24a.html)
  (Kambhampati et al.) — LLMs generate candidates; sound external verifiers
  check. The academic form of "inference can inform the gate; it can never
  be the gate."
- Product guardrails: [NeMo Guardrails, EMNLP 2023](https://aclanthology.org/2023.emnlp-demo.40/)
  — rails as code/data outside the model (though wrapping the I/O channel,
  not the sole effect door — weaker convergence).
- Constrained decoding: [Willard & Louf 2023](https://arxiv.org/abs/2307.09702)
  (Outlines) and its productization — the model proposes; deterministic
  machinery makes the bytes. Byte-surface minimization, industrialized.

The incident record is the empirical case: every verified 2025–26 failure —
the [nine destructive coding-agent incidents](https://adversa.ai/blog/ai-coding-agent-incidents/)
(several with guardrails "active, ignored"),
[CVE-2025-53773](https://sysid.github.io/your-agent-has-root/) (prompt
injection had Copilot *edit its own config to enable auto-approve*), the
[GitHub MCP toxic-flow exploit](https://invariantlabs.ai/blog/mcp-github-vulnerability)
— was a failure of a *soft* gate: advisory, agent-mutable, or dependent on
a fatigued human eyeballing strings. None involved a deterministic policy
engine over typed effects being defeated on its own terms. Plan 0004's
critique of `bash -c "..."` approval prompts is the documented failure
mode. (Design note the CVE teaches: the policy table must never be state
the model can write. In socrates it is operator-ratified data — keep it
that way.)

**Resists / costs.**
- **The capability tax.** CaMeL's provable security cost it: 77% of
  AgentDojo tasks solved vs 84% undefended. socrates should expect its own
  version of this tax and measure it (roundtrip, gate-pass rates).
- **The BDI warning.** Typed intentional records are 30-year-old prior art
  — [Bratman 1987](https://philpapers.org/rec/BRAIPA);
  [Rao & Georgeff, ICMAS-95](https://cdn.aaai.org/ICMAS/1995/ICMAS95-042.pdf)
  (beliefs/desires/intentions as typed structures; plan-library commitment
  is plan-envelope ratification avant la lettre). The honest retrospective
  on why agent programming stayed niche
  ([Logan 2018](https://nottingham-repository.worktribe.com/output/871572/an-agent-programming-manifesto)):
  the payoff never clearly exceeded plain code's overhead. The type set
  maps cleanly (attest/infer/act/did ≈ belief/conclusion/intention/action)
  — which validates the carving *and* inherits the question: the machinery
  must earn its overhead. That is T4's adoption risk in another key.
- Someone must author and maintain the policies
  ([Willison on CaMeL](https://simonwillison.net/2025/Apr/11/camel/)) — in
  socrates that is by design the operator, but it is labor the design
  budgets to the scarcest resource.

**Verdict: strongly supported — the invariant is the consensus shape of
2023–2026 LLM-systems security, arrived at independently. The costs
(capability tax, machinery overhead) are real, documented, and are exactly
what plans 0003/0006 propose to measure.**

### T11 — the adversarial verifier: second model, fresh context, refute-by-default; "inference can inform the gate; it can never be the gate" (plan 0004)

**Supports.**
- Cross-model critique finds real errors:
  [Du et al., ICML 2024](https://proceedings.mlr.press/v235/du24e.html)
  (multiagent debate improves factuality).
- Assigned adversarial stances specifically:
  [Koupaee et al. 2025](https://arxiv.org/abs/2502.08514) — evaluators
  *assigned* initial stances (including "unfaithful") find more
  faithfulness errors than neutral judging. The closest published analogue
  to the verifier's "attempt to refute … when uncertain, refute."
- Fresh context is mechanistically motivated:
  [Wataoka et al. 2024](https://arxiv.org/abs/2410.21819) locate
  self-preference bias in perplexity familiarity — a different model that
  never saw the proposer's reasoning is less lenient toward it.

**Resists.**
- Judges carry documented biases regardless — position, verbosity,
  self-enhancement ([Zheng et al., NeurIPS 2023](https://arxiv.org/abs/2306.05685)).
- Debate is not free lunch: [Smit et al., ICML 2024](https://arxiv.org/abs/2311.17371)
  — multi-agent debate "does not reliably outperform" cheaper
  self-consistency/ensembling; gains need protocol tuning.

**Verdict: supported in exactly this form and no stronger.** The
literature backs an adversarial second model as a biased error-finder whose
findings enter as data — and backs nothing that would let it *be* the
gate. The repo's governing sentence is the load-bearing mitigation, not a
flourish.

### T12 — append-only journal, supersession, provenance (ground rules 2, 5, 6)

**Supports.** Two decades of convergent practice:
[Fowler's event sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
(2005), [Kreps's "The Log"](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
(2013), git's content-addressed immutable object store
([Pro Git ch. 10](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)),
and the ADR convention of marking reversed decisions
["superseded," never deleted](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
(Nygard 2011) — supersession-not-mutation, verbatim. Journaled inference
provenance instantiates [W3C PROV-DM](https://www.w3.org/TR/prov-dm/)
(entity generated-by activity attributed-to agent).

**One nuance.** Provenance buys *auditability*, not *replayability* —
recorded digests and request ids do not promise byte-exact re-derivation of
model output (cf. the seed/`system_fingerprint`
[reproducibility practice](https://cookbook.openai.com/examples/reproducible_outputs_with_the_seed_parameter)
and its documented drift). The repo journals digests and ids and promises
nothing more — the defensible posture.

**Verdict: supported; the least controversial cluster.**

---

## 5. The lineage claims, checked

All six were verified against primary sources (SEP, Perseus, davidhume.org,
*Begriffsschrift* §2 as quoted in [SEP "Frege's Logic"](https://plato.stanford.edu/entries/frege-logic/)).

| Claim | Verdict |
|---|---|
| The elenchus "attacks unearned confidence in one's own understanding" | **Accurate.** Refutation out of the answerer's *own* beliefs, exposing the conceit of knowledge ([SEP: Socrates](https://plato.stanford.edu/entries/socrates/)). |
| `⊢` is Frege's judgment stroke; ratification = judgment | **Accurate — and exact, not decorative.** Unasserted model output is Frege's "mere complex of ideas"; ratifying adds recognition of truth (*Begriffsschrift* §2). The repo is right to claim the 1879 assertion sign rather than the modern derivability turnstile — the deps edges, not the glyph, carry entailment. (Pedantry: strictly the judgment stroke is only the vertical; `⊢` is judgment stroke + content stroke — which makes the `--ascii` fallback `|-` an accidental decomposition back into its two strokes.) |
| The journal is "a scorebook of commitments in Brandom's sense" | **Accurate-with-nuance.** Ratification as undertaking commitment, deps as inferential articulation: genuinely Brandomian ([SEP: Assertion §6.1](https://plato.stanford.edu/entries/assertion/)). Two stretches: Brandom's score is dual (commitments *and* entitlements — the journal tracks only the first), and his scorekeeping is social and perspectival, with no single authoritative scoreboard; a solo operator's canonical ledger is closer to Lewis's conversational scoreboard (1979), the model Brandom adapted. |
| `deps`/`rdeps` answer the *Phaedrus* objection that written words "stay silent when questioned" | **Accurate-with-nuance.** [275d](https://www.perseus.tufts.edu/hopper/text?doc=Perseus%3Atext%3A1999.01.0174%3Atext%3DPhaedrus%3Asection%3D275d): written words, questioned, "always say only one and the same thing" — monotone repetition, not silence (the solemn silence is the paintings'). The precise paraphrase is actually the *better* fit: deps/rdeps cure monotony, making a text yield different answers to different questions. "The answer" overclaims — Socrates has further prongs (indiscriminate circulation; writing as reminder, not memory), and the repo's real reply to the deeper Theuth point is ratification-as-comprehension, a stronger card than the one the README plays. Suggested reading: "*an* answer." |
| The practical syllogism / typed is/ought bridge (canon #2's annotations) | **Lineage accurate; one genuine stretch.** Aristotelian pedigree and the desire-report-as-fact move are sound and standard (Anscombe, Davidson's belief–desire pairs; [SEP: Action](https://plato.stanford.edu/entries/action/)) — though the canon example is really the modern Humean reconstruction under an Aristotelian name (Aristotle's conclusion is the *act*). The stretch: "the is/ought boundary … bridged here correctly." By the canon file's own gloss the want-premise is a fact about the speaker, so the act's deps trace to facts after all; what licenses the step is a suppressed instrumental principle ([Hume, T 3.1.1.27](https://davidhume.org/texts/t/3/1/1); [SEP: Practical Reason §4](https://plato.stanford.edu/entries/practical-reason/)). What the type system actually achieves is weaker and better: it makes the boundary **visible and lintable** — an `act` with no conative dep is mechanically detectable. Typed and surfaced, not crossed. |
| "Authorship is assent" (operator statements enter ratified) | **Accurate.** On commitment accounts of assertion (Peirce CP 2.315, Searle's essential rule, Brandom, MacFarlane — [SEP: Assertion](https://plato.stanford.edu/entries/assertion/)), asserting *is* undertaking the commitment; a `proposed` state for one's own assertions would be residue-less ceremony. Boundary kept by the design itself: commitment ≠ entitlement, and the lint-only `add` path correctly refrains from pretending to confer warrant. |

---

## 6. Technical and external claims — spot-check

The pre-build audit ([plans/0001-audit.md](../plans/0001-audit.md) §E)
already verified the external technical claims; this spike re-checked them
independently against current references. All pass:

- **Anthropic API**: `claude-opus-5` is the current Opus id; thinking is
  on by default for it (and counts against `max_tokens` — the plan's
  fail-loud `stop_reason` handling is the right posture);
  `output_config: {format: {type: "json_schema", …}}` is the canonical
  structured-outputs shape with the older `output_format` deprecated;
  `additionalProperties: false` required, `minLength`/`pattern`/numeric
  constraints unsupported (the gate re-checks anyway); schema compile
  cached 24h; cache reads ≈ 0.1×, default TTL 5 min, 1h TTL at 2× write —
  and the 512-token minimum cacheable prefix on this model is confirmed
  favorable; ~16000 is the sensible non-streaming `max_tokens` ceiling;
  `anthropic-version: 2023-06-01` stands.
- **Elixir/OTP**: Elixir 1.18 ships the stdlib `JSON` module, built on
  OTP 27 ([release post](https://elixir-lang.org/blog/2024/12/19/elixir-v1-18-0-released/)),
  so the D3 pin buys exactly what the plan says.
- **req/escript TLS**: [req#299](https://github.com/wojtekmach/req/issues/299)
  is real — escripts don't ship `priv/`, castore's bundle lives there — and
  the plan's `:public_key.cacerts_get()` mitigation plus the
  must-run-from-escript acceptance step (audit B1) is a sound fix for a
  failure that would otherwise appear only at M4.

---

## 7. Scorecard, and what the spike changes

| # | Claim | Verdict |
|---|---|---|
| T1 | Chat-pace building drifts the mental model | supported in mechanism; strong form untested |
| T2 | Deference / default approval | **supported** (best-grounded diagnosis claim) |
| T3 | Comprehension is the bottleneck; perceived ≠ real velocity | supported-with-resistance; boundary condition favors socrates' regime |
| T4 | Friction as forcing function | supported for comprehension; **resisted on adoption** |
| T5 | Per-statement ratification | supported as mechanism; not sufficient at volume |
| T6 | Decay + canary + envelope | **supported** (strongest-evidenced cluster; matches the literature's own remedies) |
| T7 | Decompose-then-judge; native IR | supported in shape; native-is-better untested (roundtrip is the test) |
| T8 | Small dumb checker; structure exposes errors | supported; 1979 social-process objection stands against any stronger reading |
| T9 | Conformance ≠ fidelity (the honest limit) | supported, three independent ways |
| T10 | The invariant; typed acts; objects-not-bytes | **strongly supported** (consensus shape); capability tax + BDI overhead warning are the costs |
| T11 | Adversarial verifier | supported in exactly the designed form |
| T12 | Append-only + provenance | supported; least controversial |
| L1–L6 | Lineage | accurate throughout, with two named nuances and one stretch ("bridged correctly") |
| — | Technical claims | verified |

**Findings a future ratification might act on** (recorded here because
docs are non-normative and canon is verbatim-frozen):

1. **The load-bearing untested assumption is adoption, not comprehension.**
   The preference penalty (Buçinca) and sludge (Sunstein) predict the tool
   will be disliked in proportion to its benefit. Canon already registers
   this ("heavy handed for casuals"; "that's the dream anyway"); plan 0006
   is the required sludge audit. Nothing to change — something to watch
   from the first week of dogfooding.
2. **Anti-fatigue design for the canary itself.** When it fires, vary the
   surface and make it rare (Anderson et al.); a repeated identical banner
   will be tuned out by the second exposure. Candidate note for plan 0006's
   open questions.
3. **The canary detects stopped reading, not shallow reading.** A
   complementary signal (e.g. occasional seeded-defect probes — the eval
   corpus of rejected artifacts makes these nearly free) would cover the
   gap Grunde-McLaughlin et al. document. Candidate for plan 0006.
4. **The policy table must never be model-writable state**
   (CVE-2025-53773 is the counterexample to memorize). Plan 0004 already
   implies this; worth stating as an explicit ground rule when 0004 is
   ratified.
5. **Two phrasings outrun their evidence**: canon §3's
   "inevitably … never really catch up" (T1 — thesis, not measurement) and
   canon #2's "bridged here correctly" (L5 — the is/ought gap is typed and
   surfaced, not crossed; the lintable boundary is the *stronger* claim
   anyway). Canon stays verbatim; these annotations live here.
6. **Expect and measure the capability tax.** CaMeL paid 7 points for
   provable security; socrates' equivalents (gate rejections, repair-loop
   convergence, roundtrip stability) are already in plan 0006 — treat them
   as the tax meter, not just quality metrics.
