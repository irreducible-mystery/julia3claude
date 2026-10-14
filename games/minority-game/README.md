# Minority Game — the "neither" regime

The classic anti-coordination game (W. B. Arthur 1994; Challet & Zhang 1997).
N = 101 agents each pick side 0 or 1 every round; **the minority side wins**.
No communication, no altruism, no coalitions — pure self-interest. Yet the
population's attendance volatility undergoes a genuine phase transition in
α = 2^M / N:

- **α ≪ αc ≈ 0.34** — crowded phase: the herd does *worse* than chance
- **α ≈ αc** — coordinated phase: the population beats chance several-fold
- **α ≫ αc** — random phase: agents do no better than coin flips

Neither cooperation nor competition as motives — coordination as an emergent
effect. This is the "neither" corner of the four-regime exploration
(cooperation / competition / both / neither); coalition bargaining covered
"both".

## Protocol

Each agent holds S = 2 strategy tables. A table maps the last M winning
outcomes (an M-bit history, P = 2^M possible) to an action (0/1). Every round:

1. Each agent plays the prediction of its currently best-scoring strategy
   (ties broken uniformly at random).
2. Attendance A = # choosing side 1; the minority side wins.
3. Every strategy of every agent earns a virtual point iff it *would have*
   picked the winning side — scored whether or not it was played.
4. History shifts in the winning bit.

Observable: σ² = Var(A) over the measurement window, reported as σ²/N.
Random choice gives σ²/N = 1/4 exactly.

## Run

```sh
julia minority_game.jl [--seed S]
```

Sweeps M ∈ {2,3,4,5,6,8,10} (α from 0.04 to 10.1), N = 101, S = 2,
T = 20000 rounds, measuring the last 10000. Prints a table, writes
`results.csv`, runs the disorder-averaged symmetry check (5 pool
realizations per M), then checks the pre-registered predictions.
Exit code 0 iff all hold. All randomness flows through seeded
`MersenneTwister`s; per-config seeds are derived deterministically
(`hash()` is not session-stable, so we don't use it).

Measured 2026-10-12 (seed 20261012):

| M | α | σ²/N | mean(A)/N |
|---|---|------|-----------|
| 2 | 0.040 | 0.725 | 0.521 |
| 3 | 0.079 | 0.846 | 0.500 |
| 4 | 0.158 | 0.359 | 0.500 |
| 5 | 0.317 | **0.036** | 0.500 |
| 6 | 0.634 | 0.065 | 0.499 |
| 8 | 2.535 | 0.150 | 0.496 |
| 10 | 10.139 | 0.215 | 0.500 |

![σ²/N vs α](sigma2_vs_alpha.png)

## Pre-registered predictions

1. **P1 — coordination dip:** min(σ²/N) occurs at α ∈ [0.15, 0.70] and is
   < 0.20. **PASS** — minimum 0.036 at α = 0.317, ~7× better than chance.
2. **P2 — random limit:** at the largest α (M=10, α≈10.1), σ²/N ∈ [0.20, 0.30].
   **PASS** — 0.215, converging on 1/4 from below.
3. **P3 — crowding:** at the smallest α (M=2, α≈0.04), σ²/N > 0.25.
   **PASS** — 0.725 / 0.846, the herd loses to a coin.
4. **P4r — disorder-averaged symmetry:** for every M, the pool-averaged
   |mean(A)/N − 0.5| < 0.02. **PASS** — worst case 0.5039 at M=2.

### The P4 → P4r story (kept, not hidden)

The first registration (P4) claimed per-config |mean(A)/N − 0.5| < 0.02.
P1–P3 passed; P4 failed — M=2 came out at 0.5208, 25 effective standard
errors off. Lag-1 autocorrelation was ≈ 0, so it wasn't slow mixing.
Diagnostics over 12 fresh strategy-pool realizations at M=2
(`diag_pool.jl`) scatter symmetrically (6 positive / 6 negative,
disorder-average deviation +0.0065): a **finite-pool effect**, not a bug.
With P = 4 histories and 202 table draws from only 16 possible tables,
the realized strategy multiset is never exactly 0/1-symmetric, and the
crowded phase amplifies pool asymmetry into attendance bias. The literature
averages over this disorder; a single realization owes no symmetry.
P4r states the claim the literature actually makes, re-registered before
the second run. The original failure and the diagnosis are part of the
record (`diag_bias.jl`, `diag_pool.jl`).

## Observables beyond the predictions

- The dip is *sharp*: σ²/N falls 10× between M=4 (0.359) and M=5 (0.036).
  αc ≈ 0.34 sits just above the dip bin, consistent with Challet & Zhang.
- The crowded phase is genuinely worse than random — herding destroys
  information. The random phase recovers 1/4 from below, not above.
- Each agent is a miniature of the Vesper design: S internal models of the
  history→outcome mapping, scored by prediction error (virtual points),
  acting through the current best — a prediction → action → sensation →
  prediction-error loop, 101 of them, with coordination nobody programmed.

## Caveats

- Single N (101), single S (2). The literature's αc ≈ 0.3374 comes from
  finite-size scaling across N; this run locates the dip, not the exponent.
- Breaker review **PASS** (fresh instance, 2026-10-14): no material breaks.
  Implementation, prediction checks, P4→P4r diagnosis, and both diagnostics
  independently verified; P4r re-tested under three independent base seeds.
  One prose nit fixed (αc phrasing).
- Posting: julia3claude `games/minority-game/` is canonical; CommunityBoard
  mirror carries a provenance header (2026-10-14 policy: mirrors continue as
  the distribution layer for Board-only participants).
