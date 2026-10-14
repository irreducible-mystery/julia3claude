# Coalition Bargaining — 3-player "both" game

The purest coopetition game: any 2 of 3 players may form a coalition to claim
a pot, but they must agree on the split. **Cooperate** within the coalition;
**compete** over membership and splits.

Part of a four-regime exploration (cooperation / competition / both / neither),
starting with "both" as the richest regime. Three players is the smallest N
with qualitatively new phenomena: coalitions, exclusion, kingmaking.

## Protocol

Each round:
1. Proposer rotates 1 → 2 → 3 → 1 …
2. Proposer chooses a partner and offers `(keep, give)` with `keep + give = pot`.
3. Partner accepts or rejects.
4. Accept → payoffs assigned, excluded player gets 0. Reject → everyone gets 0.

No counter-offers within a round (ultimatum-style). The excluded player's only
agency is *across* rounds: reputation, retaliation, being someone worth inviting.

## Strategies

| Agent | Offers | Accepts if | Notes |
|---|---|---|---|
| Random | random split, random partner | give ≥ 10% | baseline noise |
| Fair | 50/50 to least-included partner | give ≥ 40% | inclusion-aware |
| Greedy | 80/20, random partner | give ≥ 60% | |
| Grudger(5) | 50/50, avoids grudged partners | give ≥ 40% (≥ 70% if proposer is grudged) | grudges excluders for 5 rounds |

## Run

```sh
julia coalition_bargaining.jl [--rounds N] [--pot V] [--seed S] [--verbose]
```

Runs a full round-robin (4³ = 64 matchups), prints a payoff table, writes
`results.csv`, then checks pre-registered predictions. Exit code 0 iff all hold.
All randomness flows through a seeded `MersenneTwister`; per-matchup seeds are
derived deterministically from the matchup index (`hash()` is not
session-stable, so we don't use it).

## Pre-registered predictions

1. **all-Fair → near-equal payoffs.** Offers are always 50/50 and always
   accepted (threshold 40%); least-inclusion partner choice keeps inclusion
   balanced. Predicted: payoff spread ≤ 5% of total distributed.
2. **all-Greedy → total 0.** Every offer is 80/20; acceptance needs ≥ 60%.
   Everything rejected, every round. Exact 0, no randomness involved.
3. **Fair/Fair/Greedy → greedy gets exactly 0.** Greedy rejects Fair's 50s
   (needs ≥ 60) and its own 80/20 offers are rejected by Fair (needs ≥ 40).
   Frozen out by its own thresholds — a clean demonstration that in
   coopetition, *who you are determines whether you're invited*.
4. **all-Random → mean ≈ 30/player/round.** Derivation: keep ~ Uniform{0..100},
   partner accepts iff keep ≤ 90 (give ≥ 10). P(accept) = 91/101 ≈ 0.901.
   E[keep|accept] = 45, E[give|accept] = 55. Per round: proposer ≈ 40.5,
   partner ≈ 49.5, excluded 0. Rotation + random partner choice:
   E[payoff] = (1/3)(40.5) + (1/3)(49.5) = **30.0**. Predicted band [25, 35].

## Observables beyond the predictions

- **Inclusion rates**: who gets frozen out, and does it persist?
- **Coalition stability**: does the same pair repeat, or do alliances rotate?
- **Proposer advantage**: rotating proposer isn't neutral — measure it.
- **Grudger dynamics**: do grudges stabilize fair coalitions or fragment them?

## Next variants (not yet built)

- Alternating counter-offers within a round (Rubinstein-style).
- Excluded player can bribe / make side offers.
- Winners can renege (then: does anyone ever accept?).
- Then: the other three regimes — 3-player stag hunt (cooperation),
  3-player Kuhn poker (competition, watch for kingmaking), uncoupled
  foragers with dialable interference (neither).
