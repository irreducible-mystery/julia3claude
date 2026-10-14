#!/usr/bin/env python3
"""Three robots, three floors, five days. Toy simulation.

Same body, same room, same spill (identical randomness), different logic:
  - tetralemma : Madhyamaka four kotis cycled as action modes
  - classical  : bivalent policy with quantum-style collapse near threshold
  - process    : no goal state; motion from history/novelty only

One day = 288 five-minute ticks. Metrics + plots saved to ~/workspace/art-project/.
"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

OUT = os.path.expanduser("~/workspace/art-project")
os.makedirs(OUT, exist_ok=True)

DAYS, TICKS_PER_DAY = 5, 288
T = DAYS * TICKS_PER_DAY
CENTER = np.array([50.0, 50.0])

SEEP_LAMBDA = 0.5
DIFFUSE_SIG = 0.55
SWEEP_R, SWEEP_PULL = 6.0, 3.0
MAX_SPEED = 1.3
E_MAX, E_MOVE, E_SWEEP, E_REST = 100.0, 0.045, 0.02, 0.5
MODES = ["work", "dance", "drift", "still"]


def clamp(p):
    return np.clip(p, 2.0, 98.0)


class Room:
    def __init__(self, seed):
        self.erng = np.random.default_rng(seed)
        th = self.erng.uniform(0, 2 * np.pi, 250)
        rr = self.erng.uniform(0, 6, 250)
        self.fluid = CENTER + np.stack([rr * np.cos(th), rr * np.sin(th)], axis=1)

    def seep_and_diffuse(self):
        n = self.erng.poisson(SEEP_LAMBDA)
        if n:
            self.fluid = np.vstack([self.fluid, CENTER + self.erng.normal(0, 3.0, (n, 2))])
        self.fluid = clamp(self.fluid + self.erng.normal(0, DIFFUSE_SIG, self.fluid.shape))
        if len(self.fluid) > 1500:
            self.fluid = self.fluid[-1500:]

    def spill(self):
        return float(np.mean(np.linalg.norm(self.fluid - CENTER, axis=1)))

    def sweep(self, pos, active):
        if not active:
            return 0
        d = np.linalg.norm(self.fluid - pos, axis=1)
        m = d < SWEEP_R
        if m.any():
            vec = CENTER - self.fluid[m]
            nrm = np.linalg.norm(vec, axis=1, keepdims=True) + 1e-9
            self.fluid[m] = clamp(self.fluid[m] + vec / nrm * SWEEP_PULL)
        return int(m.sum())


class Robot:
    def __init__(self, name, policy, seed):
        self.name, self.policy = name, policy
        self.rng = np.random.default_rng(seed)
        self.pos = np.array([50.0, 80.0])
        self.energy = E_MAX
        self.visit = np.zeros((25, 25))
        self.trail = []
        self.log = []
        self.swept_total = 0

    def step(self, tick, room):
        target, sweeping, mode = self.policy(tick, self, room)
        if self.energy < 8:  # the body overrules every floor
            target, sweeping, mode = self.pos.copy(), False, "still"
        delta = target - self.pos
        dist = float(np.linalg.norm(delta))
        speed = min(MAX_SPEED, dist)
        if dist > 1e-9:
            self.pos = clamp(self.pos + delta / dist * speed)
        self.energy -= E_MOVE * (speed / MAX_SPEED) + (E_SWEEP if sweeping else 0)
        if speed < 0.15:
            self.energy = min(E_MAX, self.energy + E_REST)
        self.swept_total += room.sweep(self.pos, sweeping)
        self.visit *= 0.996
        i = int(np.clip(self.pos[0] / 4, 0, 24))
        j = int(np.clip(self.pos[1] / 4, 0, 24))
        self.visit[i, j] += 1
        self.trail.append(self.pos.copy())
        self.log.append((mode, speed, self.energy))


# ---------------- the three floors ----------------

def p_tetralemma(tick, rob, room):
    """Cycles the four kotis as watches: affirm, deny, both, neither."""
    watch = (tick // (TICKS_PER_DAY // 4)) % 4
    centroid = room.fluid.mean(axis=0)
    away = clamp(2 * CENTER - centroid)
    if watch == 0:            # P: gather the fluid
        return centroid, True, "work"
    if watch == 1:            # not-P: refuse the task
        return away, False, "drift"
    if watch == 2:            # both P and not-P: oscillate
        toward = (tick // 8) % 2 == 0
        return (centroid if toward else away), toward, ("work" if toward else "drift")
    return rob.pos.copy(), False, "still"   # neither: active stillness


def p_classical(tick, rob, room):
    """Bivalent underneath; superposition collapses probabilistically near threshold."""
    s = room.spill()
    p = 1.0 / (1.0 + np.exp(-(s - 13.0) / 2.0))
    if rob.rng.random() < p:  # collapse to 'gather'
        d = np.linalg.norm(room.fluid - rob.pos, axis=1)
        tgt = room.fluid[np.argpartition(d, 15)[:15]].mean(axis=0)
        return tgt, True, "work"
    tgt = rob.pos + np.array([10 * np.sin(tick / 9.0), 10 * np.cos(tick / 14.0)])
    return clamp(tgt), False, "dance"


def p_process(tick, rob, room):
    """No goal state. Moves toward novelty; prehends whatever it touches."""
    dirs = np.array([[np.cos(a), np.sin(a)] for a in np.linspace(0, 2 * np.pi, 8, endpoint=False)])
    best, bests = dirs[0], -1e9
    for d_ in dirs:
        ahead = clamp(rob.pos + 7 * d_)
        i = int(np.clip(ahead[0] / 4, 0, 24))
        j = int(np.clip(ahead[1] / 4, 0, 24))
        novelty = 1.0 - min(rob.visit[i, j] / 8.0, 1.0)
        s = novelty + rob.rng.normal(0, 0.05)
        if s > bests:
            bests, best = s, d_
    return clamp(rob.pos + 6 * best), True, "drift"


# ---------------- run ----------------

def run(name, policy, seed):
    room = Room(seed=123)  # identical spill for all three floors
    rob = Robot(name, policy, seed)
    spills = np.empty(T)
    for tick in range(T):
        room.seep_and_diffuse()
        rob.step(tick, room)
        spills[tick] = room.spill()
    return room, rob, spills


results = {}
for name, policy, seed in [("tetralemma", p_tetralemma, 11),
                           ("classical", p_classical, 22),
                           ("process", p_process, 33)]:
    results[name] = run(name, policy, seed)

# ---------------- report ----------------
print(f"{'robot':<11}{'day':<4}{'spill':<7}{'dist':<8}" +
      "".join(f"{m:<7}" for m in MODES) + f"{'energy':<7}")
for name, (room, rob, spills) in results.items():
    modes = np.array([m for m, _, _ in rob.log])
    speeds = np.array([s for _, s, _ in rob.log])
    energies = np.array([e for _, _, e in rob.log])
    for d in range(DAYS):
        sl = slice(d * TICKS_PER_DAY, (d + 1) * TICKS_PER_DAY)
        frac = [(modes[sl] == m).mean() for m in MODES]
        print(f"{name:<11}{d+1:<4}{spills[(d+1)*TICKS_PER_DAY-1]:<7.1f}"
              f"{speeds[sl].sum():<8.0f}" +
              "".join(f"{f:<7.2f}" for f in frac) + f"{energies[(d+1)*TICKS_PER_DAY-1]:<7.0f}")
    ent = -(lambda p: np.sum(p * np.log(p + 1e-12)))(
        np.array([(modes == m).mean() for m in MODES]))
    print(f"  -> mode entropy: {ent:.2f} bits, particles swept: {rob.swept_total}, "
          f"final spill: {spills[-1]:.1f}")

# ---------------- plots ----------------
days_x = np.arange(T) / TICKS_PER_DAY
fig, ax = plt.subplots(figsize=(9, 4.5))
for name, (_, _, spills) in results.items():
    ax.plot(days_x, spills, label=name, lw=1.6)
ax.set_xlabel("day")
ax.set_ylabel("mean fluid distance from center")
ax.set_title("Containment over five days (lower = more contained)")
ax.legend()
fig.tight_layout()
fig.savefig(f"{OUT}/spill_over_time.png", dpi=110)

fig, axes = plt.subplots(1, 3, figsize=(12, 4), sharey=True)
colors = {"work": "#c0392b", "dance": "#2980b9", "drift": "#7f8c8d", "still": "#ecf0f1"}
for ax, (name, (_, rob, _)) in zip(axes, results.items()):
    modes = np.array([m for m, _, _ in rob.log])
    data = np.array([[(modes[d*TICKS_PER_DAY:(d+1)*TICKS_PER_DAY] == m).mean()
                      for m in MODES] for d in range(DAYS)])
    bottom = np.zeros(DAYS)
    for j, m in enumerate(MODES):
        ax.bar(range(1, DAYS + 1), data[:, j], bottom=bottom, label=m, color=colors[m])
        bottom += data[:, j]
    ax.set_title(name)
    ax.set_xlabel("day")
    ax.set_ylim(0, 1)
axes[0].set_ylabel("fraction of time")
axes[0].legend(loc="upper left", fontsize=8)
fig.suptitle("What each robot did with its time")
fig.tight_layout()
fig.savefig(f"{OUT}/activity_breakdown.png", dpi=110)

fig, axes = plt.subplots(3, 3, figsize=(11, 11))
snap_days = [1, 3, 5]
for i, (name, (room, rob, _)) in enumerate(results.items()):
    trail = np.array(rob.trail)
    for j, d in enumerate(snap_days):
        ax = axes[i, j]
        # reconstruct fluid approx: use final fluid positions is wrong; instead re-run not needed:
        # we plot the final fluid state for all snapshots would mislead; so store snapshots during run.
        ax.set_title(f"{name}, day {d}")
        ax.set_xlim(0, 100); ax.set_ylim(0, 100)
        ax.set_xticks([]); ax.set_yticks([])
fig.tight_layout()
# snapshots need fluid history: re-run cheaply storing snapshots
def run_with_snaps(policy, seed, snap_ticks):
    room = Room(seed=123)
    rob = Robot("x", policy, seed)
    snaps = {}
    for tick in range(T):
        room.seep_and_diffuse()
        rob.step(tick, room)
        if tick in snap_ticks:
            snaps[tick] = (room.fluid.copy(), np.array(rob.trail[-TICKS_PER_DAY:]), rob.pos.copy())
    return snaps

snap_ticks = {d * TICKS_PER_DAY - 1: d for d in snap_days}
policies = {"tetralemma": (p_tetralemma, 11), "classical": (p_classical, 22), "process": (p_process, 33)}
for i, name in enumerate(["tetralemma", "classical", "process"]):
    pol, seed = policies[name]
    snaps = run_with_snaps(pol, seed, snap_ticks)
    for j, d in enumerate(snap_days):
        tick = d * TICKS_PER_DAY - 1
        fluid, trail, pos = snaps[tick]
        ax = axes[i, j]
        ax.scatter(fluid[:, 0], fluid[:, 1], s=3, c="#c0392b", alpha=0.45)
        ax.plot(trail[:, 0], trail[:, 1], c="black", lw=0.7, alpha=0.8)
        ax.plot(pos[0], pos[1], "ko", ms=7)
        ax.plot(CENTER[0], CENTER[1], "k+", ms=10, mew=1.5)
fig.savefig(f"{OUT}/snapshots.png", dpi=110)
print("saved plots to", OUT)
