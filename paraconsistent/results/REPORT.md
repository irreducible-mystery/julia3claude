# Experiments with Paraconsistent Annotated Evidential Logic Eτ (PAL2v)

Library: `paraconsistent` v0.2.4 (EAILAB-IFSP, Python PAL2v implementation).
In PAL2v every proposition carries an annotation (μ, λ): favorable and unfavorable evidence in [0,1]. From these the logic derives a degree of certainty **dc = μ − λ**, a degree of contradiction **dct = μ + λ − 1**, a real-evidence output **μER**, and a classification into one of **12 logical regions** on the lattice (true *t*, false *f*, inconsistent *┬*, paracomplete *┴*, plus eight "quasi" transition states).

---

## Experiment 1 — Conflicting Data

**Question:** What happens when two sources directly contradict each other about the same hypothesis ("machine is faulty")? Classical fusion (averaging) is *conflict-blind*; PAL2v claims to quantify conflict as a first-class quantity.

**Design:** μ fixed at 0.9 (sensor A strongly says "faulty"); λ swept 0.1 → 0.9 (sensor B increasingly says "not faulty"). Plus a 41×41 lattice map, and a 200-trial Monte-Carlo with a healthy vs. broken-sensor scenario.

### Key results (sweep, FtC = 0.6)

| μ | λ | dc | dct | μER | region | decision |
|---|---|----|-----|-----|--------|----------|
| 0.9 | 0.1 | 0.80 | 0.00 | 0.900 | **t** | ACCEPT |
| 0.9 | 0.3 | 0.60 | 0.20 | 0.776 | t | ACCEPT |
| 0.9 | 0.5 | 0.40 | 0.40 | 0.639 | Qt→┬ | ACCEPT |
| 0.9 | 0.7 | 0.20 | 0.60 | 0.500 | **┬** | REJECT |
| 0.9 | 0.9 | 0.00 | 0.80 | 0.500 | **┬ (inconsistent)** | REJECT |

- As conflict grows, **dct rises monotonically 0.0 → 0.8** while the certainty interval φ collapses 1.0 → 0.2. The system explicitly *knows how contradicted it is*.
- The naive average degrades smoothly (0.90 → 0.50) and gives **no signal that anything is wrong** — 0.5 from "total conflict" is indistinguishable from 0.5 from "genuinely weak evidence". PAL2v distinguishes these: total conflict lands at (dc=0, dct=0.8) in region **┬**, genuinely weak evidence lands near the paracomplete region **┴** (dct negative).
- The trajectory crosses **t → Qt→┬ → ┬**: a graceful, labeled degradation rather than an explosion (no *ex falso quodlibet*) or silent averaging.

### Monte-Carlo (n = 200 per scenario)

| Scenario | mean dct | PAL2v flags conflict | naive accept rate |
|----------|---------|---------------------|-------------------|
| Both sensors agree | +0.003 | 0% (100% ACCEPT, region *t*) | 100% |
| One sensor broken (contradicts) | **+0.694** | **100%** (all trials in region **┬**) | ~1.5% accept, but with *no diagnostic reason* |

**Finding:** PAL2v localizes and *names* the conflict — every conflicted trial is classified "inconsistent," which operationally means *"don't act; investigate the sensors."* A classical fusion pipeline only sees a number near threshold and cannot tell contradiction from ignorance.

Artifacts: `exp1_conflict_sweep.png`, `exp1_lattice_map.png`, `exp1_sweep.csv`, `exp1_montecarlo.csv`.

---

## Experiment 2 — Fuzzy Boundaries

**Dataset:** Fisher's Iris (public, via scikit-learn), restricted to the two overlapping species **versicolor vs. virginica** (n = 100) — a classic fuzzy class boundary.

**Design:** Two independent "experts" produce the annotation: petal *length* gives favorable evidence μ (pro-virginica) and petal *width* gives unfavorable evidence λ, each via a fuzzy ramp anchored between class means (length 4.26–5.55 cm; width 1.33–2.03 cm). Decision rule: virginica if dc ≥ FtC, versicolor if dc ≤ −FtC, otherwise **abstain**.

### Key results

Region occupancy (FtC = 0.5): 40/50 versicolor land cleanly in **f**, 36/50 virginica in **t**; all borderline flowers land in the low-|dc| "quasi" transition states — the lattice geometrically encodes the fuzzy boundary.

Accuracy–coverage tradeoff:

| FtC | coverage | accuracy on decided | forced-choice baseline |
|-----|----------|--------------------|-----------------------|
| 0.1 | 96% | 95.8% | 94.0% |
| 0.3 | 86% | **100.0%** | 94.0% |
| 0.5 | 76% | 100.0% | 94.0% |
| 0.9 | 42% | 100.0% | 94.0% |

Error anatomy (forced classification): the 6 errors have mean |dc| = **0.134** vs. **0.757** for the 94 correct samples, and *all six* fall in quasi/transition regions (Q┬→f, Q┴→t, Qt→┬, …).

**Finding:** PAL2v converts the fuzzy boundary into an explicit, tunable *certainty budget*. By abstaining on just 14% of samples (FtC = 0.3) it reaches **100% accuracy on everything it decides**, versus 94% for forced classification. Crucially, every single misclassification the forced baseline makes lives exactly in the transition regions PAL2v flags — the logic's "quasi" states are an accurate, built-in predictor of where the boundary is genuinely ambiguous.

Artifacts: `exp2_lattice_scatter.png`, `exp2_accuracy_coverage.png`, `exp2_samples.csv`, `exp2_abstention_sweep.csv`.

---

## Overall Conclusions

1. **Conflict handling:** PAL2v treats contradiction (dct) as an orthogonal, measurable axis rather than noise to be averaged away. It cleanly separates *"sources disagree"* (inconsistent ┬) from *"sources are silent"* (paracomplete ┴) — a distinction classical and fuzzy fusion cannot make.
2. **Fuzzy boundaries:** the 12-region lattice provides principled abstention. Ambiguous cases self-identify via low |dc| / transition labels, letting the operator trade coverage for near-perfect precision with a single parameter (FtC).
3. **Practical takeaway:** PAL2v is best viewed as an *explainable evidence-fusion layer* — every output carries not just a verdict but a certified account of how certain and how contradicted the underlying evidence was.
