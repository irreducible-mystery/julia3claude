"""
Experiment 2: How PAL2v (Paraconsistent Annotated Evidential Logic Etau)
handles FUZZY BOUNDARIES.

Public dataset: Fisher's Iris (via scikit-learn, bundled offline).
Task: discriminate VIRGINICA vs VERSICOLOR -- the two species whose petal
measurements famously overlap (fuzzy class boundary).

Evidence engineering (independent "experts"):
  Expert 1 (petal LENGTH) gives favorable evidence mu that a flower is
  virginica, via a ramp fuzzy membership between the versicolor and
  virginica class means.
  Expert 2 (petal WIDTH) gives unfavorable evidence lambda (evidence that
  the flower is versicolor), via the mirrored ramp on petal width.

For crisp specimens the two experts agree (mu high & lambda low, or
vice versa). For borderline specimens they produce weak/contradicting
evidence -> PAL2v places them in transition regions ("quasi" states),
enabling principled ABSTENTION instead of forced misclassification.

Outputs:
  A) Per-sample lattice positions (dc x dct) colored by true species.
  B) Classification with abstention: accuracy on decided samples vs
     coverage, swept over FtC in [0.1 .. 0.9].
  C) Confusion analysis: where do errors live on the lattice?
"""
import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from sklearn.datasets import load_iris
from paraconsistent.blocks import ParaconsistentBlock

iris = load_iris()
X, y = iris.data, iris.target
names = iris.target_names
# keep versicolor (1) and virginica (2)
mask = (y == 1) | (y == 2)
X, y = X[mask], y[mask]
petal_len, petal_wid = X[:, 2], X[:, 3]
is_virginica = (y == 2).astype(int)

def ramp(x, lo, hi):
    """Fuzzy ramp membership: 0 below lo, 1 above hi, linear between."""
    return float(np.clip((x - lo) / (hi - lo), 0.0, 1.0))

# ramps anchored on class means (no per-sample tuning / leakage-light)
len_lo = petal_len[y == 1].mean()   # versicolor mean length ~4.26
len_hi = petal_len[y == 2].mean()   # virginica  mean length ~5.55
wid_lo = petal_wid[y == 1].mean()   # ~1.33
wid_hi = petal_wid[y == 2].mean()   # ~2.03
print(f"Fuzzy ramp anchors: petal length [{len_lo:.2f},{len_hi:.2f}] cm, "
      f"petal width [{wid_lo:.2f},{wid_hi:.2f}] cm")

def evidences(pl, pw):
    mu  = ramp(pl, len_lo, len_hi)          # expert 1: pro-virginica
    lam = 1.0 - ramp(pw, wid_lo, wid_hi)    # expert 2: anti-virginica
    return mu, lam

def analyze(mu, lam, ftc):
    b = ParaconsistentBlock()
    b.config.FtC = ftc
    b.input.mu = mu
    b.input.lam = lam
    return b.complete

# ---------------- Part A: lattice positions ----------------
FTC = 0.5
rows = []
for i in range(len(y)):
    mu, lam = evidences(petal_len[i], petal_wid[i])
    c = analyze(mu, lam, FTC)
    rows.append(dict(petal_len=petal_len[i], petal_wid=petal_wid[i],
                     species=names[y[i]], mu=round(mu,3), lam=round(lam,3),
                     dc=round(c.dc,3), dct=round(c.dct,3),
                     muER=round(c.muER,3), label=c.label,
                     decision=c.decision_output))
with open("results/exp2_samples.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader(); w.writerows(rows)

from collections import Counter
print("\nRegion occupancy by true species (FtC=0.5):")
for sp in ("versicolor", "virginica"):
    cnt = Counter(r["label"] for r in rows if r["species"] == sp)
    print(f"  {sp:>10}: " + ", ".join(f"{k}:{v}" for k, v in cnt.most_common()))

fig, ax = plt.subplots(figsize=(7.5, 6.5))
for sp, col, mk in (("versicolor", "tab:orange", "o"), ("virginica", "tab:blue", "s")):
    xs = [r["dc"] for r in rows if r["species"] == sp]
    ys = [r["dct"] for r in rows if r["species"] == sp]
    ax.scatter(xs, ys, c=col, marker=mk, alpha=0.7, label=sp, edgecolors="k", lw=0.3)
# lattice guides
ax.axvline(FTC, color="green", ls="--", lw=1, label=f"|dc| = FtC ({FTC})")
ax.axvline(-FTC, color="green", ls="--", lw=1)
ax.plot([0,1,0,-1,0],[1,0,-1,0,1], color="gray", lw=0.8)
ax.set_xlabel("dc  (degree of certainty:  <- versicolor  |  virginica ->)")
ax.set_ylabel("dct (degree of contradiction)")
ax.set_title("Iris fuzzy boundary on the PAL2v lattice\n(boundary flowers drift toward low-|dc| transition zone)")
ax.legend(); ax.grid(alpha=0.3)
ax.set_xlim(-1.05, 1.05); ax.set_ylim(-1.05, 1.05)
fig.tight_layout()
fig.savefig("results/exp2_lattice_scatter.png", dpi=130)
plt.close(fig)

# ---------------- Part B: accuracy vs coverage sweep ----------------
print("\nAbstention sweep (decide virginica if dc >= FtC, versicolor if dc <= -FtC, else ABSTAIN):")
print(f"{'FtC':>5} {'decided':>8} {'abstain':>8} {'acc(decided)':>13} {'acc(forced-all)':>16}")
sweep = []
for ftc in np.round(np.arange(0.1, 0.91, 0.1), 2):
    decided = correct = 0
    forced_correct = 0
    for i in range(len(y)):
        mu, lam = evidences(petal_len[i], petal_wid[i])
        c = analyze(mu, lam, float(ftc))
        truth = is_virginica[i]
        # forced baseline: sign of dc decides always
        forced_pred = 1 if c.dc >= 0 else 0
        forced_correct += (forced_pred == truth)
        if c.dc >= ftc:
            decided += 1; correct += (truth == 1)
        elif c.dc <= -ftc:
            decided += 1; correct += (truth == 0)
    ncov = decided / len(y)
    acc = correct / decided if decided else float("nan")
    facc = forced_correct / len(y)
    sweep.append(dict(FtC=float(ftc), coverage=ncov, abstain=1-ncov,
                      acc_decided=acc, acc_forced=facc))
    print(f"{ftc:>5.1f} {ncov:>8.1%} {1-ncov:>8.1%} {acc:>13.1%} {facc:>16.1%}")

with open("results/exp2_abstention_sweep.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=sweep[0].keys())
    w.writeheader(); w.writerows(sweep)

fig, ax = plt.subplots(figsize=(7.5, 5))
ax.plot([s["FtC"] for s in sweep], [s["acc_decided"] for s in sweep],
        "o-", label="accuracy on decided samples (PAL2v abstains near boundary)")
ax.plot([s["FtC"] for s in sweep], [s["acc_forced"] for s in sweep],
        "x--", label="forced classification (no abstention baseline)")
ax2 = ax.twinx()
ax2.bar([s["FtC"] for s in sweep], [s["coverage"] for s in sweep],
        width=0.055, alpha=0.18, color="gray", label="coverage (decided fraction)")
ax2.set_ylabel("coverage"); ax2.set_ylim(0, 1.05)
ax.set_xlabel("FtC (certainty requirement)")
ax.set_ylabel("accuracy"); ax.set_ylim(0.85, 1.01)
ax.set_title("Fuzzy boundary: trading coverage for certainty (Iris, n=100)")
h1, l1 = ax.get_legend_handles_labels(); h2, l2 = ax2.get_legend_handles_labels()
ax.legend(h1 + h2, l1 + l2, loc="lower left", fontsize=9)
ax.grid(alpha=0.3)
fig.tight_layout()
fig.savefig("results/exp2_accuracy_coverage.png", dpi=130)
plt.close(fig)

# ---------------- Part C: where do errors live? ----------------
print("\nError anatomy at FtC=0.5 (forced classification by sign of dc):")
err_dc, ok_dc = [], []
for r in rows:
    truth = 1 if r["species"] == "virginica" else 0
    pred = 1 if r["dc"] >= 0 else 0
    (ok_dc if pred == truth else err_dc).append(abs(r["dc"]))
print(f"  correct samples: n={len(ok_dc):3d}, mean |dc| = {np.mean(ok_dc):.3f}")
print(f"  errors:          n={len(err_dc):3d}, mean |dc| = {np.mean(err_dc):.3f}")
print("  -> errors concentrate at low |dc| (the fuzzy zone PAL2v flags as 'quasi' states)")

err_labels = Counter(r["label"] for r in rows
                     if (1 if r["species"]=="virginica" else 0) != (1 if r["dc"]>=0 else 0))
print(f"  error regions: {dict(err_labels)}")

print("\nExperiment 2 complete. Artifacts in results/.")
