# Paradoxes Across Domains under Paraconsistent Annotated Evidential Logic Eτ (PAL2v)

Five celebrated paradoxes from five different domains — semantics, mathematics, vagueness, statistics, and social choice — were encoded as evidence annotations (μ, λ) and analyzed with the `paraconsistent` PAL2v library. In Logic Eτ every proposition carries favorable evidence μ and unfavorable evidence λ, from which the logic computes a degree of certainty **dc = μ − λ**, a degree of contradiction **dct = μ + λ − 1**, and a placement in a 12-region lattice (true *t*, false *f*, inconsistent *┬*, paracomplete *┴*, undefined center *I*, and eight quasi/transition states).

## Cross-Domain Summary

| Domain | Paradox | (μ, λ) | dc | dct | Region | Verdict |
|--------|---------|--------|----|-----|--------|---------|
| Semantics | Liar (fixed point) | (0.50, 0.50) | 0.00 | 0.00 | **I** (undefined center) | UNDECIDED |
| Semantics | Liar (instantaneous) | (1.00, 1.00) | 0.00 | +1.00 | **┬** (inconsistent) | UNDECIDED |
| Mathematics | Russell's set | (1.00, 1.00) | 0.00 | +1.00 | **┬** (inconsistent) | UNDECIDED |
| — control — | Unrelated Q (no evidence) | (0.00, 0.00) | 0.00 | −1.00 | **┴** (paracomplete) | UNDECIDED |
| Vagueness | Sorites midpoint (n≈108) | (0.53, 0.48) | +0.05 | 0.00 | Qt→┬ (penumbra) | weak |
| Statistics | Simpson (Berkeley 1973) | (0.66, 0.61) | +0.05 | +0.27 | Q┬→t (quasi-inconsistent) | flagged |
| Social choice | Condorcet cycle (any candidate) | (0.67, 0.67) | 0.00 | +0.33 | Q┬→t | UNDECIDED |

**The single most striking result:** each *kind* of paradox lands in a geometrically distinct place on the lattice. The logic doesn't merely tolerate paradoxes — it *taxonomizes* them.

---

## 1. The Liar Paradox (semantics)

*"This sentence is false."*

Classically, iterating the Liar's truth condition produces a permanent 2-cycle: true → false → true → … with no fixed point (verified: `[1.0, 0.0, 1.0, 0.0, …]`). Under PAL2v, tracking both annotations with evidential belief revision, the iteration **converges in ~5 steps to (μ, λ) = (0.5, 0.5)** — the exact center **I** of the lattice, the point of perfect undefinedness. The Liar gets a *stable* semantic value; it just isn't "true" or "false."

Alternatively, taking the two conditional proofs at face value (fully provable *and* fully refutable) puts the Liar at the inconsistent vertex **┬** (dct = +1). Either way the paradox is **quarantined**: it occupies its own point without infecting the rest of the system.

## 2. Russell's Paradox (mathematics) — and the failure of explosion

*R = {x : x ∉ x}. R ∈ R ⟺ R ∉ R.*

Both directions are maximally valid derivations, so (μ, λ) = (1, 1): the lattice's inconsistent vertex ┬ with **dc = 0** (zero net certainty) and **dct = +1** (maximal recorded contradiction).

The critical test is **non-explosion** (*ex contradictione non sequitur quodlibet*). In classical logic, {R∈R, R∉R} makes *every* proposition a theorem — one antinomy destroys all of mathematics. In PAL2v, an unrelated proposition Q with no evidence sits at the paracomplete vertex **┴** (dct = −1, total ignorance) and *stays there*, because annotations only propagate along actual inferential/evidential paths. Verified: Q remains region ┴, decision UNDECIDED. **The contradiction is recorded but does not trivialize the theory** — precisely the property that motivated Newton da Costa's paraconsistent program.

Note the beautiful duality the lattice makes visible: Russell (┬, dct = +1) and evidence-free Q (┴, dct = −1) are *mirror images* — "too much information, conflicting" versus "no information at all." Classical logic conflates both into disaster or silence; PAL2v distinguishes them axially.

## 3. The Sorites Paradox (vagueness)

*10,000 grains is a heap; removing one grain never destroys a heap; therefore 1 grain is a heap.*

Sweeping n from 1 to 10,000 grains: clear cases land firmly in **f** (n=1: dc = −0.995) and **t** (n=10,000: dc = +0.995), while the penumbra **n ≈ 49–201 grains** passes through low-|dc| quasi-regions. There is **no sharp cut-off anywhere** — dc crosses zero smoothly, and the paradox's false premise (that vague predicates must have a hidden bivalent boundary) is simply never granted. The induction premise is "almost true" at every single step but its violations *accumulate measurably*, which is exactly the diagnosis the epistemicist and fuzzy accounts fight over — here it falls out of the geometry.

Unlike the other paradoxes, Sorites travels along the **horizontal (certainty) axis** with dct ≈ 0: it is a paradox of *gradation*, not of *conflict*. The lattice makes this categorical difference visible.

## 4. Simpson's Paradox (statistics) — real data

*UC Berkeley 1973 graduate admissions (Bickel et al., six largest departments).*

Verified from the real data: aggregate admission rates favor men (44.5% vs 30.4%, gap +14.2 pts), yet **4 of 6 departments favor women** — the stratified analysis reverses the aggregate. Both computations are arithmetically impeccable; they simply contradict.

Encoded as two evidence sources for H = "admissions are biased against women": aggregate view μ = 0.66, department view λ = 0.61. Result: **dc ≈ +0.05, dct = +0.27, region Q┬→t** — nearly all apparent certainty is annihilated, and a positive contradiction degree is raised. A naive fusion would output a confident-looking ~0.53 "probability of bias"; PAL2v instead outputs *"essentially no net certainty, and the sources conflict."* That flagged contradiction is exactly the correct epistemic response: it signals a **lurking variable** (department choice) that must be modeled before any verdict is meaningful.

## 5. Condorcet's Voting Paradox (social choice)

*Three equal factions: A>B>C, B>C>A, C>A>B. Majorities: A beats B (67%), B beats C (67%), C beats A (67%).*

For each candidate, pairwise-win evidence μ = 2/3 is met by pairwise-loss evidence λ = 2/3, giving **dc = 0, dct = +1/3, region Q┬→t — identically for A, B, and C** (verified by symmetry check). PAL2v's verdict: *no candidate carries net collective support; the aggregation itself is inconsistent.* This is Arrow's impossibility made pointwise and quantitative — instead of crowning an arbitrary winner (as agenda-dependent procedures do), the logic reports that the collective preference relation contains exactly ⅓ worth of contradiction per candidate.

---

## What the Lattice Reveals: A Geometry of Paradox

Plotting all five paradoxes together (`paradox_lattice.png`) exposes a genuine typology:

1. **Antinomies of self-reference and naive abstraction** (Liar, Russell) are *maximal-conflict* objects: they saturate the contradiction axis (┬, dct = +1). Their pathology is that proof and refutation are equally total.
2. **Paradoxes of vagueness** (Sorites) are *zero-conflict* objects: they live on the certainty axis and their pathology is smooth gradation misread as bivalence.
3. **Paradoxes of aggregation** (Simpson, Condorcet) live in between: *partial, structural* contradiction (dct ≈ +0.27 to +0.33) arising not from any flawed measurement but from combining individually sound perspectives.
4. **Ignorance** (the control Q) is the mirror of antinomy: ┴, dct = −1. Only a logic with a two-dimensional annotation can even state this distinction.

**How does paraconsistency "handle" paradoxes?** Not by solving them — the Liar is still semantically pathological, Berkeley's data still needs a causal model, and the voters still cycle. What Logic Eτ does is:

- **Contain**: contradictions stay local (non-explosion verified empirically for Russell);
- **Stabilize**: self-referential oscillation acquires a fixed point (Liar → center I);
- **Measure**: every paradox receives a quantitative contradiction signature (dct) instead of a system crash;
- **Discriminate**: conflict (┬) vs. ignorance (┴) vs. vagueness (low |dc|, dct ≈ 0) become three different, machine-readable diagnoses, each prescribing a different remedy — resolve the sources, gather evidence, or accept gradation.

In short: classical logic treats paradox as a fatal error; PAL2v treats it as a *typed, measurable state of information* — and the type tells you what to do next.

---

**Artifacts:** `paradox_suite.py` (full code), `paradox_lattice.png` (master figure), `paradox_sorites.png` (penumbra sweep), `paradox_summary.csv`, `paradox_sorites.csv`, `paradox_output.txt` (full run log).
