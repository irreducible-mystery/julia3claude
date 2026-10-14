#!/usr/bin/env python3
"""Exploring r: the logistic map as the robot's temperament dial.

1. Bifurcation diagram + Lyapunov exponent (the honest dial under the knob).
2. Rough re-derivation of Feigenbaum delta from the diagram.
3. A robot flying on the map: heading kicks from x_n, r on a 5-day arc.
4. Determinism check: same seed -> identical dance (replayable moods).
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

OUT = os.path.expanduser("~/workspace/art-project")
os.makedirs(OUT, exist_ok=True)

# ---------- 1. bifurcation diagram (vectorized over r) ----------
rs = np.linspace(2.8, 4.0, 1400)
x = np.full_like(rs, 0.5)
for _ in range(900):
    x = rs * x * (1 - x)
xs, rr = [], []
for _ in range(150):
    x = rs * x * (1 - x)
    xs.append(x.copy())
xs = np.array(xs)  # (150, 1400)

# ---------- 2. Lyapunov exponent ----------
rl = np.linspace(2.8, 4.0, 800)
x = np.full_like(rl, 0.5)
for _ in range(500):
    x = rl * x * (1 - x)
acc = np.zeros_like(rl)
N = 3000
for _ in range(N):
    x = rl * x * (1 - x)
    acc += np.log(np.abs(rl * (1 - 2 * x)) + 1e-300)
lam = acc / N
lam_plot = np.clip(lam, -3, 1)

# ---------- 3. rough delta from the diagram ----------
# count distinct attractor points per r from the final orbit.
# Long transient: near bifurcations convergence suffers critical slowing down,
# and a short transient fakes early bifurcations.
rg = np.linspace(2.95, 3.58, 3000)
uniq = np.zeros(len(rg), dtype=int)
xx = np.full_like(rg, 0.5)
for _ in range(4000):
    xx = rg * xx * (1 - xx)
orb = np.empty((200, len(rg)))
for k in range(200):
    xx = rg * xx * (1 - xx)
    orb[k] = xx
for i in range(len(rg)):
    uniq[i] = len(np.unique(np.round(orb[:, i], 4)))

def first_sustained(thresh, hold=5):
    ok = np.convolve((uniq >= thresh).astype(int), np.ones(hold), mode="same") >= hold
    return rg[np.argmax(ok)]

r1, r2, r3 = first_sustained(2), first_sustained(4), first_sustained(8)
delta_est = (r2 - r1) / (r3 - r2)
print(f"bifurcation points from diagram: r1={r1:.4f} r2={r2:.4f} r3={r3:.4f}")
print(f"delta estimate: {delta_est:.3f}  (Kelly measured 4.6691980766, literature 4.6692016091)")

# ---------- 4. robot flying on the map ----------
DAYS, TPD = 5, 288
T = DAYS * TPD

def r_arc(t):
    """Prescribed 5-day temperament arc."""
    d = t / TPD
    if d < 1:            # day 1: tight ritual (period 2)
        return 2.9
    if d < 2:            # day 2: the cascade (2 -> 4 -> 8 -> 16 ...)
        return 2.9 + (3.57 - 2.9) * (d - 1)
    if d < 3:            # day 3: dwelling at the edge
        return 3.57 + 0.08 * np.sin(2 * np.pi * (d - 2))
    if d < 4:            # day 4: wild (chaos)
        return 3.9
    if d < 4.6:          # day 5a: island of order (period-3 window)
        return 3.8284271247461903
    return 4.0           # day 5b: full chaos, release

def fly(seed=0.3):
    x = seed
    pos = np.array([50.0, 50.0])
    theta = 0.0
    trail, r_hist = [], []
    for t in range(T):
        r = r_arc(t)
        x = r * x * (1 - x)
        theta += 2.0 * (x - 0.5)          # heading kick from the map
        pos = np.clip(pos + 0.9 * np.array([np.cos(theta), np.sin(theta)]), 2, 98)
        trail.append(pos.copy())
        r_hist.append(r)
    return np.array(trail), np.array(r_hist)

trail_a, r_hist = fly(seed=0.3)
trail_b, _ = fly(seed=0.3)               # replay: same seed
trail_c, _ = fly(seed=0.3000001)         # near-identical seed
print(f"determinism check |replay - original|_max = {np.abs(trail_b - trail_a).max():.2e} (expect 0)")
print(f"seed+1e-7 final distance apart = {np.linalg.norm(trail_c[-1] - trail_a[-1]):.1f}")
print("  (the day-1 ordered regime contracts the 1e-7 nudge below float64's")
print("   rounding quantum, so both orbits become bit-identical: finite precision")
print("   heals what exact math would never forget. Moods are replayable because")
print("   the machine is finite.)")

# clean amplification demo: perturb *inside* the chaotic regime only
x, pos, theta = 0.3, np.array([50.0, 50.0]), 0.0
tr1 = []
for _ in range(500):
    x = 4.0 * x * (1 - x)
    theta += 2.0 * (x - 0.5)
    pos = np.clip(pos + 0.9 * np.array([np.cos(theta), np.sin(theta)]), 2, 98)
    tr1.append(pos.copy())
x, pos, theta = 0.3, np.array([50.0, 50.0]), 0.0
tr2 = []
for t in range(500):
    if t == 300:
        x += 1e-7   # one nudge, mid-chaos
    x = 4.0 * x * (1 - x)
    theta += 2.0 * (x - 0.5)
    pos = np.clip(pos + 0.9 * np.array([np.cos(theta), np.sin(theta)]), 2, 98)
    tr2.append(pos.copy())
tr1, tr2 = np.array(tr1), np.array(tr2)
print(f"chaos-only: 1e-7 nudge at tick 300 -> distance 200 ticks later = "
      f"{np.linalg.norm(tr2[-1] - tr1[-1]):.1f} (amplification, as advertised)")

lam_of_r = np.interp(r_hist, rl, lam_plot)

# ---------- plots ----------
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), sharex=True,
                               gridspec_kw={"height_ratios": [3, 1]})
ax1.scatter(np.repeat(rs, 150), xs.T.ravel(), s=0.15, c="black", alpha=0.5,
            rasterized=True)
for rv, lab in [(3.0, "period 2"), (3.4495, "period 4"), (3.5441, "period 8"),
                (3.5699456, "chaos onset\n(Feigenbaum point)"),
                (3.8284271, "period-3 window\nisland of order")]:
    ax1.axvline(rv, c="#c0392b", ls="--", lw=0.8, alpha=0.7)
    ax1.text(rv + 0.008, 0.93, lab, fontsize=7, color="#c0392b", va="top")
ax1.set_ylabel("attractor x")
ax1.set_title("The dial: logistic-map bifurcation diagram (x_{n+1} = r·x_n(1−x_n))")
ax1.set_ylim(0, 1)
ax2.plot(rl, lam_plot, c="#2980b9", lw=1.2)
ax2.axhline(0, c="black", lw=0.8)
ax2.fill_between(rl, lam_plot, 0, where=(lam_plot > 0), color="#c0392b", alpha=0.25,
                 label="chaos (λ>0)")
ax2.set_xlabel("r")
ax2.set_ylabel("Lyapunov λ(r)")
ax2.legend(fontsize=8, loc="lower left")
ax2.set_ylim(-3, 1)
fig.tight_layout()
fig.savefig(f"{OUT}/r_bifurcation.png", dpi=110)

# trajectory colored by r, with r(t) and lambda(t) strips
fig = plt.figure(figsize=(11, 8))
gs = fig.add_gridspec(3, 2, height_ratios=[3, 1, 1])
ax = fig.add_subplot(gs[0, :])
sc = ax.scatter(trail_a[:, 0], trail_a[:, 1], c=r_hist, s=2, cmap="coolwarm",
                vmin=2.8, vmax=4.0)
ax.plot(trail_a[0, 0], trail_a[0, 1], "go", ms=8, label="start")
ax.plot(trail_a[-1, 0], trail_a[-1, 1], "rx", ms=10, mew=2, label="end")
ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.set_aspect("equal")
ax.set_title("Five days flying on the map (color = r)")
fig.colorbar(sc, ax=ax, label="r", shrink=0.8)
ax.legend(fontsize=8)
ax2 = fig.add_subplot(gs[1, :])
ax2.plot(np.arange(T) / TPD, r_hist, c="#c0392b", lw=1)
ax2.set_ylabel("r(t)")
ax2.set_xlim(0, 5)
for dv, lab in [(1, "ritual"), (2, "cascade"), (3, "edge"), (4, "wild"), (5, "island→release")]:
    ax2.text(dv - 0.5, 3.95, lab, fontsize=7, ha="center", color="#7f8c8d")
ax3 = fig.add_subplot(gs[2, :])
ax3.plot(np.arange(T) / TPD, lam_of_r, c="#2980b9", lw=1)
ax3.axhline(0, c="black", lw=0.8)
ax3.set_ylabel("λ(t)")
ax3.set_xlabel("day")
ax3.set_xlim(0, 5)
fig.tight_layout()
fig.savefig(f"{OUT}/r_trajectory.png", dpi=110)

# small multiples: fixed r
fig, axes = plt.subplots(2, 3, figsize=(12, 8))
for ax, r, title in zip(axes.flat,
                        [2.9, 3.5, 3.5699456, 3.7, 3.8284271, 4.0],
                        ["r=2.9 · period 2: pacing", "r=3.5 · period 4: ritual",
                         "r=3.5699 · the edge", "r=3.7 · chaos",
                         "r=3.8284 · period-3 island", "r=4.0 · full chaos"]):
    x, pos, theta = 0.3, np.array([50.0, 50.0]), 0.0
    tr = []
    for _ in range(600):
        x = r * x * (1 - x)
        theta += 2.0 * (x - 0.5)
        pos = np.clip(pos + 0.9 * np.array([np.cos(theta), np.sin(theta)]), 2, 98)
        tr.append(pos.copy())
    tr = np.array(tr)
    ax.plot(tr[:, 0], tr[:, 1], c="black", lw=0.6)
    ax.set_title(title, fontsize=10)
    ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.set_aspect("equal")
    ax.set_xticks([]); ax.set_yticks([])
fig.suptitle("Same controller, six temperaments (600 ticks each)")
fig.tight_layout()
fig.savefig(f"{OUT}/r_temperaments.png", dpi=110)
print("saved plots to", OUT)
