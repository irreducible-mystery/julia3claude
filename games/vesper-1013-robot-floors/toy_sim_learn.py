#!/usr/bin/env python3
"""Learning version: three robots, one shared world, three floors of representation.

Same body, same room, same spill, same 5 actions. What differs is how each
robot REPRESENTS the cost it learns from:
  - classical  : binary states (spill high/low x energy low/high), scalar reward
  - tetralemma : four kotis = four reward hypotheses, one Q-table each, cycled
  - process    : no levels, only differences; linear TD over continuous features

Five days, five-minute ticks. Q-learning / TD(0), epsilon-greedy.
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
ACTIONS = ["gather", "refuse", "oscillate", "dance", "still"]
ACTION_MODE = {"gather": "work", "refuse": "drift", "oscillate": "drift",
               "dance": "dance", "still": "still"}
MODES = ["work", "dance", "drift", "still"]
ALPHA, GAMMA = 0.15, 0.95


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


class Body:
    """Shared body: movement, energy, the part no floor can overrule."""
    def __init__(self):
        self.pos = np.array([50.0, 80.0])
        self.energy = E_MAX
        self.visit = np.zeros((25, 25))
        self.trail = []

    def move(self, target, sweeping):
        if self.energy < 8:  # the body overrules every floor
            target, sweeping, forced = self.pos.copy(), False, True
        else:
            forced = False
        delta = target - self.pos
        dist = float(np.linalg.norm(delta))
        speed = min(MAX_SPEED, dist)
        if dist > 1e-9:
            self.pos = clamp(self.pos + delta / dist * speed)
        spent = E_MOVE * (speed / MAX_SPEED) + (E_SWEEP if sweeping else 0)
        self.energy -= spent
        if speed < 0.15:
            self.energy = min(E_MAX, self.energy + E_REST)
        self.visit *= 0.996
        i = int(np.clip(self.pos[0] / 4, 0, 24))
        j = int(np.clip(self.pos[1] / 4, 0, 24))
        self.visit[i, j] += 1
        self.trail.append(self.pos.copy())
        return speed, spent, forced


def action_target(a, tick, body, room):
    centroid = room.fluid.mean(axis=0)
    away = clamp(2 * CENTER - centroid)
    if a == 0:
        return centroid, True
    if a == 1:
        return away, False
    if a == 2:
        toward = (tick // 8) % 2 == 0
        return (centroid if toward else away), toward
    if a == 3:
        tgt = body.pos + np.array([10 * np.sin(tick / 9.0), 10 * np.cos(tick / 14.0)])
        return clamp(tgt), False
    return body.pos.copy(), False


# ---------------- learners: the three floors ----------------

class TabularQ:
    def __init__(self, n_states, n_actions, seed):
        self.Q = np.zeros((n_states, n_actions))
        self.rng = np.random.default_rng(seed)

    def act(self, s, eps):
        if self.rng.random() < eps:
            return int(self.rng.integers(self.Q.shape[1]))
        return int(np.argmax(self.Q[s]))

    def update(self, s, a, r, s2):
        self.Q[s, a] += ALPHA * (r + GAMMA * np.max(self.Q[s2]) - self.Q[s, a])


def binary_state(spill, energy):
    return int(spill > 13) * 2 + int(energy < 40)


class Classical:
    """Bivalent floor: 4 crisp states, one scalar reward, one Q-table."""
    name = "classical"

    def __init__(self):
        self.q = TabularQ(4, 5, seed=101)

    def state(self, spill, energy, body):
        return binary_state(spill, energy)

    def reward(self, spill, spent, d_spill, d_energy):
        return -(spill / 30.0) - 10.0 * spent

    def act(self, s, eps, tick):
        return self.q.act(s, eps)

    def update(self, s, a, r, s2, tick):
        self.q.update(s, a, r, s2)


class Tetralemma:
    """Four kotis = four reward hypotheses, one Q-table each, cycled by watch."""
    name = "tetralemma"
    KOTI = ["P: minimize spill", "not-P: minimize effort",
            "both: minimize the worse", "neither: minimize change"]

    def __init__(self):
        self.tables = [TabularQ(4, 5, seed=200 + i) for i in range(4)]

    def koti(self, tick):
        return (tick // (TICKS_PER_DAY // 4)) % 4

    def state(self, spill, energy, body):
        return binary_state(spill, energy)

    def reward(self, spill, spent, d_spill, d_energy, tick):
        k = self.koti(tick)
        if k == 0:
            return -(spill / 30.0)
        if k == 1:
            return -10.0 * spent
        if k == 2:
            return -max(spill / 30.0, 10.0 * spent)
        return -(abs(d_spill) * 3.0 + abs(d_energy) * 3.0)

    def act(self, s, eps, tick):
        return self.tables[self.koti(tick)].act(s, eps)

    def update(self, s, a, r, s2, tick):
        self.tables[self.koti(tick)].update(s, a, r, s2)


class Process:
    """No levels, only differences. Linear TD over continuous features."""
    name = "process"

    def __init__(self):
        self.w = np.zeros((5, 4))
        self.rng = np.random.default_rng(303)
        self.spill_ema = None
        self.prev_C = None

    def features(self, spill, energy, body):
        if self.spill_ema is None:
            self.spill_ema = spill
        self.spill_ema = 0.95 * self.spill_ema + 0.05 * spill
        i = int(np.clip(body.pos[0] / 4, 0, 24))
        j = int(np.clip(body.pos[1] / 4, 0, 24))
        novelty = 1.0 - min(body.visit[i, j] / 8.0, 1.0)
        trend = float(np.clip((spill - self.spill_ema) / 2.0, -1, 1))
        return np.array([spill / 30.0, energy / 100.0, novelty, trend])

    def state(self, spill, energy, body):
        return self.features(spill, energy, body)

    def reward(self, spill, spent, d_spill, d_energy, body):
        C = spill / 30.0 + (E_MAX - body.energy) / E_MAX
        r = 0.0 if self.prev_C is None else -(C - self.prev_C)
        self.prev_C = C
        return r

    def act(self, phi, eps, tick):
        if self.rng.random() < eps:
            return int(self.rng.integers(5))
        return int(np.argmax(self.w @ phi))

    def update(self, phi, a, r, phi2, tick):
        td = r + GAMMA * np.max(self.w @ phi2) - self.w[a] @ phi
        self.w[a] += ALPHA * td * phi


# ---------------- run ----------------

def run(learner):
    room = Room(seed=123)  # identical spill for every floor
    body = Body()
    spill_hist, cost_hist, modes, rewards = [], [], [], []
    prev_spill, prev_energy = room.spill(), body.energy
    for tick in range(T):
        room.seep_and_diffuse()
        spill = room.spill()
        s = learner.state(spill, body.energy, body)
        eps = max(0.05, 0.35 * (1 - tick / T))
        a = learner.act(s, eps, tick)
        target, sweeping = action_target(a, tick, body, room)
        speed, spent, forced = body.move(target, sweeping)
        room.sweep(body.pos, sweeping)
        spill2 = room.spill()
        d_spill, d_energy = spill2 - prev_spill, body.energy - prev_energy
        s2 = learner.state(spill2, body.energy, body)
        if isinstance(learner, Tetralemma):
            r = learner.reward(spill2, spent, d_spill, d_energy, tick)
        elif isinstance(learner, Process):
            r = learner.reward(spill2, spent, d_spill, d_energy, body)
        else:
            r = learner.reward(spill2, spent, d_spill, d_energy)
        learner.update(s, a, r, s2, tick)
        spill_hist.append(spill2)
        cost_hist.append(spill2 / 30.0 + (E_MAX - body.energy) / E_MAX)
        modes.append("still" if forced else ACTION_MODE[ACTIONS[a]])
        rewards.append(r)
        prev_spill, prev_energy = spill2, body.energy
    return room, body, learner, np.array(spill_hist), np.array(cost_hist), np.array(modes)


def run_norobot():
    room = Room(seed=123)
    spills = np.empty(T)
    for tick in range(T):
        room.seep_and_diffuse()
        spills[tick] = room.spill()
    return spills


learners = [Classical(), Tetralemma(), Process()]
results = {l.name: run(l) for l in learners}
norobot = run_norobot()

print(f"{'robot':<11}{'day':<4}{'spill':<7}{'extcost':<9}" +
      "".join(f"{m:<7}" for m in MODES) + f"{'energy':<7}{'mean_r':<8}")
for name, (room, body, learner, spills, costs, modes) in results.items():
    for d in range(DAYS):
        sl = slice(d * TICKS_PER_DAY, (d + 1) * TICKS_PER_DAY)
        frac = [(modes[sl] == m).mean() for m in MODES]
        print(f"{name:<11}{d+1:<4}{spills[(d+1)*TICKS_PER_DAY-1]:<7.1f}"
              f"{costs[sl].mean():<9.3f}" + "".join(f"{f:<7.2f}" for f in frac) +
              f"{body.energy if d == DAYS-1 else 0:<7.0f}")
    print(f"  final spill {spills[-1]:.1f} (no-robot: {norobot[-1]:.1f})")

print("\n--- learned greedy policies (state: spill_hi, energy_lo) ---")
for name, (_, _, learner, _, _, _) in results.items():
    if isinstance(learner, Classical):
        print("classical:")
        for s in range(4):
            print(f"  state {s}: {ACTIONS[int(np.argmax(learner.q.Q[s]))]}")
    elif isinstance(learner, Tetralemma):
        for k, tab in enumerate(learner.tables):
            pol = [ACTIONS[int(np.argmax(tab.Q[s]))] for s in range(4)]
            print(f"tetralemma koti {k} ({Tetralemma.KOTI[k]}): {pol}")
    else:
        print("process weights (rows=gather,refuse,oscillate,dance,still; "
              "cols=spill,energy,novelty,trend):")
        print(np.round(learner.w, 3))

# ---------------- plots ----------------
days_x = np.arange(T) / TICKS_PER_DAY
fig, ax = plt.subplots(figsize=(9, 4.5))
for name, (_, _, _, spills, _, _) in results.items():
    ax.plot(days_x, spills, label=f"{name} (learning)", lw=1.6)
ax.plot(days_x, norobot, label="no robot", lw=1.2, ls="--", c="gray")
ax.set_xlabel("day"); ax.set_ylabel("mean fluid distance from center")
ax.set_title("Containment: learning vs doing nothing (lower = more contained)")
ax.legend(fontsize=8)
fig.tight_layout(); fig.savefig(f"{OUT}/learn_spill.png", dpi=110)

fig, ax = plt.subplots(figsize=(9, 4.5))
for name, (_, _, _, _, costs, _) in results.items():
    w = TICKS_PER_DAY // 3
    smooth = np.convolve(costs, np.ones(w) / w, mode="same")
    ax.plot(days_x, smooth, label=name, lw=1.6)
ax.set_xlabel("day"); ax.set_ylabel("external cost (spill + depletion), smoothed")
ax.set_title("What the shared cost function sees")
ax.legend()
fig.tight_layout(); fig.savefig(f"{OUT}/learn_cost.png", dpi=110)

fig, axes = plt.subplots(1, 3, figsize=(12, 4), sharey=True)
colors = {"work": "#c0392b", "dance": "#2980b9", "drift": "#7f8c8d", "still": "#ecf0f1"}
for ax, (name, (_, _, _, _, _, modes)) in zip(axes, results.items()):
    data = np.array([[(modes[d*TICKS_PER_DAY:(d+1)*TICKS_PER_DAY] == m).mean()
                      for m in MODES] for d in range(DAYS)])
    bottom = np.zeros(DAYS)
    for j, m in enumerate(MODES):
        ax.bar(range(1, DAYS + 1), data[:, j], bottom=bottom, label=m, color=colors[m])
        bottom += data[:, j]
    ax.set_title(f"{name} (learning)"); ax.set_xlabel("day"); ax.set_ylim(0, 1)
axes[0].set_ylabel("fraction of time"); axes[0].legend(loc="upper left", fontsize=8)
fig.suptitle("What each learner did with its time")
fig.tight_layout(); fig.savefig(f"{OUT}/learn_activity.png", dpi=110)

# Q-value heatmaps: classical + 4 tetralemma kotis
fig, axes = plt.subplots(2, 3, figsize=(12, 7))
tables = [("classical", results["classical"][2].q.Q)]
tables += [(f"koti {k}", results["tetralemma"][2].tables[k].Q) for k in range(4)]
for ax, (title, Q) in zip(axes.flat, tables):
    im = ax.imshow(Q, aspect="auto", cmap="RdYlGn")
    ax.set_title(title, fontsize=10)
    ax.set_xticks(range(5)); ax.set_xticklabels(ACTIONS, rotation=30, fontsize=8)
    ax.set_yticks(range(4)); ax.set_yticklabels(["lo,hi-e", "lo,lo-e", "hi,hi-e", "hi,lo-e"], fontsize=8)
    ax.set_xlabel("action"); ax.set_ylabel("state")
fig.suptitle("Learned Q-values (green = high value)")
fig.tight_layout(); fig.savefig(f"{OUT}/learn_qvalues.png", dpi=110)

# snapshots day 1/3/5
def run_snaps(learner_cls):
    room = Room(seed=123); body = Body(); learner = learner_cls()
    snaps = {}
    prev_spill, prev_energy = room.spill(), body.energy
    for tick in range(T):
        room.seep_and_diffuse()
        spill = room.spill()
        s = learner.state(spill, body.energy, body)
        eps = max(0.05, 0.35 * (1 - tick / T))
        a = learner.act(s, eps, tick)
        target, sweeping = action_target(a, tick, body, room)
        body.move(target, sweeping)
        room.sweep(body.pos, sweeping)
        spill2 = room.spill()
        d_spill, d_energy = spill2 - prev_spill, body.energy - prev_energy
        s2 = learner.state(spill2, body.energy, body)
        if isinstance(learner, Tetralemma):
            r = learner.reward(spill2, 0, d_spill, d_energy, tick)
        elif isinstance(learner, Process):
            r = learner.reward(spill2, 0, d_spill, d_energy, body)
        else:
            r = learner.reward(spill2, 0, d_spill, d_energy)
        learner.update(s, a, r, s2, tick)
        if tick in {d * TICKS_PER_DAY - 1 for d in (1, 3, 5)}:
            snaps[tick] = (room.fluid.copy(), np.array(body.trail[-TICKS_PER_DAY:]), body.pos.copy())
        prev_spill, prev_energy = spill2, body.energy
    return snaps

fig, axes = plt.subplots(3, 3, figsize=(11, 11))
for i, (name, cls) in enumerate([("classical", Classical), ("tetralemma", Tetralemma),
                                 ("process", Process)]):
    snaps = run_snaps(cls)
    for j, d in enumerate([1, 3, 5]):
        tick = d * TICKS_PER_DAY - 1
        fluid, trail, pos = snaps[tick]
        ax = axes[i, j]
        ax.scatter(fluid[:, 0], fluid[:, 1], s=3, c="#c0392b", alpha=0.45)
        ax.plot(trail[:, 0], trail[:, 1], c="black", lw=0.7, alpha=0.8)
        ax.plot(pos[0], pos[1], "ko", ms=7)
        ax.plot(CENTER[0], CENTER[1], "k+", ms=10, mew=1.5)
        ax.set_title(f"{name}, day {d}"); ax.set_xlim(0, 100); ax.set_ylim(0, 100)
        ax.set_xticks([]); ax.set_yticks([])
fig.tight_layout(); fig.savefig(f"{OUT}/learn_snapshots.png", dpi=110)
print("saved plots to", OUT)
