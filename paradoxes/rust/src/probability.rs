//! # Paradoxes of Probability and Statistics — Rust translation
//!
//! Line-for-line port of `paradoxes/lean/Paradoxes/Probability.lean`.
//! Fourteen classical probability/statistics paradoxes over *finite, exact*
//! sample spaces.  Every probability claim is a statement about integer
//! counts; comparisons of ratios become cross-multiplied integer
//! (in)equalities.
//!
//! Translation dictionary (Lean → Rust):
//! - `theorem … := by decide`   → a `#[test]` whose assertions the test
//!   runner checks by exhaustive computation (the same finite enumeration
//!   the Lean kernel reduces — but checked at *run* time, not proof time)
//! - `List.countP p l`          → `l.iter().filter(p).count()`
//! - `Fin 3`                    → `u8` values 0..3 (invariant by construction)
//! - `Nat` (arbitrary precision)→ `u64`/`u128` where they fit, `BigNat` where
//!   they don't (birthday paradox: 59-digit integers)
//! - `#eval s!"…"`              → `demo()` printing the same counting tables
//!
//! What is *lost* in translation: Lean's `theorem` is a compile-time
//! certificate valid for all executions; a Rust `#[test]` is one green run.
//! For universally quantified statements (`∀ N`, `∀ a : Int`) Lean proves
//! the schema once with `omega`; Rust can only spot-check instances — those
//! sites are marked `IDENTITY (spot-checked)` below.

use crate::bignat::BigNat;

// ----------------------------------------------------------------------
// (1) MONTY HALL — conditional probability.
// Lean: montyPairs : List (Fin 3 × Fin 3), countP, decide.
// ----------------------------------------------------------------------

pub const FIN3: [u8; 3] = [0, 1, 2];

/// All 9 equally likely (prize, pick) configurations.
pub fn monty_pairs() -> Vec<(u8, u8)> {
    FIN3.iter()
        .flat_map(|&prize| FIN3.iter().map(move |&pick| (prize, pick)))
        .collect()
}

pub fn switch_wins(pc: &(u8, u8)) -> bool {
    pc.0 != pc.1
}
pub fn stay_wins(pc: &(u8, u8)) -> bool {
    pc.0 == pc.1
}

/// Richer model: (prize, pick, host, weight).  Host splits 1/1 when he has a
/// choice (prize == pick), weight 2 when forced.  Total weight 18.
pub fn monty_full() -> Vec<(u8, u8, u8, u64)> {
    let mut out = vec![];
    for &prize in &FIN3 {
        for &pick in &FIN3 {
            for &host in FIN3.iter().filter(|&&h| h != pick && h != prize) {
                out.push((prize, pick, host, if prize == pick { 1 } else { 2 }));
            }
        }
    }
    out
}

pub fn w_sum(l: &[(u8, u8, u8, u64)]) -> u64 {
    l.iter().map(|x| x.3).sum()
}

// ----------------------------------------------------------------------
// (2) THREE PRISONERS — isomorphic to Monty Hall (prisoners = doors,
// pardon = prize, warden's named victim = opened door).  As in the Lean
// file, no separate formalization: the Monty Hall checks ARE the theorems.
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
// (3) BERTRAND'S BOX.  Lean: inductive Box | GG | GS | SS, countP, decide.
// ----------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Box {
    GG,
    GS,
    /// Present in the story (you never draw gold from it), absent from the
    /// conditioned sample space — exactly as in the Lean file.
    #[allow(dead_code)]
    SS,
}

/// The three equally likely gold coins, each labeled by its home box.
pub const GOLD_COINS: [Box; 3] = [Box::GG, Box::GG, Box::GS];

pub fn partner_is_gold(b: &Box) -> bool {
    matches!(b, Box::GG)
}

// ----------------------------------------------------------------------
// (4) BOY OR GIRL PARADOX.  Lean: inductive Child | boy | girl.
// ----------------------------------------------------------------------

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Child {
    Boy,
    Girl,
}
use Child::{Boy, Girl};

/// All four equally likely (eldest, youngest) families.
pub const FAMILIES: [(Child, Child); 4] =
    [(Boy, Boy), (Boy, Girl), (Girl, Boy), (Girl, Girl)];

pub fn both_boys(f: &(Child, Child)) -> bool {
    matches!(f, (Boy, Boy))
}
pub fn some_boy(f: &(Child, Child)) -> bool {
    !matches!(f, (Girl, Girl))
}
pub fn eldest_boy(f: &(Child, Child)) -> bool {
    matches!(f.0, Boy)
}

// ----------------------------------------------------------------------
// (5) BIRTHDAY PARADOX.  Lean decides 2 * (365 falling 23) < 365^23 on
// kernel bignums; Rust uses the BigNat module for the same exact 59-digit
// comparison — no floats in the inequality.
// ----------------------------------------------------------------------

pub fn birthday_distinct() -> BigNat {
    BigNat::falling(365, 23)
}
pub fn birthday_total() -> BigNat {
    BigNat::pow(365, 23)
}

/// Float estimate of P(all 23 birthdays distinct) ≈ 0.4927.
pub fn birthday_approx() -> f64 {
    (0..23).fold(1.0, |acc, i| acc * (365.0 - i as f64) / 365.0)
}

// ----------------------------------------------------------------------
// (6) BASE-RATE FALLACY.  Same integer confusion table as the Lean file.
// ----------------------------------------------------------------------

pub const POPULATION: u64 = 100_000;
pub const SICK_COUNT: u64 = 100; // prevalence 1/1000
pub const HEALTHY_COUNT: u64 = 99_900;
pub const TRUE_POSITIVES: u64 = 99; // sensitivity 99%
pub const FALSE_POSITIVES: u64 = 4_995; // false-positive rate 5%

// ----------------------------------------------------------------------
// (7) SLEEPING BEAUTY.  Lean proves ∀ N by omega; Rust exposes the model
// functions and spot-checks the identities over a range (IDENTITY status).
// ----------------------------------------------------------------------

pub fn heads_runs(n: u64) -> u64 {
    n
}
pub fn tails_runs(n: u64) -> u64 {
    n
}
pub fn heads_awakenings(n: u64) -> u64 {
    n // one awakening per heads-run
}
pub fn tails_awakenings(n: u64) -> u64 {
    2 * n // two per tails-run
}
pub fn total_awakenings(n: u64) -> u64 {
    heads_awakenings(n) + tails_awakenings(n)
}
pub fn total_runs(n: u64) -> u64 {
    heads_runs(n) + tails_runs(n)
}

// ----------------------------------------------------------------------
// (8) TWO ENVELOPES.  Lean proves ∀ a : Int by omega; spot-checked here.
// ----------------------------------------------------------------------

pub fn gain_if_holding_smaller(a: i64) -> i64 {
    2 * a - a
}
pub fn gain_if_holding_larger(a: i64) -> i64 {
    a - 2 * a
}

// ----------------------------------------------------------------------
// (9) GAMBLER'S FALLACY.  All 32 length-5 coin sequences.
// ----------------------------------------------------------------------

pub fn seqs5() -> Vec<[bool; 5]> {
    let bools = [true, false];
    let mut out = vec![];
    for &a in &bools {
        for &b in &bools {
            for &c in &bools {
                for &d in &bools {
                    for &e in &bools {
                        out.push([a, b, c, d, e]);
                    }
                }
            }
        }
    }
    out
}

pub fn starts_hhhh(s: &[bool; 5]) -> bool {
    s[0] && s[1] && s[2] && s[3]
}
pub fn fifth_h(s: &[bool; 5]) -> bool {
    s[4]
}

// ----------------------------------------------------------------------
// (10) SIMPSON'S PARADOX — real kidney-stone data (Charig et al. 1986).
// Pure integer cross-multiplications, checked in tests.
// ----------------------------------------------------------------------

// ----------------------------------------------------------------------
// (11) WILL ROGERS PHENOMENON.
// ----------------------------------------------------------------------

pub const LOW_BEFORE: [u64; 2] = [1, 2];
pub const LOW_AFTER: [u64; 3] = [1, 2, 90];
pub const HIGH_BEFORE: [u64; 2] = [90, 100];
pub const HIGH_AFTER: [u64; 1] = [100];

// ----------------------------------------------------------------------
// (12) FRIENDSHIP PARADOX — star K_{1,3} on 4 vertices.
// ----------------------------------------------------------------------

pub const VERTS: [u8; 4] = [0, 1, 2, 3];

/// Star K_{1,3}: vertex 0 adjacent to 1, 2, 3.
pub fn adj(i: u8, j: u8) -> bool {
    (i == 0 && j != 0) || (j == 0 && i != 0)
}

pub fn deg(v: u8) -> u64 {
    VERTS.iter().filter(|&&j| adj(v, j)).count() as u64
}

/// Average degree of v's friends (exact integer on this graph: 3/3 and 3/1).
pub fn avg_friend_deg(v: u8) -> u64 {
    let friends: Vec<u8> = VERTS.iter().copied().filter(|&j| adj(v, j)).collect();
    friends.iter().map(|&f| deg(f)).sum::<u64>() / deg(v)
}

// ----------------------------------------------------------------------
// (13) ACCURACY PARADOX.
// ----------------------------------------------------------------------

pub const N_SAMPLES: u64 = 1000;
pub const N_POSITIVE: u64 = 10;
pub const NULL_CORRECT: u64 = 990; // TN = 990, everything else missed
pub const NULL_RECALL: u64 = 0;
pub const REAL_CORRECT: u64 = 8 + 942; // TP 8, TN 942 (FN 2, FP 48)
pub const REAL_RECALL: u64 = 8;

// ----------------------------------------------------------------------
// (14) BERKSON'S PARADOX — selection bias via a collider.
// ----------------------------------------------------------------------

/// Population of 100: (hasA, hasB), 25 in each of the four cells.
pub fn berkson_pop() -> Vec<(bool, bool)> {
    let mut v = vec![];
    for cell in [(true, true), (true, false), (false, true), (false, false)] {
        v.extend(std::iter::repeat(cell).take(25));
    }
    v
}

/// Hospital admits anyone with at least one condition.
pub fn admitted() -> Vec<(bool, bool)> {
    berkson_pop().into_iter().filter(|p| p.0 || p.1).collect()
}

fn count<T>(l: &[T], p: impl Fn(&T) -> bool) -> u64 {
    l.iter().filter(|x| p(x)).count() as u64
}

// ----------------------------------------------------------------------
// Demo: the Rust analogue of the Lean file's #eval lines.
// ----------------------------------------------------------------------

pub fn demo() {
    let pairs = monty_pairs();
    println!(
        "Monty Hall: of {} uniform (prize,pick) cases, switching wins {}, staying wins {}",
        pairs.len(),
        count(&pairs, switch_wins),
        count(&pairs, stay_wins)
    );
    let full = monty_full();
    println!(
        "Monty Hall with host: total weight {}, switch-wins weight {} (= 2/3)",
        w_sum(&full),
        w_sum(&full.iter().copied().filter(|x| x.0 != x.1).collect::<Vec<_>>())
    );
    println!(
        "Bertrand's box: {} of the {} equally likely gold coins have a gold partner: P = 2/3, not 1/2",
        count(&GOLD_COINS, partner_is_gold),
        GOLD_COINS.len()
    );
    println!(
        "Boy-girl: P(BB | some boy) = {}/{}, but P(BB | eldest boy) = {}/{}",
        count(&FAMILIES, |f| some_boy(f) && both_boys(f)),
        count(&FAMILIES, some_boy),
        count(&FAMILIES, |f| eldest_boy(f) && both_boys(f)),
        count(&FAMILIES, eldest_boy)
    );
    println!("Birthday: distinct assignments = {}", birthday_distinct().to_decimal());
    println!("Birthday: total assignments   = {}", birthday_total().to_decimal());
    println!(
        "Birthday: P(all 23 distinct) ≈ {:.6}, so P(shared birthday) ≈ {:.6}",
        birthday_approx(),
        1.0 - birthday_approx()
    );
    println!(
        "Base rate: of {} people, {} sick ({} test +), {} healthy ({} test +)",
        POPULATION, SICK_COUNT, TRUE_POSITIVES, HEALTHY_COUNT, FALSE_POSITIVES
    );
    println!(
        "Base rate: P(sick | positive) = {}/{} ≈ {:.6} — under 1/50 (2%) despite a 99%-sensitive test",
        TRUE_POSITIVES,
        TRUE_POSITIVES + FALSE_POSITIVES,
        TRUE_POSITIVES as f64 / (TRUE_POSITIVES + FALSE_POSITIVES) as f64
    );
    println!(
        "Sleeping Beauty, N = 1000 runs each way: heads awakenings {} of {} (thirder 1/3); heads runs {} of {} (halfer 1/2)",
        heads_awakenings(1000),
        total_awakenings(1000),
        heads_runs(1000),
        total_runs(1000)
    );
    println!(
        "Two envelopes (a = 100): gain if holding smaller {}, if larger {}, sum {}",
        gain_if_holding_smaller(100),
        gain_if_holding_larger(100),
        gain_if_holding_smaller(100) + gain_if_holding_larger(100)
    );
    let s5 = seqs5();
    println!(
        "Gambler's fallacy: {} of {} sequences start HHHH; {} of those continue H — still 1/2, the coin has no memory",
        count(&s5, starts_hhhh),
        s5.len(),
        count(&s5, |s| starts_hhhh(s) && fifth_h(s))
    );
    println!("Simpson (kidney stones): A wins small (81/87 vs 234/270) and large (192/263 vs 55/80) yet loses overall (273/350 vs 289/350)");
    println!(
        "Will Rogers: moving 90 raises low-group mean {}/{} -> {}/{} (1.5 -> 31) AND high-group mean {}/{} -> {}/{} (95 -> 100)",
        LOW_BEFORE.iter().sum::<u64>(), LOW_BEFORE.len(),
        LOW_AFTER.iter().sum::<u64>(), LOW_AFTER.len(),
        HIGH_BEFORE.iter().sum::<u64>(), HIGH_BEFORE.len(),
        HIGH_AFTER.iter().sum::<u64>(), HIGH_AFTER.len()
    );
    let degs: Vec<u64> = VERTS.iter().map(|&v| deg(v)).collect();
    let afds: Vec<u64> = VERTS.iter().map(|&v| avg_friend_deg(v)).collect();
    println!(
        "Friendship paradox on K_(1,3): degrees {:?}, mean {}/4; avg-friend-degrees {:?}, mean {}/4 — your friends have more friends than you",
        degs,
        degs.iter().sum::<u64>(),
        afds,
        afds.iter().sum::<u64>()
    );
    println!(
        "Accuracy paradox: always-negative scores {}/{} accuracy vs the real model's {}/{}, yet recall {}/{} vs {}/{}",
        NULL_CORRECT, N_SAMPLES, REAL_CORRECT, N_SAMPLES, NULL_RECALL, N_POSITIVE, REAL_RECALL, N_POSITIVE
    );
    let pop = berkson_pop();
    let adm = admitted();
    println!(
        "Berkson: population P(A|B) = {}/{} = P(A|not B) = {}/{} (independent)",
        count(&pop, |p| p.0 && p.1),
        count(&pop, |p| p.1),
        count(&pop, |p| p.0 && !p.1),
        count(&pop, |p| !p.1)
    );
    println!(
        "Berkson: among {} admitted, P(A|B) = {}/{} < P(A|not B) = {}/{} — selection made A and B look negatively associated",
        adm.len(),
        count(&adm, |p| p.0 && p.1),
        count(&adm, |p| p.1),
        count(&adm, |p| p.0 && !p.1),
        count(&adm, |p| !p.1)
    );
}

/// The Lean file's per-module `catalog : List (String × String)`.
pub fn catalog() -> Vec<(&'static str, &'static str)> {
    vec![
        ("Monty Hall",
         "VERIFIED (test): switching wins 6/9 uniform (prize,pick) cases, staying 3/9; weighted host model 12/18, conditional table 2/3"),
        ("Three Prisoners",
         "NOTE: isomorphic to Monty Hall under prisoners=doors, pardon=prize, warden's named victim=opened door; covered by the Monty Hall tests"),
        ("Bertrand's Box",
         "VERIFIED (test): 2 of the 3 equally likely gold coins have a gold partner: P(other gold | drew gold) = 2/3"),
        ("Boy or Girl",
         "VERIFIED (test): P(BB | at least one boy) = 1/3 yet P(BB | eldest is a boy) = 1/2; the ambiguity of the conditioning event is the paradox"),
        ("Birthday Paradox",
         "VERIFIED (test): exact BigNat arithmetic, 2 * (365 falling 23) < 365^23, so P(23 distinct birthdays) < 1/2; f64 demo ≈ 0.4927"),
        ("Base-Rate Fallacy",
         "VERIFIED (test): 99 true vs 4995 false positives per 100000: P(sick | positive) = 99/5094 < 1/50 (under 2%)"),
        ("Sleeping Beauty",
         "IDENTITY (spot-checked): 3·heads-awakenings = total awakenings and 2·heads-runs = total runs, checked for N in 0..10000 — Lean proves ∀ N; the dispute is which ratio 'credence' names"),
        ("Two Envelopes",
         "IDENTITY (spot-checked): gain-if-smaller + gain-if-larger = 0, checked over a range of a — Lean proves ∀ a : Int by omega"),
        ("Gambler's Fallacy",
         "VERIFIED (test): over all 32 length-5 sequences, exactly 1 of the 2 HHHH-starts continues H: conditional = unconditional = 1/2"),
        ("Simpson's Paradox",
         "VERIFIED (test): Charig kidney-stone data, A beats B in both strata (81·270>234·87, 192·80>55·263) yet loses overall 273 < 289 of 350"),
        ("Will Rogers Phenomenon",
         "VERIFIED (test): moving 90 from {90,100} to {1,2} raises both means via cross-multiplied inequalities"),
        ("Friendship Paradox",
         "VERIFIED (test): on star K_{1,3}, scaled mean degree 6 < scaled mean friend-degree 10 over the same 4 people"),
        ("Accuracy Paradox",
         "VERIFIED (test): always-negative accuracy 990/1000 beats the real model's 950/1000 while recall is 0/10 vs 8/10"),
        ("Berkson's Paradox",
         "VERIFIED (test): A,B independent in the 25/25/25/25 population but among the 75 admitted P(A|B) = 25/50 < P(A|not B) = 25/25"),
    ]
}

// ----------------------------------------------------------------------
// The `decide` theorems, as tests.
// ----------------------------------------------------------------------

#[cfg(test)]
mod tests {
    use super::*;

    /// Lean: theorem monty_hall
    #[test]
    fn monty_hall() {
        let pairs = monty_pairs();
        assert_eq!(pairs.len(), 9);
        assert_eq!(count(&pairs, switch_wins), 6);
        assert_eq!(count(&pairs, stay_wins), 3);
    }

    /// Lean: theorems monty_hall_weighted, monty_hall_conditional
    #[test]
    fn monty_hall_weighted_and_conditional() {
        let full = monty_full();
        assert_eq!(w_sum(&full), 18);
        let switch: Vec<_> = full.iter().copied().filter(|x| x.0 != x.1).collect();
        assert_eq!(w_sum(&switch), 12);
        // conditional: picked door 0, host opened door 2
        let cond: Vec<_> = full.iter().copied().filter(|x| x.1 == 0 && x.2 == 2).collect();
        assert_eq!(w_sum(&cond), 3);
        let cond_switch: Vec<_> = cond.iter().copied().filter(|x| x.0 != x.1).collect();
        assert_eq!(w_sum(&cond_switch), 2);
    }

    /// Lean: theorem bertrands_box
    #[test]
    fn bertrands_box() {
        assert_eq!(GOLD_COINS.len(), 3);
        assert_eq!(count(&GOLD_COINS, partner_is_gold), 2);
    }

    /// Lean: theorems boy_girl_at_least_one, boy_girl_eldest
    #[test]
    fn boy_girl() {
        assert_eq!(count(&FAMILIES, some_boy), 3);
        assert_eq!(count(&FAMILIES, |f| some_boy(f) && both_boys(f)), 1);
        assert_eq!(count(&FAMILIES, eldest_boy), 2);
        assert_eq!(count(&FAMILIES, |f| eldest_boy(f) && both_boys(f)), 1);
    }

    /// Lean: theorem birthday_paradox : 2 * fallingProd 365 23 < 365 ^ 23
    /// The same exact 59-digit integer comparison, on BigNat instead of
    /// kernel Nat.
    #[test]
    fn birthday_paradox() {
        let twice_distinct = birthday_distinct().mul_small(2);
        let total = birthday_total();
        assert!(twice_distinct < total);
        // Both really are 59-digit integers, as the Lean PR advertises:
        assert_eq!(birthday_distinct().to_decimal().len(), 59);
        assert_eq!(total.to_decimal().len(), 59);
        // And the float estimate lands where the story says.
        assert!((birthday_approx() - 0.4927).abs() < 0.001);
    }

    /// Lean: theorems base_rate_table, base_rate_fallacy
    #[test]
    fn base_rate() {
        assert_eq!(SICK_COUNT * 1000, POPULATION);
        assert_eq!(HEALTHY_COUNT, POPULATION - SICK_COUNT);
        assert_eq!(TRUE_POSITIVES * 100, SICK_COUNT * 99);
        assert_eq!(FALSE_POSITIVES * 100, HEALTHY_COUNT * 5);
        // P(sick | positive) < 1/50, cross-multiplied:
        assert!(TRUE_POSITIVES * 50 < TRUE_POSITIVES + FALSE_POSITIVES);
    }

    /// Lean: theorems sleeping_beauty_thirder / _halfer, proved ∀ N by omega.
    /// Rust spot-checks the identity over a range (see module doc).
    #[test]
    fn sleeping_beauty_spot_check() {
        for n in 0..10_000 {
            assert_eq!(3 * heads_awakenings(n), total_awakenings(n));
            assert_eq!(2 * heads_runs(n), total_runs(n));
        }
    }

    /// Lean: theorem two_envelopes, proved ∀ a : Int by omega.  Spot-checked.
    #[test]
    fn two_envelopes_spot_check() {
        for a in -1_000_000..=1_000_000i64 {
            assert_eq!(gain_if_holding_smaller(a) + gain_if_holding_larger(a), 0);
        }
    }

    /// Lean: theorem gamblers_fallacy
    #[test]
    fn gamblers_fallacy() {
        let s = seqs5();
        assert_eq!(s.len(), 32);
        assert_eq!(count(&s, starts_hhhh), 2);
        assert_eq!(count(&s, |x| starts_hhhh(x) && fifth_h(x)), 1);
        assert_eq!(count(&s, fifth_h), 16);
        // independence, cross-multiplied: 1 · 32 = 2 · 16
        assert_eq!(
            count(&s, |x| starts_hhhh(x) && fifth_h(x)) * s.len() as u64,
            count(&s, starts_hhhh) * count(&s, fifth_h)
        );
    }

    /// Lean: theorem simpsons_paradox (Charig kidney-stone data)
    #[test]
    fn simpsons_paradox() {
        assert!(81 * 270 > 234 * 87); // small stones: A wins
        assert!(192 * 80 > 55 * 263); // large stones: A wins
        assert_eq!(81 + 192, 273);
        assert_eq!(234 + 55, 289);
        assert_eq!(87 + 263, 350);
        assert_eq!(270 + 80, 350);
        assert!(273 < 289); // overall: A loses
    }

    /// Lean: theorem will_rogers
    #[test]
    fn will_rogers() {
        let (lb, la) = (LOW_BEFORE.iter().sum::<u64>(), LOW_AFTER.iter().sum::<u64>());
        let (hb, ha) = (HIGH_BEFORE.iter().sum::<u64>(), HIGH_AFTER.iter().sum::<u64>());
        assert!(lb * (LOW_AFTER.len() as u64) < la * (LOW_BEFORE.len() as u64));
        assert!(hb * (HIGH_AFTER.len() as u64) < ha * (HIGH_BEFORE.len() as u64));
    }

    /// Lean: theorem friendship_paradox
    #[test]
    fn friendship_paradox() {
        let deg_sum: u64 = VERTS.iter().map(|&v| deg(v)).sum();
        let afd_sum: u64 = VERTS.iter().map(|&v| avg_friend_deg(v)).sum();
        assert_eq!(deg_sum, 6);
        assert_eq!(afd_sum, 10);
        assert!(deg_sum < afd_sum);
    }

    /// Lean: theorem accuracy_paradox
    #[test]
    fn accuracy_paradox() {
        assert_eq!(NULL_CORRECT, N_SAMPLES - N_POSITIVE);
        assert_eq!(REAL_CORRECT, 950);
        assert!(REAL_CORRECT < NULL_CORRECT); // worse accuracy...
        assert!(NULL_RECALL < REAL_RECALL); // ...but the null model finds nothing
    }

    /// Lean: theorems berkson_population_independent, berksons_paradox
    #[test]
    fn berksons_paradox() {
        let pop = berkson_pop();
        assert_eq!(pop.len(), 100);
        // independence in the population: |A∧B|·|¬B| = |A∧¬B|·|B|
        assert_eq!(
            count(&pop, |p| p.0 && p.1) * count(&pop, |p| !p.1),
            count(&pop, |p| p.0 && !p.1) * count(&pop, |p| p.1)
        );
        let adm = admitted();
        assert_eq!(adm.len(), 75);
        // among the admitted: P(A|B) < P(A|¬B), cross-multiplied
        assert!(
            count(&adm, |p| p.0 && p.1) * count(&adm, |p| !p.1)
                < count(&adm, |p| p.0 && !p.1) * count(&adm, |p| p.1)
        );
    }
}
