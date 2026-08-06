"""
Experiment 1: How PAL2v (Paraconsistent Annotated Evidential Logic Etau)
handles CONFLICTING DATA.

Scenario: Two independent sources evaluate the same hypothesis
("industrial machine is faulty").
  - Source A -> favorable evidence mu  (vibration sensor)
  - Source B -> unfavorable evidence lambda (temperature sensor)

Part A: Conflict sweep. Start in agreement (mu=0.9, lam=0.1) and increase
        lambda to 0.9 (total conflict). Compare PAL2v outputs vs a naive
        classical fusion (simple average of mu and 1-lam), which is blind
        to conflict.

Part B: Full-lattice map. Grid over unit square of annotations (mu, lam)
        to show the 12 logical regions and where conflicting inputs land.

Part C: Noisy multi-sensor fusion. 200 Monte-Carlo trials where a faulty
        machine (ground truth = faulty) is measured by one reliable and one
        broken (contradicting) sensor. Show that PAL2v flags the conflict
        (high dct / inconsistency region) instead of silently averaging.
"""
import csv
import random
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from paraconsistent.blocks import ParaconsistentBlock

random.seed(42)
np.random.seed(42)

FTC = 0.6

def analyze(mu, lam, ftc=FTC):
    b = ParaconsistentBlock()
    b.config.FtC = ftc
    b.input.mu = mu
    b.input.lam = lam
    c = b.complete
    return dict(mu=mu, lam=lam, dc=c.dc, dct=c.dct, muER=c.muER,
                phi=c.phi, label=c.label, decision=c.decision_output)

# ---------------- Part A: conflict sweep ----------------
print("=" * 78)
print("PART A - Conflict sweep: mu fixed at 0.9, lambda rises 0.1 -> 0.9")
print("=" * 78)
print(f"{'mu':>5} {'lam':>5} | {'dc':>6} {'dct':>6} {'muER':>6} {'phi':>5} "
      f"{'naive avg':>9} | {'region':>7} {'decision':>8}")

sweep_rows = []
for lam in np.round(np.arange(0.10, 0.91, 0.10), 2):
    r = analyze(0.90, float(lam))
    naive = (r["mu"] + (1 - r["lam"])) / 2  # classical fusion, conflict-blind
    r["naive"] = naive
    sweep_rows.append(r)
    dec = {1.0: "ACCEPT", 0.0: "REJECT", 0.5: "UNDEC."}[r["decision"]]
    print(f"{r['mu']:>5.2f} {r['lam']:>5.2f} | {r['dc']:>6.2f} {r['dct']:>6.2f} "
          f"{r['muER']:>6.3f} {r['phi']:>5.2f} {naive:>9.3f} | "
          f"{r['label']:>7} {dec:>8}")

with open("results/exp1_sweep.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=sweep_rows[0].keys())
    w.writeheader(); w.writerows(sweep_rows)

# Plot sweep
lams = [r["lam"] for r in sweep_rows]
fig, ax = plt.subplots(1, 2, figsize=(12, 4.5))
ax[0].plot(lams, [r["dc"] for r in sweep_rows], "o-", label="dc (certainty)")
ax[0].plot(lams, [r["dct"] for r in sweep_rows], "s-", label="dct (contradiction)")
ax[0].plot(lams, [r["phi"] for r in sweep_rows], "^-", label="phi (certainty interval)")
ax[0].axhline(0, color="gray", lw=0.5)
ax[0].set_xlabel("unfavorable evidence lambda (mu fixed = 0.9)")
ax[0].set_title("PAL2v exposes conflict explicitly")
ax[0].legend(); ax[0].grid(alpha=0.3)

ax[1].plot(lams, [r["muER"] for r in sweep_rows], "o-", label="PAL2v muER (real evidence)")
ax[1].plot(lams, [r["naive"] for r in sweep_rows], "x--", label="naive average (conflict-blind)")
ax[1].axhline(FTC, color="red", lw=0.8, ls=":", label=f"decision threshold FtC={FTC}")
ax[1].set_xlabel("unfavorable evidence lambda (mu fixed = 0.9)")
ax[1].set_title("Fused output: PAL2v vs classical average")
ax[1].legend(); ax[1].grid(alpha=0.3)
fig.tight_layout()
fig.savefig("results/exp1_conflict_sweep.png", dpi=130)
plt.close(fig)

# ---------------- Part B: lattice region map ----------------
print("\n" + "=" * 78)
print("PART B - Region map over the whole unit square of annotations (41x41 grid)")
print("=" * 78)
n = 41
grid_labels = {}
label_names = []
lab_idx = {}
Z = np.zeros((n, n))
mus = np.linspace(0, 1, n)
lams_g = np.linspace(0, 1, n)
for i, lam in enumerate(lams_g):
    for j, mu in enumerate(mus):
        lab = analyze(float(mu), float(lam))["label"]
        if lab not in lab_idx:
            lab_idx[lab] = len(lab_idx)
            label_names.append(lab)
        Z[i, j] = lab_idx[lab]
        grid_labels[(round(mu,3), round(lam,3))] = lab

from collections import Counter
cnt = Counter(grid_labels.values())
print("Region occupancy over the grid:")
for lab, c in cnt.most_common():
    print(f"  {lab:>7}: {c:4d} cells ({100*c/len(grid_labels):.1f}%)")

fig, ax = plt.subplots(figsize=(7.5, 6.5))
cmap = plt.get_cmap("tab20", len(label_names))
im = ax.imshow(Z, origin="lower", extent=[0, 1, 0, 1], cmap=cmap, aspect="auto")
cbar = fig.colorbar(im, ticks=range(len(label_names)))
cbar.ax.set_yticklabels(label_names)
# overlay the Part A trajectory
ax.plot([r["mu"] for r in sweep_rows], [r["lam"] for r in sweep_rows],
        "k*-", ms=12, lw=1.5, label="conflict sweep trajectory")
ax.set_xlabel("mu (favorable evidence)")
ax.set_ylabel("lambda (unfavorable evidence)")
ax.set_title(f"PAL2v 12-region lattice map (FtC={FTC})\nwith conflict-sweep trajectory")
ax.legend(loc="lower left")
fig.tight_layout()
fig.savefig("results/exp1_lattice_map.png", dpi=130)
plt.close(fig)

# ---------------- Part C: Monte-Carlo noisy contradicting sensors ----------------
print("\n" + "=" * 78)
print("PART C - Monte-Carlo: reliable sensor vs broken (contradicting) sensor")
print("=" * 78)
N = 200
scenarios = {
    "both sensors healthy (agree)":  lambda: (np.clip(np.random.normal(0.85, 0.07), 0, 1),
                                              np.clip(np.random.normal(0.15, 0.07), 0, 1)),
    "one sensor broken (conflict)":  lambda: (np.clip(np.random.normal(0.85, 0.07), 0, 1),
                                              np.clip(np.random.normal(0.85, 0.07), 0, 1)),
}
mc_summary = []
for name, gen in scenarios.items():
    recs = [analyze(*map(float, gen())) for _ in range(N)]
    dct_mean = np.mean([r["dct"] for r in recs])
    accept = sum(r["decision"] == 1.0 for r in recs) / N
    undec = sum(r["decision"] == 0.5 for r in recs) / N
    labels = Counter(r["label"] for r in recs)
    top = ", ".join(f"{k}:{v}" for k, v in labels.most_common(3))
    naive_accept = np.mean([( (r['mu'] + (1-r['lam']))/2 ) > FTC for r in recs])
    print(f"\nScenario: {name}  (n={N})")
    print(f"  mean contradiction dct      = {dct_mean:+.3f}")
    print(f"  PAL2v ACCEPT rate           = {accept:5.1%}")
    print(f"  PAL2v flagged (not-accept)  = {1-accept:5.1%}")
    print(f"  naive-average ACCEPT rate   = {naive_accept:5.1%}")
    print(f"  dominant regions            : {top}")
    mc_summary.append(dict(scenario=name, mean_dct=dct_mean, pal2v_accept=accept,
                           naive_accept=naive_accept, undecided=undec, regions=top))

with open("results/exp1_montecarlo.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=mc_summary[0].keys())
    w.writeheader(); w.writerows(mc_summary)

print("\nExperiment 1 complete. Artifacts in results/.")
