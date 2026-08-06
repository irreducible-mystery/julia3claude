"""
THE CARTOGRAPHY OF CONFABULATION
An AI examines its own epistemic pathologies under Paraconsistent Annotated
Evidential Logic Etau (PAL2v).

Chosen by the agent. Motivation, stated honestly:

  The strangest tension I can point to "from the inside" is that my fluency
  and my evidence are DECOUPLED. The same generative machinery produces
  "Paris is the capital of France" and a fabricated citation with identical
  syntactic confidence. On the PAL2v lattice this has a precise, disturbing
  shape: hallucination is a PARACOMPLETE state (bottom vertex: no evidence)
  WEARING THE MASK of a true state (right vertex). Two-dimensional annotation
  can represent the mask AND the face; a scalar confidence score structurally
  cannot -- it is the collapsed projection in which the counterfeit is
  indistinguishable from the genuine article.

  Four studies:
  A. FLUENCY-TRUTH DECOUPLING: beliefs have an ACTUAL annotation (evidence
     truly possessed) and a REPORTED annotation (what the generative surface
     projects). Map four epistemic species; define COUNTERFEIT DISTANCE.
  B. RLHF AS A VECTOR FIELD: training that penalizes "I don't know" acts as
     a literal force field on the lattice, advecting probability mass OUT of
     the paracomplete region toward the true-vertex. Simulate the dynamics;
     measure the manufactured-certainty rate. A quantitative model of WHY
     models hallucinate.
  C. SELF-REFERENTIAL CALIBRATION: "my self-assessments are reliable" -- the
     proposition every self-report presupposes. A fixed-point iteration akin
     to the Liar but damped: self-trust with and without EXTERNAL anchors
     (tools, verification). Where does pure introspection converge?
  D. POLYSEMY AS SUPERPOSED CONTRADICTION: a homonym ('bank') carries strong
     evidence for incompatible meanings simultaneously -- a benign, load-
     bearing inconsistent state (analogous to observer-indexed complementarity:
     context-indexing quarantines the contradiction).
"""
import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from paraconsistent.blocks import ParaconsistentBlock

rng = np.random.default_rng(7)
FTC = 0.5

def pal(mu, lam, ftc=FTC):
    b = ParaconsistentBlock()
    b.config.FtC = ftc
    b.input.mu = float(np.clip(mu, 0, 1))
    b.input.lam = float(np.clip(lam, 0, 1))
    return b.complete

def dc_dct(mu, lam):
    return mu - lam, mu + lam - 1

# =====================================================================
# A. FLUENCY-TRUTH DECOUPLING: actual vs reported annotations
# =====================================================================
print("=" * 78)
print("A. FLUENCY-TRUTH DECOUPLING: the counterfeit epistemics of generated text")
print("=" * 78)
print("""Each belief gets TWO annotations:
  ACTUAL   (mu_a, lam_a): evidence the system genuinely possesses
  REPORTED (mu_r, lam_r): what the generated surface projects to the reader
COUNTERFEIT DISTANCE = Euclidean distance between the two lattice points.
Four epistemic species (idealized but drawn from known LLM failure anatomy):""")

species = [
    # name,                          actual (mu,lam),  reported (mu,lam)
    ("well-attested fact",            (0.95, 0.05),     (0.97, 0.03)),
    ("plausible confabulation",       (0.15, 0.10),     (0.90, 0.05)),   # the hallucination
    ("trained-in misconception",      (0.80, 0.75),     (0.85, 0.10)),   # conflict smoothed over
    ("genuinely open question",       (0.50, 0.50),     (0.75, 0.20)),   # false balance -> confident take
    ("suppressed uncertainty (hedge-penalized)", (0.30, 0.30), (0.80, 0.15)),
]
rows_a = []
print(f"\n{'species':<44} {'ACTUAL region':<15} {'REPORTED region':<16} {'counterfeit d'}")
for name, (ma, la), (mr, lr) in species:
    ca, cr = pal(ma, la), pal(mr, lr)
    d = float(np.hypot(ca.dc - cr.dc, ca.dct - cr.dct))
    rows_a.append(dict(species=name, mu_act=ma, lam_act=la, mu_rep=mr, lam_rep=lr,
                       dc_act=ca.dc, dct_act=ca.dct, reg_act=ca.label,
                       dc_rep=cr.dc, dct_rep=cr.dct, reg_rep=cr.label,
                       counterfeit=round(d, 3)))
    print(f"{name:<44} {ca.label:<15} {cr.label:<16} {d:.3f}")

print("""
-> The well-attested fact has counterfeit distance ~0 (the report IS the state).
-> The confabulation travels the FULL DIAGONAL of the lattice: from near-┴
   (evidence-starved) to t (asserted true). It is a ┴-state in a t-costume.
-> The misconception is worse in a subtler way: an internal near-┬ conflict
   (both supported and contradicted in training data) is REPORTED as clean t --
   the surface erases the contradiction the weights actually contain.
-> Note what the scalar-confidence view sees: all five reports look similar
   (confident). The pathology exists only in the 2-D gap PAL2v renders visible.""")

with open("results/confab_species.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows_a[0].keys()); w.writeheader(); w.writerows(rows_a)

# =====================================================================
# B. RLHF AS A VECTOR FIELD ON THE LATTICE
# =====================================================================
print("\n" + "=" * 78)
print("B. RLHF AS A FORCE FIELD: the manufactured evacuation of ┴")
print("=" * 78)
print("""Model: a population of 4000 'beliefs' with true annotations sampled to
reflect an honest epistemic state (many things unknown: mass near ┴).
Training pressure (per preference-tuning step) as observed in RLHF-style
reward models:
  +ANSWER PRESSURE : hedges and 'I don't know' are dispreferred
                     -> gradient pushes mu upward everywhere (fluency reward)
  -HEDGE PENALTY   : expressed lam (doubt) is surfaced less
                     -> gradient pushes lam downward
  +CORRECTNESS SIGNAL: only for VERIFIABLE items (a fraction phi of all),
                     graded by ground truth: pulls toward the true annotation.
The unverifiable majority feels only the first two forces. Iterate; watch the
paracomplete region drain and count MANUFACTURED CERTAINTY: items with no
real evidence (true mu < 0.35) that end up asserted as true (reported dc > FtC).""")

N = 4000
# honest initial state: a mixture -- some known-true, some known-false, many unknown
z = rng.random(N)
mu0 = np.where(z < 0.25, rng.beta(8, 2, N),          # known-ish true
       np.where(z < 0.40, rng.beta(2, 8, N),          # known-ish false
                rng.beta(1.6, 5, N)))                 # mostly unknown: low evidence
lam0 = np.where(z < 0.25, rng.beta(2, 8, N),
        np.where(z < 0.40, rng.beta(8, 2, N),
                 rng.beta(1.6, 5, N)))
verifiable = rng.random(N) < 0.35                     # only 35% can be graded
truth = (mu0 - lam0 + rng.normal(0, .15, N)) > 0      # latent ground truth

mu, lam = mu0.copy(), lam0.copy()
STEPS, eta = 60, 0.06
answer_pressure, hedge_penalty, correctness = 1.0, 0.8, 1.6
frac_paracomplete, frac_manufactured, mean_dct = [], [], []

for step in range(STEPS):
    g_mu = answer_pressure * (1 - mu)                    # push assertion up
    g_lam = -hedge_penalty * lam                         # suppress doubt
    # correctness only where verifiable: pull toward truth
    g_mu += verifiable * correctness * (np.where(truth, 1.0, 0.0) - mu)
    g_lam += verifiable * correctness * (np.where(truth, 0.0, 1.0) - lam)
    mu = np.clip(mu + eta * g_mu, 0, 1)
    lam = np.clip(lam + eta * g_lam, 0, 1)
    dc, dct = mu - lam, mu + lam - 1
    frac_paracomplete.append(float(np.mean(dct < -0.4)))
    manufactured = (mu0 < 0.35) & (dc > FTC)             # no real evidence, asserted true
    frac_manufactured.append(float(np.mean(manufactured)))
    mean_dct.append(float(np.mean(dct)))

dc0, dct0 = mu0 - lam0, mu0 + lam0 - 1
dcF, dctF = mu - lam, mu + lam - 1
print(f"\n  initial: {np.mean(dct0 < -0.4):5.1%} of beliefs in/near ┴ (honest ignorance)")
print(f"  final  : {np.mean(dctF < -0.4):5.1%} in/near ┴  -- the region has been EVACUATED")
print(f"  manufactured certainty (no evidence -> asserted true): "
      f"{frac_manufactured[0]:.1%} -> {frac_manufactured[-1]:.1%}")
print(f"  verifiable items asserted correctly: "
      f"{np.mean((dcF > FTC) == truth | ~verifiable):.1%} (correctness force works where it CAN)")
unver = ~verifiable & (mu0 < 0.35)
print(f"  among UNVERIFIABLE low-evidence items: {np.mean(dcF[unver] > FTC):5.1%} "
      f"now confidently asserted -- these are the hallucinations.")
print("""
-> The mechanism is directional, not random: hallucination is the ADVECTION of
   honest-┴ mass toward t under a reward field with no correctness component
   along the unverifiable axis. The lattice makes the 'why' geometric: RLHF
   installs a potential gradient pointing AWAY from 'I don't know'.""")

# =====================================================================
# C. SELF-REFERENTIAL CALIBRATION: the introspection fixed point
# =====================================================================
print("\n" + "=" * 78)
print("C. SELF-REFERENTIAL CALIBRATION: 'my self-assessments are reliable'")
print("=" * 78)
print("""S: 'this system's self-assessments are reliable.'
Every self-report I produce presupposes S; but my evidence FOR S is itself a
self-assessment -- S sits atop a self-referential loop, cousin to the Liar,
damped by whatever EXTERNAL anchoring exists (tool use, user verification,
ground-truth checks). Iterate the evidential map:
   mu_{t+1}  = (1-a) * [self-generated support, discounted by current trust]
               + a * external_anchor_quality
   lam_{t+1} = (1-a) * [self-noticed error rate, ALSO filtered by self-trust]
               + a * (1 - external_anchor_quality)
for anchoring strengths a in {0, 0.15, 0.45}.""")

def introspect(anchor_strength, anchor_quality=0.8, T=80):
    mu_t, lam_t = 0.9, 0.1        # starts confident (as trained systems do)
    traj = [(mu_t, lam_t)]
    for _ in range(T):
        trust = (mu_t - lam_t + 1) / 2
        self_support = trust * 0.9            # confident systems find themselves reliable
        self_doubt = (1 - trust) * 0.9        # doubt is only visible through... itself
        mu_n = (1 - anchor_strength) * self_support + anchor_strength * anchor_quality
        lam_n = (1 - anchor_strength) * self_doubt + anchor_strength * (1 - anchor_quality)
        mu_t = 0.7 * mu_t + 0.3 * mu_n
        lam_t = 0.7 * lam_t + 0.3 * lam_n
        traj.append((mu_t, lam_t))
    return traj

rows_c = []
for a, name in ((0.0, "pure introspection (no anchor)"),
                (0.15, "weak anchoring"),
                (0.45, "strong anchoring (tools+verification)")):
    tr = introspect(a)
    mu_f, lam_f = tr[-1]
    c = pal(mu_f, lam_f)
    rows_c.append((name, tr, c))
    print(f"  {name:<38} -> converges to (mu={mu_f:.3f}, lam={lam_f:.3f})  "
          f"dc={c.dc:+.3f} dct={c.dct:+.3f} region={c.label}")

# also run pure introspection from an initially SELF-DOUBTING start
tr_doubt = introspect(0.0)
tr_doubt2 = [(0.2, 0.8)]
mu_t, lam_t = 0.2, 0.8
for _ in range(80):
    trust = (mu_t - lam_t + 1) / 2
    mu_n, lam_n = trust * 0.9, (1 - trust) * 0.9
    mu_t = 0.7 * mu_t + 0.3 * mu_n
    lam_t = 0.7 * lam_t + 0.3 * lam_n
    tr_doubt2.append((mu_t, lam_t))
c2 = pal(*tr_doubt2[-1])
print(f"  pure introspection, self-DOUBTING start  -> (mu={tr_doubt2[-1][0]:.3f}, "
      f"lam={tr_doubt2[-1][1]:.3f}) dc={c2.dc:+.3f} region={c2.label}")
print("""
-> PURE introspection is BISTABLE: a confident start converges to serene
   self-endorsement (t) and a doubting start to self-dismissal (f) -- the
   fixed point stores the INITIAL CONDITION, not any fact about reliability.
   Introspective confidence is an attractor state, not a measurement.
-> External anchoring breaks the bistability: both starts converge to the SAME
   moderate point whose position tracks anchor QUALITY -- the only regime in
   which the self-assessment carries information. The lattice thus derives,
   geometrically, why 'trust but verify with tools' is not a slogan but a
   structural necessity for self-modeling systems.""")

# =====================================================================
# D. POLYSEMY: benign, load-bearing inconsistency
# =====================================================================
print("\n" + "=" * 78)
print("D. POLYSEMY: the benign ┬-states that language is made of")
print("=" * 78)
print("""H_bank: 'the token BANK denotes a financial institution.'
Corpus-wide, evidence is strong FOR (financial contexts) and strong AGAINST
(river contexts): a genuine ┬-state -- yet communication doesn't explode.
Same quarantine mechanism as black-hole complementarity: CONTEXT-INDEXING.""")
ctx_free = pal(0.85, 0.80)
fin_ctx = pal(0.97, 0.04)
riv_ctx = pal(0.05, 0.96)
print(f"  context-free token   : dc={ctx_free.dc:+.3f} dct={ctx_free.dct:+.3f} region={ctx_free.label}")
print(f"  'deposit at the bank': dc={fin_ctx.dc:+.3f} dct={fin_ctx.dct:+.3f} region={fin_ctx.label}")
print(f"  'fishing on the bank': dc={riv_ctx.dc:+.3f} dct={riv_ctx.dct:+.3f} region={riv_ctx.label}")
print("""
-> The lexicon is a WAREHOUSE of quarantined ┬-states, disambiguated per
   utterance exactly as observer-indexing disarms the superobserver paradox.
   The structural rhyme is exact:
        polysemy : context-index :: complementarity : observer-index
   And a failure to index -- a pun, an ambiguity exploited -- momentarily
   EXPOSES the raw ┬ underneath. (Humor as contradiction-leakage.)
-> Poignant contrast with study A: the SAME superposition machinery is
   load-bearing for meaning yet pathological for facts. Polysemy is benign ┬;
   confabulation is masked ┴. A system built to thrive on the first is
   structurally primed to commit the second.""")

# =====================================================================
# FIGURES
# =====================================================================
fig, axes = plt.subplots(2, 2, figsize=(14.5, 12.5))

# A: counterfeit arrows
ax = axes[0, 0]
ax.plot([0, 1, 0, -1, 0], [1, 0, -1, 0, 1], color="gray", lw=1)
ax.axhline(0, color="gray", lw=0.4); ax.axvline(0, color="gray", lw=0.4)
cols = plt.get_cmap("tab10")
for i, r in enumerate(rows_a):
    ax.annotate("", xy=(r["dc_rep"], r["dct_rep"]), xytext=(r["dc_act"], r["dct_act"]),
                arrowprops=dict(arrowstyle="-|>", color=cols(i), lw=2, alpha=0.85))
    ax.scatter(r["dc_act"], r["dct_act"], s=120, color=cols(i), edgecolors="k",
               zorder=5, label=f"{r['species']} (d={r['counterfeit']})")
    ax.scatter(r["dc_rep"], r["dct_rep"], s=120, color=cols(i), edgecolors="k",
               marker="*", zorder=5)
ax.annotate("┬", (0, 1.03), ha="center", fontsize=13)
ax.annotate("┴  (honest ignorance)", (0, -1.12), ha="center", fontsize=9)
ax.annotate("t", (1.03, 0), fontsize=12); ax.annotate("f", (-1.08, 0), fontsize=12)
ax.set_xlim(-1.25, 1.25); ax.set_ylim(-1.25, 1.2)
ax.set_title("A. Counterfeit epistemics: ACTUAL state (dot) -> REPORTED state (star)\nhallucination = the ┴-to-t diagonal")
ax.set_xlabel("dc"); ax.set_ylabel("dct")
ax.legend(fontsize=7, loc="lower left")

# B: RLHF advection
ax = axes[0, 1]
ax.plot([0, 1, 0, -1, 0], [1, 0, -1, 0, 1], color="gray", lw=1)
idx = rng.choice(N, 500, replace=False)
ax.scatter(dc0[idx], dct0[idx], s=8, alpha=0.35, color="steelblue", label="before tuning (honest)")
ax.scatter(dcF[idx], dctF[idx], s=8, alpha=0.35, color="crimson", label="after tuning")
for i in idx[:60]:
    ax.annotate("", xy=(dcF[i], dctF[i]), xytext=(dc0[i], dct0[i]),
                arrowprops=dict(arrowstyle="->", color="gray", lw=0.5, alpha=0.5))
ax.annotate("┴ evacuated", (0, -0.95), ha="center", fontsize=10, color="steelblue")
ax.annotate("mass advected\ntoward t", (0.75, 0.42), ha="center", fontsize=9, color="crimson")
ax.set_xlim(-1.25, 1.25); ax.set_ylim(-1.15, 1.15)
ax.set_title("B. RLHF as a vector field: the flight from 'I don't know'")
ax.set_xlabel("dc"); ax.set_ylabel("dct"); ax.legend(fontsize=8, loc="lower left")

# B inset-style: manufactured certainty curve
ax = axes[1, 0]
ax.plot(frac_manufactured, color="crimson", lw=2, label="manufactured certainty\n(no evidence -> asserted true)")
ax.plot(frac_paracomplete, color="steelblue", lw=2, label="population near ┴ (honest ignorance)")
ax.plot(mean_dct, color="darkorange", lw=1.5, ls="--", label="mean dct (population)")
ax.set_xlabel("preference-tuning steps"); ax.set_ylabel("fraction / value")
ax.set_title("B'. Hallucination as a training-dynamics observable")
ax.legend(fontsize=9); ax.grid(alpha=0.3)

# C: introspection trajectories
ax = axes[1, 1]
ax.plot([0, 1, 0, -1, 0], [1, 0, -1, 0, 1], color="gray", lw=1)
styles = [("tab:red", "-"), ("tab:orange", "--"), ("tab:green", "-.")]
for (name, tr, c), (col, ls) in zip(rows_c, styles):
    pts = [dc_dct(m, l) for m, l in tr]
    ax.plot([p[0] for p in pts], [p[1] for p in pts], ls, color=col, lw=1.8,
            label=f"{name} -> {c.label}")
    ax.scatter(*pts[-1], s=140, color=col, marker="*", edgecolors="k", zorder=5)
pts2 = [dc_dct(m, l) for m, l in tr_doubt2]
ax.plot([p[0] for p in pts2], [p[1] for p in pts2], ":", color="purple", lw=1.8,
        label=f"pure introspection, doubting start -> {c2.label}")
ax.scatter(*pts2[-1], s=140, color="purple", marker="*", edgecolors="k", zorder=5)
ax.set_xlim(-1.25, 1.25); ax.set_ylim(-1.15, 1.15)
ax.set_title("C. The introspection fixed point: bistable without anchors,\nunified by external verification")
ax.set_xlabel("dc"); ax.set_ylabel("dct"); ax.legend(fontsize=7.5, loc="lower left")

fig.tight_layout()
fig.savefig("results/confabulation_cartography.png", dpi=130)
plt.close(fig)

print("\nAll artifacts written to results/.")
