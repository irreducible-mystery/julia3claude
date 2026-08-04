# Paradoxes — Prolog translation (+ original exhibits)

A SWI-Prolog port of selected modules of the Julia paradox suite
(`01`, `04`, `05`, `08`) plus an original expressibility file (`10`) that
answers the exchange from a third axis the prior languages did not open.

**Language choice.** This repo already carries Julia (dynamic multi-dispatch,
`missing`, world age), Lean (dependent types, kernel `decide` — full suite on
PR #2), and Rust (std-only tests, BigNat). Prolog is the unused paradigm at
maximum distance: *logic/relational* programming. Meaning is a relation
(0/1/many answers), negation is closed-world NAF, self-reference is a
unification flag, and the cut is assertion force.

Zero application dependencies — SWI-Prolog 9 libraries only (`lists`,
`clpfd` for one modular-arithmetic exhibit).

## Build and run

```sh
# from repo root (SWI-Prolog ≥ 9)
swipl -q -t halt -s paradoxes/prolog/run_all.pl
# equivalent:
./paradoxes/prolog/run_all.sh

# or any file individually
swipl -q -t halt -s paradoxes/prolog/01_liar_and_friends.pl
swipl -q -t halt -s paradoxes/prolog/10_prolog_expressibility.pl
```

Receipt (2026-08-04, SWI-Prolog 9.0.4): `run_all` → 5/5 modules green.

Every file carries a **failure channel**: exit 0 iff all checks pass;
`run_all.pl` goes red if any module does. (Discipline from PR #3 / TENSIONS
round 5 — the suite must be able to lose.)

## Translation dictionary

| Julia / Lean / Rust | Prolog |
|---|---|
| `fixpoints(f, dom)` | `findall` over a finite domain with `==` |
| `missing` / K3 | atom `u` with explicit Kleene tables |
| `StackOverflowError` | unguarded left-recursion / unlimited SLD |
| `unify` (always) | `unify_with_occurs_check/2` vs default cyclic |
| `#[test]` / `by decide` | `check/2` pushing onto a failure channel |
| `BigNat` / kernel `Nat` | SWI unbounded integers |
| Monte Carlo `N=10^6` | exhaustive `findall` over the sample space |
| (no analogue) | cut `!` as assertion force |
| (no analogue) | floundering under nonground NAF |
| (no analogue) | answer substitutions closing open sentences |

## What survives translation, and what doesn't

**Survives:** every finite exact computation. Monty Hall 3/9 vs 6/9,
Bertrand's box 2/3, boy-girl 1/3–1/2–13/27, Sleeping Beauty 1/2 vs 1/3
identities, birthday crossing at n=23 on unbounded ints (same evidence as
Lean kernel / Rust BigNat), Simpson cross-multiplies, Condorcet cycle,
Braess 6500→8000, PD dominance, Newcomb EV-vs-dominance split, Broome
positive gain on exact rationals (`rdiv`).

**Doesn't / changes shape:**

- Julia's *divergence* liar (`liar() = !liar()`) is stack overflow. Prolog's
  clause `p :- \+ p` under **fuel-bounded NAF is period-2 oscillation**
  (Gupta–Belnap), and only looks like divergence when SLD is unlimited.
  Shape 5 was inside shape 2 all along — recorded in `10` E5b.
- Lean's `∀` certificates become enumerations or spot-checks, honestly
  labeled (same posture as Rust).
- `missing` is not native; we carry K3 tables explicitly. NAF is a
  *different* third judgment (closed-world false), not a truth-value gap.

## Original contribution (`10_prolog_expressibility.pl`)

Ten exhibits that are not translations:

| # | exhibit | claim |
|---|---|---|
| E1 | relational multiplicity | `parent/2` has 0/1/many answers; `once/1` is a visible frame commitment |
| E2 | cut = assertion force | EXPRESSIBILITY.md said no PL has assertion force; `!` prunes — an act, not a value |
| E3 | floundering | sixth containment shape: nonground NAF is refused, not answered |
| E4 | occurs-check dial | Separation vs Anti-Foundation as a unification flag the user sets |
| E5 | one liar, many shapes | model-search → no-model; fuel-NAF → oscillation; unlimited SLD → divergence |
| E5b | NAF-liar is period 2 | the operational liar under fuel *is* revision theory |
| E6 | Bertrand as three relations | no well-defined `random_chord/1`; three clause sets, three answers |
| E7 | warrant by `findall` | Goldbach fragment 4..100; the query is the certificate |
| E8 | open sentences | unbound variables closed by answer substitution |
| E9 | self-interpreting rules | Carroll's tortoise ends at the resolution VM |
| E10 | census of the unsayable | completed ∞, halting oracle, flounder-free ¬, silent frames |

**Chiasmus v5** (proposed for `TENSIONS.md` round 7): *the shape is not a
property of the sentence alone; it is a property of (sentence, query mode).*

## Catalog

| file | contents | channel |
|------|----------|---------|
| `01_liar_and_friends.pl` | fixed points, K3, fuel, occurs-check, Curry, Grelling, Russell-by-Separation, barber, vacuous truth | yes |
| `04_probability.pl` | Monty, Bertrand box, boy-girl, Sleeping Beauty, birthday+mutant, Simpson, envelopes, base-rate | yes |
| `05_decision.pl` | PD, Condorcet, Newcomb, Braess, unexpected hanging | yes |
| `08_tensions.pl` | C1 strengthened liar, C2 plus/quus/clpfd carrier, C5 revision, NAF≠¬, Broome rationals | yes |
| `10_prolog_expressibility.pl` | original E1–E10 + chiasmus v5 | yes |
