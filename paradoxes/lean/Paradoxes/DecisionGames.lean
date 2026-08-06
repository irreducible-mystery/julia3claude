/-!
# Paradoxes of Decision, Games, and Social Choice

Machine-checked formalizations of classical paradoxes from decision theory,
game theory, social choice, and economics: the prisoner's dilemma, the
Condorcet cycle, the Allais paradox, Newcomb's problem, Braess's paradox,
and an exact-arithmetic computation of Parrondo's paradox, plus honest
NOTEs for neighbors (tragedy of the commons, Arrow, Ellsberg,
St. Petersburg, Jevons/thrift) that are either subsumed, cross-referenced,
or genuinely out of scope for a core-Lean file.

Core Lean 4 only: proofs use `decide` and `omega`; the running
demonstrations are `#eval` lines executed at compile time.
-/

namespace Paradoxes.DecisionGames

/-
## 1. Prisoner's dilemma  (game theory)

Story: Two prisoners each choose to Cooperate (stay silent) or Defect
(betray).  Whatever the other does, defecting pays strictly more — so two
rational players both defect and get 1 each, even though mutual
cooperation would have given each of them 3.

Formalized: the payoff matrix `pdPayoff my their` (true = cooperate) with
the standard values 3/0/5/1.  Two `decide` theorems: defection strictly
dominates cooperation against every opponent choice, yet mutual
cooperation strictly Pareto-dominates the mutual-defection outcome that
dominance reasoning produces.

Resolution/lesson: there is no contradiction — the paradox is that
individually dominant choices aggregate to a collectively dominated
outcome.  Nash equilibrium and Pareto optimality are different solution
concepts, and here they point in opposite directions.
-/

/-- Row player's payoff; `true` = cooperate, `false` = defect. -/
def pdPayoff : Bool → Bool → Nat
  | true,  true  => 3   -- C/C
  | true,  false => 0   -- C/D: sucker's payoff
  | false, true  => 5   -- D/C: temptation
  | false, false => 1   -- D/D

/-- Whatever the opponent does, defecting pays strictly more than cooperating. -/
theorem defection_strictly_dominates :
    ∀ their : Bool, pdPayoff false their > pdPayoff true their := by decide

/-- Yet mutual cooperation pays each player strictly more than mutual defection. -/
theorem mutual_cooperation_pareto_dominates :
    pdPayoff true true > pdPayoff false false := by decide

/-- The dilemma in one statement: dominance drives both players to D/D (payoff 1),
    while C/C (payoff 3) was available and better for both. -/
theorem prisoners_dilemma :
    (∀ their : Bool, pdPayoff false their > pdPayoff true their) ∧
    pdPayoff true true > pdPayoff false false := by decide

#eval s!"Prisoner's dilemma (row payoff, true=cooperate): C/C={pdPayoff true true}, C/D={pdPayoff true false}, D/C={pdPayoff false true}, D/D={pdPayoff false false} — defect dominates, yet (C,C) beats (D,D)"

/-
## 2. Tragedy of the commons  (economics)

NOTE only.  Hardin's tragedy is the n-player generalization of the
prisoner's dilemma: each herder's dominant strategy (add one more animal
to the shared pasture) is collectively ruinous.  The 2-player core of the
phenomenon — dominant strategies producing a Pareto-dominated outcome —
is exactly what item 1 proves, so a separate n-player formalization would
add bookkeeping (payoffs as functions of how many players defect) without
adding a new logical point.
-/

/-
## 3. Condorcet paradox  (social choice)

Story: Three voters rank three candidates A, B, C as A>B>C, B>C>A, and
C>A>B.  Pairwise majority vote then prefers A to B (2:1), B to C (2:1),
and C to A (2:1) — a cycle.  A perfectly reasonable electorate of
individually rational (transitively-ranking) voters produces an
irrational (cyclic) group preference.

Formalized: explicit rank lists for the 3 voters, pairwise vote counting
with `List.countP`, and a `decide` verification of the full cycle.  A
corollary theorem shows majority preference is not transitive, so it is
not an ordering and "the group's most preferred candidate" is undefined.

Resolution/lesson: majority aggregation does not preserve transitivity.
This cycle is the seed of Arrow's impossibility theorem (item 4).
-/

inductive Cand where
  | A | B | C
deriving DecidableEq, Repr

/-- `rank v x` = position of candidate `x` in voter `v`'s ballot (0 = top).
    Voter 0: A>B>C.  Voter 1: B>C>A.  Voter 2: C>A>B. -/
def rank : Nat → Cand → Nat
  | 0, .A => 0 | 0, .B => 1 | 0, .C => 2
  | 1, .B => 0 | 1, .C => 1 | 1, .A => 2
  | 2, .C => 0 | 2, .A => 1 | 2, .B => 2
  | _, _  => 0

/-- Voter `v` strictly prefers `x` to `y`. -/
def prefers (v : Nat) (x y : Cand) : Bool := decide (rank v x < rank v y)

/-- Number of the three voters preferring `x` to `y`. -/
def votesFor (x y : Cand) : Nat := (List.range 3).countP fun v => prefers v x y

/-- A strict majority (≥ 2 of 3) prefers `x` to `y`. -/
def majPrefers (x y : Cand) : Bool := decide (2 ≤ votesFor x y)

/-- The Condorcet cycle: majorities prefer A to B, B to C, and C to A. -/
theorem condorcet_cycle :
    majPrefers Cand.A Cand.B = true ∧
    majPrefers Cand.B Cand.C = true ∧
    majPrefers Cand.C Cand.A = true := by decide

/-- Hence majority preference is not transitive: it prefers A to B and B to C
    but not A to C (indeed it prefers C to A), so it is no ordering at all. -/
theorem majority_not_transitive
    (h : ∀ x y z : Cand,
        majPrefers x y = true → majPrefers y z = true → majPrefers x z = true) :
    False :=
  absurd (h Cand.A Cand.B Cand.C (by decide) (by decide)) (by decide)

#eval s!"Condorcet: A beats B {votesFor Cand.A Cand.B}:{votesFor Cand.B Cand.A}, B beats C {votesFor Cand.B Cand.C}:{votesFor Cand.C Cand.B}, C beats A {votesFor Cand.C Cand.A}:{votesFor Cand.A Cand.C} — majority preference cycles"

/-
## 4. Arrow's impossibility theorem  (social choice)

NOTE only.  Arrow's theorem — every social welfare function on ≥ 3
alternatives satisfying unanimity and independence of irrelevant
alternatives is a dictatorship — is fully formalizable, but it is a
research-project-sized development (quantifying over all preference
profiles, decisive-coalition arguments), not a file item.  The Condorcet
cycle above is its seed: it already shows the obvious aggregation rule
fails to produce an ordering, which is why Arrow had to ask which rules
could.
-/

/-
## 5. Allais paradox  (decision theory / economics)

Story: Experiment 1: most people choose gamble A ($1M for sure) over B
(10% $5M, 89% $1M, 1% nothing).  Experiment 2: the same people choose D
(10% $5M, 90% nothing) over C (11% $1M, 89% nothing).  Each choice looks
sensible, but no assignment of utilities to the three prizes makes both
choices maximize expected utility.

Formalized: with utilities `u0 u1 u5 : Int` for $0/$1M/$5M and
percentages as integer weights, choice A>B says `100·u1 > 10·u5 + 89·u1
+ 1·u0` and choice D>C says `10·u5 + 90·u0 > 11·u1 + 89·u0`.  The
theorem derives `False` from the two inequalities by `omega`: both reduce
to opposite comparisons of `11·u1` with `10·u5 + u0`.

Resolution/lesson: the modal human pattern violates the independence
axiom of expected utility (the common 89% consequence should cancel).
Humans overweight certainty; expected-utility theory is a normative
model that real preferences measurably break.
-/

theorem allais_no_expected_utility (u0 u1 u5 : Int)
    (choiceA : 100 * u1 > 10 * u5 + 89 * u1 + 1 * u0)
    (choiceD : 10 * u5 + 90 * u0 > 11 * u1 + 89 * u0) :
    False := by omega

#eval s!"Allais: 'A over B' forces 11·u1 > 10·u5 + u0, 'D over C' forces the reverse — no utility function (u0,u1,u5) rationalizes both (proved by omega)"

/-
## 6. Ellsberg paradox  (decision theory)

NOTE only.  An urn holds 30 red balls and 60 black-or-yellow in unknown
proportion.  People prefer betting on red (known 1/3) over black, yet
prefer black-or-yellow (known 2/3) over red-or-yellow: the first choice
forces P(black) < 1/3, the second forces P(black) > 1/3, for any single
subjective probability — the same inconsistency pattern the Allais theorem
exhibits for utilities.  It shows ambiguity aversion: no single
subjective probability rationalizes the modal choices.  Formally it is
the Allais schema with probabilities in place of utilities, so it is
recorded as a NOTE rather than duplicated.
-/

/-
## 7. Newcomb's problem  (decision theory)

Story: An almost-perfect predictor put $1,000,000 in an opaque box iff it
predicted you will take only that box; a transparent box always holds
$1,000.  Take one box or both?  Expected value (predictor 99% accurate)
says one-box; dominance says two-box, since in each fixed state of the
opaque box, taking both is exactly $1,000 better.

Formalized: the payoff function over (box state, action); a `decide`
theorem that two-boxing beats one-boxing by exactly 1000 in each of the
two box states (dominance), and a `decide` theorem that with the 99%
predictor the one-boxing expected value (×100) 99·1,000,000 exceeds the
two-boxing 1·1,001,000 + 99·1,000.

Resolution/lesson: both computations are correct; the theorems make the
clash precise.  Evidential decision theory (act on conditional expected
value) one-boxes; causal decision theory (your act cannot cause the
already-fixed box contents) two-boxes.  The paradox is that two
compelling principles of rational choice provably disagree.
-/

/-- Payoff given whether the opaque box is full and whether you take both boxes. -/
def newcombPayoff (boxFull takeBoth : Bool) : Nat :=
  (if boxFull then 1000000 else 0) + (if takeBoth then 1000 else 0)

/-- Dominance: in each fixed state of the opaque box, two-boxing gains exactly 1000. -/
theorem newcomb_dominance :
    ∀ boxFull : Bool,
      newcombPayoff boxFull true = newcombPayoff boxFull false + 1000 := by decide

/-- Expected values scaled by 100, with a 99%-accurate predictor:
    one-box → 99% full box; two-box → 99% empty box. -/
def oneBoxEV : Nat := 99 * newcombPayoff true false + 1 * newcombPayoff false false
def twoBoxEV : Nat := 1 * newcombPayoff true true + 99 * newcombPayoff false true

/-- Expected value: one-boxing wins by a huge margin (99,000,000 vs 1,100,000). -/
theorem newcomb_ev_favors_one_boxing : oneBoxEV > twoBoxEV := by decide

#eval s!"Newcomb: EV×100 one-box={oneBoxEV}, two-box={twoBoxEV} (EDT: one-box) — yet per box state two-boxing gains {newcombPayoff true true - newcombPayoff true false} (CDT: two-box)"

/-
## 8. St. Petersburg paradox  (decision theory / probability)

NOTE, cross-reference.  The coin-doubling gamble whose expected payoff
diverges while any sane person pays only a few dollars to play is
formalized in this suite's Infinity file (the divergence of the partial
expectations is an unbounded-sum statement, which belongs with the other
infinity paradoxes).  Not duplicated here.
-/

/-
## 9. Braess's paradox  (game theory / traffic economics)

Story: 4000 drivers travel A→B along two routes.  Top: a congestible
road A→C taking x/100 minutes for x drivers, then a fixed 45-minute road
C→B.  Bottom: fixed 45 minutes A→D, then congestible x/100 D→B.  In
equilibrium they split 2000/2000 and each takes 65 minutes.  Now add a
zero-cost shortcut C→D.  The only equilibrium becomes: everyone drives
congestible A→C, shortcut, congestible D→B — and everyone takes 80
minutes.  Adding a free road made every single driver worse off.

Formalized (in centiminutes, so all arithmetic is exact in Nat: a
congestible leg with x drivers costs x, a fixed leg costs 4500):
(i) before the shortcut, the 2000/2000 split is an equilibrium — a lone
deviator would pay 6501 > 6500; (ii) the load-bearing step the audit
found missing: the moment the shortcut opens, that old 2000/2000 split
STOPS being an equilibrium — a top-route driver who switches to the
shortcut path keeps the A→C leg at load 2000 (they are still on it) and
joins the D→B leg at load 2001, paying 4001 < 6500, a strict gain — so
the system must move; (iii) after the shortcut, all-4000-on-the-
shortcut-path is an equilibrium — a deviator to top or bottom still
shares a congestible leg with all 4000 cars and pays 8500 > 8000;
(iv) 8000 > 6500: the new equilibrium is worse for everyone.  All by
`decide`.

Resolution/lesson: Nash equilibria need not be Pareto-efficient, and the
inefficiency can be created by adding capacity.  Removing a road can
speed traffic up (observed in real cities: Seoul, Stuttgart, New York).
-/

/-- Cost in centiminutes of the top route when `x` drivers use its congestible leg. -/
def topRoute (x : Nat) : Nat := x + 4500

/-- Cost of the bottom route when `x` drivers use its congestible leg. -/
def botRoute (x : Nat) : Nat := 4500 + x

/-- Cost of the shortcut route: congestible A→C (load `ac`), free C→D,
    congestible D→B (load `db`). -/
def shortcutRoute (ac db : Nat) : Nat := ac + 0 + db

/-- Before the shortcut: the 2000/2000 split costs everyone 6500, and a lone
    deviator to the other route would pay 6501 — so nobody moves: equilibrium. -/
theorem braess_before :
    topRoute 2000 = 6500 ∧ botRoute 2000 = 6500 ∧
    botRoute 2001 > topRoute 2000 ∧ topRoute 2001 > botRoute 2000 := by decide

/-- The audit's missing link: once the shortcut exists, the old 2000/2000
    split is no equilibrium at all.  A driver on the top route (cost 6500)
    who deviates to A→C→D→B still shares A→C with its 2000 cars (themselves
    included) and joins D→B, raising its load to 2001 — total 4001 < 6500,
    a strict gain.  The shortcut is irresistible; the slide to the worse
    equilibrium is forced, not optional. -/
theorem braess_old_split_destabilized :
    shortcutRoute 2000 2001 < topRoute 2000 := by decide

/-- After the free shortcut opens: everyone on A→C→D→B pays 8000, and a lone
    deviator to top or bottom (still sharing one congestible leg with all
    4000 cars, itself included) would pay 8500 — so nobody moves: equilibrium. -/
theorem braess_after :
    shortcutRoute 4000 4000 = 8000 ∧
    topRoute 4000 > shortcutRoute 4000 4000 ∧
    botRoute 4000 > shortcutRoute 4000 4000 := by decide

/-- The free new road made every driver strictly worse off: 80 min > 65 min. -/
theorem braess_everyone_worse :
    shortcutRoute 4000 4000 > topRoute 2000 := by decide

#eval s!"Braess: before shortcut each driver pays {topRoute 2000} centimin (deviating: {botRoute 2001}); the moment it opens, deviating to it costs {shortcutRoute 2000 2001} < {topRoute 2000} — the old split dies; after everyone follows, each pays {shortcutRoute 4000 4000} (deviating: {topRoute 4000}) — a free road cost everyone 15 minutes"

/-
## 10. Parrondo's paradox  (game theory / stochastic processes)

Story: Game A: win 1 with probability 0.495, else lose 1 — a losing
game.  Game B: if your capital is a multiple of 3, win with probability
0.095, else win with probability 0.745 — also a losing game.  Yet
alternating A,B,A,B,... is a *winning* game: game A's noise pumps
capital off the multiples of 3 where game B is terrible, letting B's
good branch dominate.

Formalized as a computed DEMO (labelled honestly — no theorem): an exact
integer dynamic program over the full probability distribution of
capital, weights scaled by 1000 each round so all arithmetic is exact in
Nat (weights reach 1000^50; capital starts at 99 ≡ 0 (mod 3), safely
above 0, so Nat capital never underflows).  `#eval` prints the exact
expected capital (rendered as Float only at the end) after 50 rounds:
A-only drifts down to 98.5, B-only down to ≈98.04, but strict
alternation ABAB rises to ≈99.46 (and AABB to ≈99.61).

Resolution/lesson: "losing + losing = winning" is no contradiction —
game B's payoff depends on a state variable whose distribution the other
game reshapes.  Mixing dynamics can change the sign of a drift; the same
ratchet mechanism appears in flashing Brownian motors in physics.
-/

/-- A distribution over capital values: list of (capital, weight) pairs.
    Weights are exact Nats, scaled by 1000 per round played. -/
abbrev Dist := List (Nat × Nat)

/-- Add weight `w` at capital `c`, merging with an existing entry if present. -/
def addWeight : Dist → Nat → Nat → Dist
  | [],              c, w => [(c, w)]
  | (c', w') :: rest, c, w =>
    if c = c' then (c', w' + w) :: rest else (c', w') :: addWeight rest c w

/-- Play one round of a game with win-weight function `winW : capital → per-mille`.
    Each (c, w) entry splits into a win branch (c+1) and a loss branch (c-1). -/
def stepDist (winW : Nat → Nat) (d : Dist) : Dist :=
  d.foldl (init := []) fun acc (c, w) =>
    let p := winW c
    addWeight (addWeight acc (c + 1) (w * p)) (c - 1) (w * (1000 - p))

/-- Game A: win with probability 495/1000, regardless of capital. -/
def winA (_ : Nat) : Nat := 495

/-- Game B: win 95/1000 if capital ≡ 0 (mod 3), else win 745/1000. -/
def winB (c : Nat) : Nat := if c % 3 = 0 then 95 else 745

/-- Play `n` rounds, cycling through `sched`, starting from distribution `d`. -/
def playAux (sched : List (Nat → Nat)) : Nat → Nat → Dist → Dist
  | 0,     _, d => d
  | n + 1, i, d =>
      playAux sched n (i + 1) (stepDist (sched.getD (i % sched.length) winA) d)

/-- All capital starts at 99 (≡ 0 mod 3, and far from Nat-subtraction trouble). -/
def startCapital : Nat := 99

def play (sched : List (Nat → Nat)) (rounds : Nat) : Dist :=
  playAux sched rounds 0 [(startCapital, 1)]

/-- Exact expected capital of a distribution, rendered as a Float at the end. -/
def meanCapital (d : Dist) : Float :=
  let num := d.foldl (fun s cw => s + cw.1 * cw.2) 0
  let den := d.foldl (fun s cw => s + cw.2) 0
  Float.ofNat num / Float.ofNat den

#eval s!"Parrondo, mean capital after 50 rounds (start {startCapital}): A only = {meanCapital (play [winA] 50)} (losing), B only = {meanCapital (play [winB] 50)} (losing), alternate ABAB = {meanCapital (play [winA, winB] 50)} (winning!), AABB = {meanCapital (play [winA, winA, winB, winB] 50)} (winning!)"

/-
## 11. Jevons paradox / paradox of thrift  (economics)

NOTE only.  Jevons: making an engine more coal-efficient can increase
total coal consumption (efficiency lowers the effective price, demand
responds elastically).  Keynes's paradox of thrift: everyone saving more
can lower total savings (spending is income).  Both are macro/empirical
feedback claims whose content lies in elasticities and equilibrium
multipliers, not in a small self-contained logical core, so neither is
formalized here.
-/

/-- Catalog of this file's paradoxes and what was established for each. -/
def catalog : List (String × String) := [
  ("Prisoner's dilemma",
   "THEOREM: defection strictly dominates for every opponent choice, yet mutual cooperation Pareto-dominates mutual defection (decide)"),
  ("Tragedy of the commons",
   "NOTE: the n-player prisoner's dilemma; its logical core (dominance vs Pareto) is proved in item 1"),
  ("Condorcet paradox",
   "VERIFIED: with ballots A>B>C, B>C>A, C>A>B majority prefers A>B, B>C, C>A by 2:1 each — a cycle, so majority preference is provably not transitive (decide)"),
  ("Arrow's impossibility theorem",
   "NOTE: formalizable but a project in itself; the Condorcet cycle above is its seed"),
  ("Allais paradox",
   "THEOREM: the modal choices A-over-B and D-over-C are jointly unsatisfiable for every utility assignment u0 u1 u5 : Int (omega)"),
  ("Ellsberg paradox",
   "NOTE: ambiguity aversion — the Allais inconsistency pattern with subjective probabilities in place of utilities"),
  ("Newcomb's problem",
   "IDENTITY: two-boxing dominates by exactly 1000 in each box state — unfolds to the modeling definitions, the content is the model, not the derivation; the EV comparison stays VERIFIED: one-boxing's 100x-scaled expected value 99,000,000 beats two-boxing's 1,100,000 (both decide) — EDT and CDT provably disagree"),
  ("St. Petersburg paradox",
   "NOTE: cross-reference — formalized in this suite's Infinity file"),
  ("Braess's paradox",
   "THEOREM: 2000/2000 split at cost 6500 is an equilibrium; the instant the shortcut opens that split is destabilized — deviating to the shortcut pays 4001 < 6500 (braess_old_split_destabilized, the audit's missing load-bearing fact) — and all-on-the-shortcut is an equilibrium costing everyone 8000 (decide; its uniqueness is classical but not formalized here) — adding a road hurts all"),
  ("Parrondo's paradox",
   "DEMO: exact integer DP over the capital distribution — A-only and B-only drift down (98.5, 98.04) but ABAB alternation drifts up (99.46) after 50 rounds (#eval)"),
  ("Jevons paradox / paradox of thrift",
   "NOTE: macroeconomic/empirical feedback effects; no self-contained formal core")
]

private def countStatus (pfx : String) : Nat :=
  catalog.countP fun e => e.2.startsWith pfx

#eval s!"DecisionGames catalog: {catalog.length} paradoxes — {countStatus "THEOREM"} theorems, {countStatus "IDENTITY"} identity, {countStatus "VERIFIED"} verified, {countStatus "DEMO"} demo, {countStatus "NOTE"} notes"

end Paradoxes.DecisionGames
