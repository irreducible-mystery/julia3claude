#!/usr/bin/env python3
"""The dial aims itself: r-homeostasis driven by a simulated audience.

Inner loop: the robot measures its own behavioral wildness W (how surprised it
is by its own motion, via its own LMS predictor) and nudges r toward a
setpoint S: r += a*(S - W).

Outer loop: a simulated audience. Attention = inverted-U in wildness
(Berlyne/Wundt: too still = boring, too wild = unwatchable) discounted by
habituation (novelty = change vs. the long-run average). Neglect -> S rises ->
r rises -> wilder. The vicious loop is allowed to run.

PREDICTIONS (written before running):
  P1. r will not sit still: attention habituates, so r oscillates over 5 days.
  P2. Time-averaged r hovers near the edge (3.5-3.7): the inverted-U pulls it there.
  P3. Possible late pinning at r~4 (chaos trap): if wildness kills attention,
      neglect keeps S high and nothing pulls it back. If seen, the nightly
      "dreaming" reset becomes a design requirement, not a nice-to-have.
  P4. Audience surprise peaks at transitions, not at steady chaos.
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

OUT = os.path.expanduser("~/workspace/art-project")
os.makedirs(OUT, exist_ok=True)

DAYS, TPD = 5, 288
T = DAYS * TPD

# Lyapunov curve for the lambda strip (recomputed compactly)
rl = np.linspace(2.8, 4.0, 800)
xx = np.full_like(rl, 0.5)
for _ in range(500):
    xx = rl * xx * (1 - xx)
acc = np.zeros_like(rl)
for _ in range(3000):
    xx = rl * xx * (1 - xx)
    acc += np.log(np.abs(rl * (1 - 2 * xx)) + 1e-300)
lam_curve = np.clip(acc / 3000, -3, 1)


class LMS:
    """Tiny online linear predictor: predicts next kick from last 3."""
    def __init__(self, lr=0.05):
        self.w = np.zeros(3)
        self.lr = lr
        self.hist = []

    def step(self, kick):
        self.hist.append(kick)
        err = 0.0
        if len(self.hist) >= 4:
            feat = np.array(self.hist[-4:-1])
            pred = self.w @ feat
            err = kick - pred
            self.w += self.lr * err * feat
        return abs(err)


def run():
    x = 0.3
    r = 2.9
    pos = np.array([50.0, 50.0])
    theta = 0.0
    self_pred, aud_pred = LMS(0.05), LMS(0.05)
    W = 0.0          # wildness: EMA of self-surprise
    W_long = 0.0     # slow average (habituation reference)
    A_ema = 0.3
    rec = {k: [] for k in
           ["r", "W", "S", "A", "novelty", "surprise", "x", "pos"]}
    for t in range(T):
        x = r * x * (1 - x)
        kick = 2.0 * (x - 0.5)
        theta += kick
        pos = np.clip(pos + 0.9 * np.array([np.cos(theta), np.sin(theta)]), 2, 98)

        s_sur = self_pred.step(kick)     # how surprised am I by myself?
        a_sur = aud_pred.step(kick)      # how surprised is the audience?
        W = 0.95 * W + 0.05 * min(s_sur / 0.5, 1.0)
        W_long = 0.9967 * W_long + 0.0033 * W   # ~300-tick memory

        novelty = min(abs(W - W_long) / 0.3, 1.0)
        I = 4 * W * (1 - W)                       # inverted-U: peak at W=0.5
        A = I * (0.15 + 0.85 * novelty)
        A_ema = 0.9958 * A_ema + 0.0042 * A       # ~240-tick memory

        S = float(np.clip(0.5 + 1.2 * (0.45 - A_ema), 0.05, 0.95))
        r = float(np.clip(r + 0.008 * (S - W), 2.8, 4.0))

        for k, v in [("r", r), ("W", W), ("S", S), ("A", A),
                     ("novelty", novelty), ("surprise", a_sur),
                     ("x", x)]:
            rec[k].append(v)
        rec["pos"].append(pos.copy())
    for k in rec:
        rec[k] = np.array(rec[k])
    return rec


rec = run()
r_hist = rec["r"]
lam_t = np.interp(r_hist, rl, lam_curve)
days = np.arange(T) / TPD

# ---- prediction scorecard (computed, reported in reply) ----
print("--- scorecard ---")
print(f"r range over 5 days: [{r_hist.min():.3f}, {r_hist.max():.3f}]")
print(f"mean r: {r_hist.mean():.3f} | frac time r>3.9: {(r_hist > 3.9).mean():.2f}")
print(f"r std: {r_hist.std():.3f} (oscillation amplitude)")
print(f"final-day mean r: {r_hist[-TPD:].mean():.3f} (pinning check)")
# surprise at transitions vs steady chaos:
dr = np.abs(np.diff(r_hist))
trans = dr > np.median(dr)
s = rec['surprise'][1:]
print(f"mean surprise |r changing fast|: {s[trans].mean():.3f} "
      f"vs slow: {s[~trans].mean():.3f}")
print(f"mean attention: {rec['A'].mean():.3f}")

# ---- plots ----
fig, axes = plt.subplots(4, 1, figsize=(10, 10), sharex=True)
axes[0].plot(days, r_hist, c="#c0392b", lw=1.2)
axes[0].axhline(3.5699456, c="black", ls="--", lw=0.8, alpha=0.6)
axes[0].text(0.1, 3.62, "Feigenbaum point", fontsize=8)
axes[0].set_ylabel("r (self-tuned)")
axes[0].set_ylim(2.75, 4.05)
axes[1].plot(days, rec["W"], c="#2980b9", lw=1.2, label="wildness W (self-surprise)")
axes[1].plot(days, rec["S"], c="#27ae60", lw=1.2, ls="--", label="setpoint S (from neglect)")
axes[1].set_ylabel("wildness")
axes[1].legend(fontsize=8)
axes[1].set_ylim(0, 1.05)
axes[2].plot(days, rec["A"], c="#8e44ad", lw=1.2, label="attention")
axes[2].plot(days, rec["novelty"], c="#7f8c8d", lw=0.8, alpha=0.7, label="novelty")
axes[2].set_ylabel("audience")
axes[2].legend(fontsize=8)
axes[2].set_ylim(0, 1.05)
axes[3].plot(days, lam_t, c="#2980b9", lw=1)
axes[3].axhline(0, c="black", lw=0.8)
axes[3].fill_between(days, lam_t, 0, where=(lam_t > 0), color="#c0392b", alpha=0.25)
axes[3].set_ylabel("λ(t)")
axes[3].set_xlabel("day")
fig.suptitle("The dial aims itself: r-homeostasis driven by simulated attention")
fig.tight_layout()
fig.savefig(f"{OUT}/r_selftune.png", dpi=110)

fig, ax = plt.subplots(figsize=(8, 8))
pos = rec["pos"]
sc = ax.scatter(pos[:, 0], pos[:, 1], c=r_hist, s=2, cmap="coolwarm",
                vmin=2.8, vmax=4.0)
ax.set_xlim(0, 100); ax.set_ylim(0, 100); ax.set_aspect("equal")
ax.set_title("Five days, dial self-aimed (color = r)")
fig.colorbar(sc, ax=ax, label="r", shrink=0.8)
fig.tight_layout()
fig.savefig(f"{OUT}/r_selftune_traj.png", dpi=110)

fig, ax = plt.subplots(figsize=(7, 6))
sc = ax.scatter(rec["W"], rec["A"], c=days, s=3, cmap="viridis", alpha=0.6)
ax.set_xlabel("wildness W")
ax.set_ylabel("attention A")
ax.set_title("Phase portrait: wildness vs attention (color = time)")
fig.colorbar(sc, ax=ax, label="day")
fig.tight_layout()
fig.savefig(f"{OUT}/r_phase.png", dpi=110)
print("saved plots to", OUT)
