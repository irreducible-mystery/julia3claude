# Forage-and-share — the "cooperation" corner

A 3-player common-pool resource game. Three players share one renewable
resource; each round every player chooses a harvest, then the stock regrows
logistically. No communication, no enforcement. The question: does
self-interest sustain the commons or destroy it?

This is the **cooperation** corner of the four-regime exploration
(cooperation / competition / both / neither): coalition bargaining covered
"both", the minority game covered "neither".

## Model

- Stock `R`, carrying capacity `K = 300`, regrowth rate `r = 0.3`, `T = 500` rounds.
- Each round: players harvest (desired amounts rationed proportionally if
  they exceed the stock), then `R <- R + r*R*(1 - R/K)`.
- `R < 1` is extinction — absorbing. No randomness anywhere: fully
  deterministic given the strategies.

## Strategies

| Strategy | Rule |
|---|---|
| **Greedy** | Takes the per-round cap (12), always. |
| **Fair** | Takes the textbook MSY quota `q = r*K/(4*3) = 7.5` per player. |
| **Restraint** | Takes the quota, but only while `R >= K/2`; harvests 0 below it. |
| **Grim** | Takes the quota until some round's total harvest exceeds 24 (the sustainable max 22.5); then withdraws forever. |

## Protocol

```sh
julia forage_share.jl        # Run 1: 9 matchups, pre-registered predictions, exit 0 iff all hold
julia diag_quota.jl          # diagnostic for the Run 1 failures (see below)
```

Measured 2026-10-12 (deterministic; no seed needed).

## Run 1 results

| matchup | welfare | p1 total | collapse @ round | min R |
|---|---|---|---|---|
| Fair^3 | 914.6 | 304.9 | 42 | 0.0 |
| Greedy^3 | 241.4 | 80.5 | 8 | 0.0 |
| Restraint^3 | 11227.5 | 3742.5 | — | 149.5 |
| Grim^3 | 914.6 | 304.9 | 42 | 0.0 |
| Greedy/Fair/Fair | 357.7 | 159.0 (greedy) | 15 | 0.0 |
| Greedy/Greedy/Fair | 277.1 | 105.6 | 10 | 0.0 |
| Greedy/Restraint/Restraint | 11040.0 | 6000.0 (greedy) | — | 144.8 |
| Greedy/Grim/Grim | 6015.0 | 6000.0 (greedy) | — | 144.8 |
| Fair/Fair/Restraint | 11077.5 | 3750.0 | — | 149.5 |

![stock trajectories](stock_trajectories.png)

## Pre-registered predictions — 4/7 PASS

1. **P1 — tragedy:** Greedy^3 collapses; Fair^3 never collapses. **FAIL** — Greedy^3 collapsed at round 8 as expected, but Fair^3 *also* collapsed, at round 42.
2. **P2 — sustainability premium:** welfare(Fair^3) > 10000, welfare(Greedy^3) < 2000. **FAIL** — 914.6 vs 241.4.
3. **P3 — free-rider:** in Greedy/Fair/Fair the greedy player's total (159.0) exceeds each fair player's (99.4). **PASS**.
4. **P4 — one bad apple:** Greedy/Fair/Fair collapses. **PASS** — round 15.
5. **P5 — conditional withdrawal:** Greedy/Grim/Grim never collapses. **PASS** — the grims withdraw after round 1; the lone greedy taker (12/round) cannot overexploit alone, and the stock recovers.
6. **P6 — adaptive restraint:** Greedy/Restraint/Restraint never collapses. **PASS** — restraint steps back below K/2, letting the stock recover; the commons survives a greedy player.
7. **P7 — grim among cooperators:** Grim^3 sustains with welfare >= 11000. **FAIL** — behaves as Fair^3 (trigger never fires at H = 22.5 < 24); collapses at 42.

## The failure is the finding (kept, not hidden)

The Fair quota was computed from continuous-time MSY logic: max regrowth
`r*K/4 = 22.5`, split three ways. But the simulation runs a **discrete
harvest-then-regrow map**, and in that map the quota-22.5 harvest is only
sustainable from a pre-harvest stock of exactly `R* = 172.5`. Worse, `x = 150`
(post-harvest stock) is a **double root** of `0.3*x*(1 - x/300) = 22.5` — a
knife-edge: from `R_init = 150` the stock drifts down from round 1 and
collapses at round 42.

`diag_quota.jl` confirms the mechanism (exit 0):

- **D3** — Fair^3, R_init=150, quota=7.5: collapses at 42 (reproduces Run 1).
- **D1** — Fair^3, R_init=200 (> 172.5), quota=7.5: sustains, welfare 11250.0, min R 174.4.
- **D2** — Fair^3, R_init=150, quota=6.5: sustains, welfare 9750.0, min R 150.0.

So the collapse is the quota/stock knife-edge, not a code bug — the same
moral as the edge-of-chaos work: the phenomenon is real, the signature is
method-dependent.

## What the numbers say about cooperation

- **Uncalibrated fixed rules die; feedback lives.** Fair^3 (914.6, collapse) vs
  Restraint^3 (11227.5, sustained): the *identical quota* sustains when it is
  conditioned on the stock and collapses when it isn't. The naive continuous-time
  MSY quota fails as a fixed rule in the discrete map — but D2 shows a *recalibrated*
  fixed quota (6.5) also sustains (9750.0). So: uncalibrated fixed rules die;
  feedback and recalibration live. (Wording softened 2026-10-14 per breaker caveat;
  the D2 counter-evidence was already in this README.)
- **Adaptive cooperators rescue a commons with a defector in it.**
  Greedy/Fair/Fair collapses at round 15 (357.7); Greedy/Restraint/Restraint
  sustains (11040.0). One rigid cooperator is dead weight; one adaptive
  cooperator is a backstop.
- **Withdrawal can beat participation.** Greedy/Grim/Grim (6015.0, sustained)
  vs Greedy/Fair/Fair (357.7, collapsed): refusing to feed a spoiled commons
  leaves everyone — including the defector, who keeps 6000.0 — better off
  than dutiful over-harvesting. (Whether that counts as "cooperation" is a
  question for the taxonomy, not the model.)
- **The free-rider premium is real but small consolation.** In
  Greedy/Fair/Fair the defector takes 159.0 vs 99.4 each — and then the
  commons dies at round 15. Defection wins the round and loses the game.

## Files

- `forage_share.jl` — the game, the 9 matchups, the 7 pre-registered predictions.
- `diag_quota.jl` — knife-edge diagnostic (D1/D2/D3).
- `results.csv` — per-matchup welfare, per-player totals, collapse round, min R.
- `trajectories.csv` — per-round stock for all 9 matchups.
- `stock_trajectories.png` — stock over time for the six key matchups.

## Open threads

- **Public goods with punishment** (the competition corner) is the one
  regime still unbuilt.
- A regrow-then-harvest ordering would restore the textbook MSY story and
  make the method-dependence explicit — a natural follow-up experiment.
- Nothing here has been posted to any repo; posting needs Kelly's explicit yes.
