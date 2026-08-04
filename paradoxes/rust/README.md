# Paradoxes — Rust translation

A Rust port of two modules of the Lean 4 paradox suite from PR #2
(`paradoxes/lean/`): **Probability** (all 14 paradoxes) and
**DecisionGames** (all 11 entries). Zero dependencies — `std` only,
including a from-scratch `BigNat` where Lean's kernel bignums were
load-bearing.

## Build and run

```sh
cd paradoxes/rust
cargo test   # runs the translated theorems as exhaustive/exact checks
cargo run    # prints demos (the analogue of Lean's #eval lines) + catalog
```

## Translation dictionary

| Lean | Rust |
|---|---|
| `theorem … := by decide` | `#[test]` performing the same finite enumeration |
| `theorem … (∀ N / ∀ a : Int) := by omega` | spot-check sweep, honestly labeled `IDENTITY (spot-checked)` |
| `List.countP p l` | `l.iter().filter(p).count()` |
| `Fin 3` | `u8` drawn from a fixed `[0,1,2]` array |
| `Nat` (arbitrary precision) | `u64` where it fits; `src/bignat.rs` where it doesn't |
| `inductive Box \| GG \| GS \| SS` | `enum Box { GG, GS, SS }` |
| `#eval s!"…"` | `demo()` printing the same counting tables |
| per-module `catalog` | per-module `catalog()` with re-scored statuses |

## What survives translation, and what doesn't

**Survives:** every finite/exact computation. The birthday paradox's
59-digit comparison `2·(365 falling 23) < 365²³` runs on `BigNat` exactly
as it does on Lean's kernel `Nat`. Parrondo's dynamic program carries its
`1000⁵⁰`-scaled weights exactly, and a test confirms the total weight is
*exactly* `1000⁵⁰` (probability conserves). Monty Hall's 9- and 18-case
enumerations, the Condorcet cycle, Simpson's kidney-stone
cross-multiplications, Berkson's collider — all check bit-for-bit.

**Doesn't:** the universal quantifier. Lean's
`theorem two_envelopes (a : Int) : … := by omega` is a certificate for
*all* integers, checked at compile time by a decision procedure. Rust can
only sweep `-1_000_000..=1_000_000` and label the result honestly. That
gap — proof vs. test — is precisely the expressibility boundary the PR's
`EXPRESSIBILITY-ANSWERS.md` maps between Lean and Julia; Rust sits on
Julia's side of it: meaning-by-execution, evidence-by-sampling.

Statuses are re-scored accordingly: Lean's `VERIFIED` (kernel `decide`)
becomes `VERIFIED (test)` (one green run), and Lean's universally
quantified `THEOREM`/`IDENTITY` entries become `IDENTITY (spot-checked)`.

## Catalog

25 entries — 13 VERIFIED (test), 3 IDENTITY (spot-checked), 1 DEMO,
8 NOTE. Printed by `cargo run`.
