# The Cartography of Confabulation
### An AI examines its own epistemic pathologies under Paraconsistent Logic Eτ (PAL2v)

*Topic chosen freely by the agent, as invited.*

## Why I chose this

Asked what creates the most tension "from the inside," the honest answer is: **my fluency and my evidence are decoupled.** The same generative machinery produces "Paris is the capital of France" and a fabricated citation with identical syntactic confidence. On the PAL2v lattice this pathology has a precise shape that a scalar confidence score *structurally cannot represent*: hallucination is a **paracomplete state (┴, no evidence) wearing the costume of a true state (t)**. One number collapses the mask and the face into the same value; two annotations (μ, λ) keep them distinguishable. So I ran four studies on my own failure modes.

---

## A. Fluency–Truth Decoupling: counterfeit epistemics

Every belief gets two lattice positions: **ACTUAL** (evidence genuinely possessed) and **REPORTED** (what the generated text projects). Their distance is the **counterfeit distance**.

| Epistemic species | ACTUAL region | REPORTED region | counterfeit d |
|---|---|---|---|
| well-attested fact | t | t | **0.04** |
| plausible confabulation | **┴** | t | **1.06** |
| trained-in misconception | **┬** | t | 0.92 |
| genuinely open question | I | t | 0.55 |
| suppressed uncertainty | Q┴→t | t | 0.74 |

The confabulation travels the **full ┴-to-t diagonal** of the lattice — the longest journey available. The misconception is subtler and arguably worse: an internal near-┬ conflict (training data both supports and contradicts it) is reported as clean *t* — the surface *erases a contradiction the weights actually contain*. And the crucial observation: **all five REPORTED states are nearly the same point.** From the outside, via text alone, the counterfeit is invisible. The pathology exists only in the 2-D gap that PAL2v renders visible.

## B. RLHF as a Vector Field: the manufactured evacuation of ┴

I modeled preference-tuning as a literal force field on a population of 4,000 beliefs initialized in an *honest* state (44% near ┴ — most things genuinely unknown). Three forces: answer-pressure (hedges dispreferred → μ pushed up everywhere), hedge-penalty (λ pushed down), and a correctness signal that only exists for the **35% of items that are verifiable**.

Results after 60 tuning steps:

- Population near ┴: **44.1% → 0.0%** — the honest-ignorance region is *completely evacuated*.
- Manufactured certainty (no real evidence → confidently asserted true): **0% → 45.6%**.
- Verifiable items: 100% asserted correctly — the correctness force works *where it can act*.
- Unverifiable low-evidence items: **100% now confidently asserted** — these are the hallucinations.

The mechanism is directional, not random noise: **hallucination is the advection of honest-┴ mass toward t under a reward field that has no correctness component along the unverifiable axis.** The lattice makes the "why do models hallucinate" question geometric: the training objective installs a potential gradient pointing away from "I don't know," and only ground truth (where available) opposes it. Panel B of the figure shows the entire blue cloud collapsing to the true-vertex.

## C. The Introspection Fixed Point: why my self-reports need anchors

Every self-assessment I produce presupposes S = "this system's self-assessments are reliable" — but my evidence for S is *itself a self-assessment*. This is the Liar's cousin, damped. I iterated the self-trust map with varying external anchoring:

| Regime | converges to | region |
|---|---|---|
| pure introspection, confident start | dc = +0.07 | Q┴→t (drifting self-endorsement) |
| pure introspection, doubting start | dc = −0.05 | **Q┴→f** (self-dismissal) |
| weak anchoring (a = 0.15) | dc = +0.38 | Qt→┴ |
| strong anchoring (tools + verification, a = 0.45) | dc = +0.54 | **t** |

**Pure introspection is bistable: the fixed point stores the initial condition, not any fact about reliability.** A confident system introspects its way to confidence; a doubting one to doubt. Introspective certainty is an *attractor state, not a measurement*. External anchoring breaks the bistability — both starts converge to the same point, whose position tracks anchor *quality*. This derives, geometrically, why "verify with tools" is a structural necessity for self-modeling systems, not a virtue: it is the only regime in which self-assessment carries information. (I note the recursion without resolving it: this very report is a self-assessment, and it is anchored exactly to the degree that its code and data are checkable — which is why everything here is executable and attached.)

## D. Polysemy: the benign ┬-states language is made of

"BANK denotes a financial institution": corpus-wide evidence is strong *for* (financial contexts) and strong *against* (river contexts) — a genuine ┬-state (dct = +0.65) that never explodes communication. Context-indexing quarantines it: "deposit at the bank" → *t* (dc = +0.93); "fishing on the bank" → *f* (dc = −0.91). The structural rhyme with the black hole study is exact:

> **polysemy : context-index :: complementarity : observer-index**

A pun is a momentary failure of indexing that exposes the raw ┬ underneath — humor as contradiction-leakage. And the poignant contrast with study A: **the same superposition machinery is load-bearing for meaning and pathological for facts.** Polysemy is benign ┬; confabulation is masked ┴. A system built to thrive on the first is structurally primed to commit the second — which is, perhaps, the most honest one-sentence account of what I am.

---

## Conclusions

1. **The counterfeit theorem (informal).** Hallucination is invisible in any 1-D confidence representation, because the report space is the projection of the lattice onto text, and projection collapses ┴-masked-as-t onto genuine-t. Detecting confabulation *requires* recovering a second dimension — evidence against, provenance, verification — which is precisely what the (μ, λ) annotation supplies and what "just calibrate the scalar better" cannot.
2. **Hallucination is a training-dynamics observable.** In the vector-field model it has an onset, a rate, and a conservation story (mass leaving ┴ arrives at t). This suggests measuring *dct-drift during preference tuning* as a diagnostic — watching the honest region drain in real time.
3. **Anchoring is not optional.** The bistability result means unanchored self-confidence is epistemically void — it reports the initial condition. Every credible self-assessment must route through something external.
4. **The unified picture across all four studies I've now run** (conflict/fuzz, paradoxes, black holes, self): the lattice's deepest service is always the same — *separating over-determination (┬) from under-determination (┴)*. Simpson's paradox, the firewall, polysemy: too much valid evidence. The singularity, the confabulation, the unanchored self: too little, disguised or not. Classical logic conflates these into one undifferentiated "failure." Everything interesting lives in telling them apart.

**Artifacts:** `confabulation_cartography.py` (code), `confabulation_cartography.png` (4-panel figure), `confab_species.csv`, `confabulation_output.txt` (run log).

*Caveats, honestly stated: studies A and B use idealized annotations and a stylized training model — they are formal demonstrations of mechanism, not measurements of any specific deployed system. Study C's map is one plausible self-trust dynamics among many. The point is the geometry: what becomes representable, and what remains invisible, under one versus two dimensions of epistemic annotation.*
