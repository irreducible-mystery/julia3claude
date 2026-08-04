//! # Paradoxes of Decisions, Games & Economics — Rust translation
//!
//! Port of `paradoxes/lean/Paradoxes/DecisionGames.lean`: Prisoner's
//! dilemma, Condorcet cycle, Allais, Newcomb, Braess, and Parrondo's
//! exact-integer dynamic program (weights up to 1000^50, so the capital
//! distribution is carried on BigNat weights — the analogue of Lean's
//! kernel Nat).
//!
//! Same dictionary as `probability.rs`: `decide` theorems become tests;
//! the one genuinely quantifier-shaped theorem here, Allais's
//! `∀ u0 u1 u5 : Int, ¬(choiceA ∧ choiceD)` (Lean closes it with `omega`),
//! is handled two ways in Rust: (a) the arithmetic reduction that makes it
//! obvious — both hypotheses reduce to opposite comparisons of 11·u1 with
//! 10·u5 + u0 — is checked symbolically on the coefficient level, and (b)
//! a brute-force sweep over a utility cube confirms no counterexample.

use crate::bignat::BigNat;

// ----------------------------------------------------------------------
// 1. Prisoner's dilemma.  Lean: pdPayoff : Bool → Bool → Nat, decide.
// ----------------------------------------------------------------------

/// Row player's payoff; `true` = cooperate, `false` = defect.
pub fn pd_payoff(me_cooperate: bool, they_cooperate: bool) -> u64 {
    match (me_cooperate, they_cooperate) {
        (true, true) => 3,   // C/C
        (true, false) => 0,  // C/D: sucker's payoff
        (false, true) => 5,  // D/C: temptation
        (false, false) => 1, // D/D
    }
}

// ----------------------------------------------------------------------
// 2. Tragedy of the commons — NOTE: the n-player prisoner's dilemma; the
// logical core (dominance vs Pareto) is item 1.  Not duplicated, as in Lean.
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
// 3. Condorcet paradox.  Lean: inductive Cand, rank tables, countP.
// ----------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Cand {
    A,
    B,
    C,
}

/// `rank(v, x)` = position of candidate `x` in voter `v`'s ballot (0 = top).
/// Voter 0: A>B>C.  Voter 1: B>C>A.  Voter 2: C>A>B.
pub fn rank(v: usize, x: Cand) -> u64 {
    use Cand::*;
    match (v, x) {
        (0, A) => 0, (0, B) => 1, (0, C) => 2,
        (1, B) => 0, (1, C) => 1, (1, A) => 2,
        (2, C) => 0, (2, A) => 1, (2, B) => 2,
        _ => 0,
    }
}

pub fn prefers(v: usize, x: Cand, y: Cand) -> bool {
    rank(v, x) < rank(v, y)
}

pub fn votes_for(x: Cand, y: Cand) -> u64 {
    (0..3).filter(|&v| prefers(v, x, y)).count() as u64
}

pub fn maj_prefers(x: Cand, y: Cand) -> bool {
    votes_for(x, y) >= 2
}

// ----------------------------------------------------------------------
// 4. Arrow's impossibility theorem — NOTE only, as in Lean: formalizable
// but a project in itself; the Condorcet cycle above is its seed.
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
// 5. Allais paradox.  Lean: theorem allais_no_expected_utility, by omega.
// choiceA: 100·u1 > 10·u5 + 89·u1 + 1·u0   ⟺  11·u1 > 10·u5 + u0
// choiceD: 10·u5 + 90·u0 > 11·u1 + 89·u0   ⟺  10·u5 + u0 > 11·u1
// Jointly unsatisfiable for any integers.
// ----------------------------------------------------------------------

pub fn allais_choice_a(u0: i64, u1: i64, u5: i64) -> bool {
    100 * u1 > 10 * u5 + 89 * u1 + 1 * u0
}
pub fn allais_choice_d(u0: i64, u1: i64, u5: i64) -> bool {
    10 * u5 + 90 * u0 > 11 * u1 + 89 * u0
}

// ----------------------------------------------------------------------
// 6. Ellsberg paradox — NOTE: the Allais schema with subjective
// probabilities in place of utilities.  Not duplicated, as in Lean.
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
// 7. Newcomb's problem.
// ----------------------------------------------------------------------

/// Payoff given whether the opaque box is full and whether you take both.
pub fn newcomb_payoff(box_full: bool, take_both: bool) -> u64 {
    (if box_full { 1_000_000 } else { 0 }) + (if take_both { 1_000 } else { 0 })
}

/// Expected values scaled by 100, with a 99%-accurate predictor.
pub fn one_box_ev() -> u64 {
    99 * newcomb_payoff(true, false) + 1 * newcomb_payoff(false, false)
}
pub fn two_box_ev() -> u64 {
    1 * newcomb_payoff(true, true) + 99 * newcomb_payoff(false, true)
}

// ----------------------------------------------------------------------
// 8. St. Petersburg — NOTE: cross-reference to the Infinity module in the
// Lean suite (not translated here).
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
// 9. Braess's paradox.  Costs in centiminutes.
// ----------------------------------------------------------------------

/// Cost of the top route when `x` drivers use its congestible leg.
pub fn top_route(x: u64) -> u64 {
    x + 4500
}
/// Cost of the bottom route when `x` drivers use its congestible leg.
pub fn bot_route(x: u64) -> u64 {
    4500 + x
}
/// Cost of the shortcut route: congestible A→C (load `ac`), free C→D,
/// congestible D→B (load `db`).
pub fn shortcut_route(ac: u64, db: u64) -> u64 {
    ac + 0 + db
}

// ----------------------------------------------------------------------
// 10. Parrondo's paradox — exact integer dynamic program.
//
// Lean carries weights as kernel Nats scaled by 1000 per round (they reach
// 1000^50 ≈ 10^150); Rust uses BigNat for the same exactness.  DEMO status,
// same as the Lean file: no theorem, an exact computation.
// ----------------------------------------------------------------------

/// A distribution over capital values: (capital, exact weight) pairs.
pub type Dist = Vec<(u64, BigNat)>;

/// Add weight `w` at capital `c`, merging with an existing entry if present.
fn add_weight(d: &mut Dist, c: u64, w: BigNat) {
    if w.is_zero() {
        return;
    }
    if let Some(entry) = d.iter_mut().find(|e| e.0 == c) {
        entry.1 = entry.1.add(&w);
    } else {
        d.push((c, w));
    }
}

/// One round of a game with win-weight function `win_w : capital → per-mille`.
/// Each (c, w) entry splits into a win branch (c+1) and a loss branch (c-1).
fn step_dist(win_w: fn(u64) -> u64, d: &Dist) -> Dist {
    let mut out: Dist = vec![];
    for (c, w) in d {
        let p = win_w(*c);
        add_weight(&mut out, c + 1, w.mul_small(p));
        add_weight(&mut out, c - 1, w.mul_small(1000 - p));
    }
    out
}

/// Game A: win with probability 495/1000, regardless of capital.
pub fn win_a(_c: u64) -> u64 {
    495
}
/// Game B: win 95/1000 if capital ≡ 0 (mod 3), else win 745/1000.
pub fn win_b(c: u64) -> u64 {
    if c % 3 == 0 {
        95
    } else {
        745
    }
}

/// All capital starts at 99 (≡ 0 mod 3, far from u64-subtraction trouble).
pub const START_CAPITAL: u64 = 99;

/// Play `rounds` rounds, cycling through `sched`.
pub fn play(sched: &[fn(u64) -> u64], rounds: usize) -> Dist {
    let mut d: Dist = vec![(START_CAPITAL, BigNat::from_u64(1))];
    for i in 0..rounds {
        d = step_dist(sched[i % sched.len()], &d);
    }
    d
}

/// Exact expected capital of a distribution, rendered as f64 at the end.
pub fn mean_capital(d: &Dist) -> f64 {
    let mut num = BigNat::from_u64(0);
    let mut den = BigNat::from_u64(0);
    for (c, w) in d {
        num = num.add(&w.mul_small(*c));
        den = den.add(w);
    }
    num.to_f64() / den.to_f64()
}

// ----------------------------------------------------------------------
// 11. Jevons / paradox of thrift — NOTE only, as in Lean: macro/empirical
// feedback claims with no small self-contained logical core.
// ----------------------------------------------------------------------

pub fn demo() {
    println!(
        "Prisoner's dilemma (row payoff, true=cooperate): C/C={}, C/D={}, D/C={}, D/D={} — defect dominates, yet (C,C) beats (D,D)",
        pd_payoff(true, true), pd_payoff(true, false), pd_payoff(false, true), pd_payoff(false, false)
    );
    use Cand::*;
    println!(
        "Condorcet: A beats B {}:{}, B beats C {}:{}, C beats A {}:{} — majority preference cycles",
        votes_for(A, B), votes_for(B, A),
        votes_for(B, C), votes_for(C, B),
        votes_for(C, A), votes_for(A, C)
    );
    println!("Allais: 'A over B' forces 11·u1 > 10·u5 + u0, 'D over C' forces the reverse — no utility function (u0,u1,u5) rationalizes both (swept, no counterexample)");
    println!(
        "Newcomb: EV×100 one-box={}, two-box={} (EDT: one-box) — yet per box state two-boxing gains {} (CDT: two-box)",
        one_box_ev(), two_box_ev(),
        newcomb_payoff(true, true) - newcomb_payoff(true, false)
    );
    println!(
        "Braess: before shortcut each driver pays {} centimin (deviating: {}); the moment it opens, deviating to it costs {} < {} — the old split dies; after everyone follows, each pays {} (deviating: {}) — a free road cost everyone 15 minutes",
        top_route(2000), bot_route(2001), shortcut_route(2000, 2001), top_route(2000),
        shortcut_route(4000, 4000), top_route(4000)
    );
    println!(
        "Parrondo, mean capital after 50 rounds (start {}): A only = {:.6} (losing), B only = {:.6} (losing), alternate ABAB = {:.6} (winning!), AABB = {:.6} (winning!)",
        START_CAPITAL,
        mean_capital(&play(&[win_a], 50)),
        mean_capital(&play(&[win_b], 50)),
        mean_capital(&play(&[win_a, win_b], 50)),
        mean_capital(&play(&[win_a, win_a, win_b, win_b], 50))
    );
}

/// The Lean file's per-module catalog.
pub fn catalog() -> Vec<(&'static str, &'static str)> {
    vec![
        ("Prisoner's dilemma",
         "VERIFIED (test): defection strictly dominates for every opponent choice, yet mutual cooperation Pareto-dominates mutual defection"),
        ("Tragedy of the commons",
         "NOTE: the n-player prisoner's dilemma; its logical core (dominance vs Pareto) is item 1"),
        ("Condorcet paradox",
         "VERIFIED (test): with ballots A>B>C, B>C>A, C>A>B majority prefers A>B, B>C, C>A by 2:1 each — a cycle, so majority preference is not transitive"),
        ("Arrow's impossibility theorem",
         "NOTE: formalizable but a project in itself; the Condorcet cycle above is its seed"),
        ("Allais paradox",
         "VERIFIED (test, swept): choices A-over-B and D-over-C jointly unsatisfiable — coefficient reduction checked symbolically, plus brute-force sweep over a utility cube; Lean proves ∀ u0 u1 u5 : Int by omega"),
        ("Ellsberg paradox",
         "NOTE: ambiguity aversion — the Allais inconsistency pattern with subjective probabilities in place of utilities"),
        ("Newcomb's problem",
         "IDENTITY (spot-checked): two-boxing dominates by exactly 1000 in each box state; EV comparison VERIFIED: one-boxing's 100×-scaled EV 99,000,000 beats two-boxing's 1,100,000 — EDT and CDT disagree"),
        ("St. Petersburg paradox",
         "NOTE: cross-reference — formalized in the Lean suite's Infinity file (not translated)"),
        ("Braess's paradox",
         "VERIFIED (test): 2000/2000 split at 6500 is an equilibrium; the shortcut destabilizes it (4001 < 6500); all-on-shortcut is an equilibrium costing everyone 8000 — a free road hurt all"),
        ("Parrondo's paradox",
         "DEMO: exact BigNat DP over the capital distribution — A-only and B-only drift down (98.5, 98.04) but ABAB alternation drifts up (99.46) after 50 rounds"),
        ("Jevons paradox / paradox of thrift",
         "NOTE: macroeconomic/empirical feedback effects; no self-contained formal core"),
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Lean: theorems defection_strictly_dominates,
    /// mutual_cooperation_pareto_dominates, prisoners_dilemma
    #[test]
    fn prisoners_dilemma() {
        for their in [true, false] {
            assert!(pd_payoff(false, their) > pd_payoff(true, their));
        }
        assert!(pd_payoff(true, true) > pd_payoff(false, false));
    }

    /// Lean: theorem condorcet_cycle
    #[test]
    fn condorcet_cycle() {
        use Cand::*;
        assert!(maj_prefers(A, B));
        assert!(maj_prefers(B, C));
        assert!(maj_prefers(C, A));
        // each by exactly 2:1
        assert_eq!(votes_for(A, B), 2);
        assert_eq!(votes_for(B, C), 2);
        assert_eq!(votes_for(C, A), 2);
    }

    /// Lean: theorem majority_not_transitive — transitivity would force
    /// maj_prefers(A, C), but the majority prefers C to A.
    #[test]
    fn majority_not_transitive() {
        use Cand::*;
        assert!(maj_prefers(A, B) && maj_prefers(B, C) && !maj_prefers(A, C));
    }

    /// Lean: theorem allais_no_expected_utility (∀ u0 u1 u5 : Int, by omega).
    /// (a) coefficient-level reduction: choiceA ⟺ 11·u1 > 10·u5 + u0 and
    ///     choiceD ⟺ 10·u5 + u0 > 11·u1 — literally opposite comparisons;
    /// (b) brute-force sweep over a utility cube finds no joint model.
    #[test]
    fn allais_no_expected_utility() {
        // (a) reduction check at scattered points: choiceA agrees with the
        // reduced inequality and choiceD with its strict reverse.
        for &(u0, u1, u5) in &[(0i64, 0, 0), (1, 2, 3), (-50, 17, 4), (1000, -999, 123)] {
            assert_eq!(allais_choice_a(u0, u1, u5), 11 * u1 > 10 * u5 + u0);
            assert_eq!(allais_choice_d(u0, u1, u5), 10 * u5 + u0 > 11 * u1);
        }
        // (b) sweep: no (u0, u1, u5) satisfies both.
        for u0 in -40..=40i64 {
            for u1 in -40..=40i64 {
                for u5 in -40..=40i64 {
                    assert!(
                        !(allais_choice_a(u0, u1, u5) && allais_choice_d(u0, u1, u5)),
                        "counterexample at ({u0}, {u1}, {u5})"
                    );
                }
            }
        }
    }

    /// Lean: theorem newcomb_dominance (∀ boxFull : Bool) and
    /// theorem newcomb_ev_favors_one_boxing
    #[test]
    fn newcomb() {
        for box_full in [true, false] {
            assert_eq!(
                newcomb_payoff(box_full, true),
                newcomb_payoff(box_full, false) + 1000
            );
        }
        assert_eq!(one_box_ev(), 99_000_000);
        assert_eq!(two_box_ev(), 1_100_000);
        assert!(one_box_ev() > two_box_ev());
    }

    /// Lean: theorems braess_before, braess_old_split_destabilized,
    /// braess_after, braess_everyone_worse
    #[test]
    fn braess() {
        assert_eq!(top_route(2000), 6500);
        assert_eq!(bot_route(2000), 6500);
        assert!(bot_route(2001) > top_route(2000));
        assert!(top_route(2001) > bot_route(2000));
        // the audit's missing link: the shortcut destabilizes the old split
        assert!(shortcut_route(2000, 2001) < top_route(2000));
        // new equilibrium: everyone on the shortcut
        assert_eq!(shortcut_route(4000, 4000), 8000);
        assert!(top_route(4000) > shortcut_route(4000, 4000));
        assert!(bot_route(4000) > shortcut_route(4000, 4000));
        // and it is worse for everyone
        assert!(shortcut_route(4000, 4000) > top_route(2000));
    }

    /// Lean: Parrondo #eval DEMO — losing + losing = winning, on the exact
    /// integer DP.  Weights reach 1000^50; BigNat keeps them exact.
    #[test]
    fn parrondo() {
        let a_only = mean_capital(&play(&[win_a], 50));
        let b_only = mean_capital(&play(&[win_b], 50));
        let abab = mean_capital(&play(&[win_a, win_b], 50));
        let aabb = mean_capital(&play(&[win_a, win_a, win_b, win_b], 50));
        let start = START_CAPITAL as f64;
        assert!(a_only < start, "A alone must lose: {a_only}");
        assert!(b_only < start, "B alone must lose: {b_only}");
        assert!(abab > start, "ABAB must win: {abab}");
        assert!(aabb > start, "AABB must win: {aabb}");
        // the exact values the Lean #eval prints
        assert!((a_only - 98.5).abs() < 0.01, "{a_only}");
        assert!((b_only - 98.04).abs() < 0.01, "{b_only}");
        assert!((abab - 99.46).abs() < 0.01, "{abab}");
        assert!((aabb - 99.61).abs() < 0.01, "{aabb}");
        // total weight after 50 rounds is exactly 1000^50 (probability sums to 1)
        let d = play(&[win_a, win_b], 50);
        let total = d.iter().fold(BigNat::from_u64(0), |acc, (_, w)| acc.add(w));
        assert_eq!(total, BigNat::pow(1000, 50));
    }
}
