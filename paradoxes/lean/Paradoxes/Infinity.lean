/-!
# Paradoxes of the Infinite

Machine-checked formalizations of classical paradoxes of infinity, spanning
mathematics (Galileo, Hilbert, Grandi, Gabriel's horn), motion (Zeno, the ant
on a rubber band, Aristotle's wheel), decision theory (St. Petersburg),
cosmology (Olbers), and supertasks (Ross–Littlewood, Thomson's lamp).

Core Lean 4 only — no Mathlib. Real analysis is avoided by scaling to exact
integer arithmetic inside theorems; `Rat` and `Float` appear only in `#eval`
demonstrations. Each paradox gets: a story, a precise formal statement, a
proof (or decidable verification / running demo), and its resolution.
-/

namespace Paradoxes.Infinity

/-! ## Shared helper -/

/-- Powers of two are positive (from core `Nat.pow_pos`). -/
theorem two_pow_pos (n : Nat) : 0 < 2 ^ n :=
  Nat.pow_pos (by decide)

/-
### 1. Galileo's paradox — mathematics (1638)

Story: Galileo observed that every natural number has a square (and every
square a root), so there seem to be "as many" squares as naturals — yet the
squares are a tiny, ever-thinner part of the naturals. Whole and part match
up perfectly. We use the evens (via n ↦ 2n) for the same effect.

Formalized: `double n = 2*n` is injective, lands only on even numbers, and
hits every even number — a bijection between Nat and a proper subset of Nat.

Resolution: for infinite collections, "equinumerous with a proper part" is
not a contradiction but the defining property (Dedekind's definition of
infinite). Size-by-pairing and size-by-inclusion simply come apart.
-/

/-- The pairing n ↦ 2n between all naturals and the even naturals. -/
def double (n : Nat) : Nat := 2 * n

/-- The pairing is injective: distinct naturals get distinct evens. -/
theorem double_injective : ∀ m n, double m = double n → m = n := by
  intro m n h
  simp only [double] at h
  omega

/-- The pairing lands inside the evens. -/
theorem double_mem_evens (n : Nat) : double n % 2 = 0 := by
  simp only [double]
  omega

/-- The pairing exhausts the evens: every even number is hit. -/
theorem double_onto_evens : ∀ m, m % 2 = 0 → ∃ n, double n = m := by
  intro m hm
  exact ⟨m / 2, by simp only [double]; omega⟩

#eval s!"Galileo: naturals {List.range 8}... pair exactly with the evens {(List.range 8).map double}... — whole ≈ proper part"

/-
### 2. Hilbert's Hotel — mathematics (Hilbert, 1924)

Story: a hotel with rooms 0, 1, 2, … is completely full. A newcomer arrives.
Every guest moves from room n to room n+1 — nobody is evicted, no two guests
share, and room 0 is now empty. When an infinite bus arrives, guests move
from n to 2n, freeing every odd room at once.

Formalized: `shift n = n+1` is injective and misses room 0; `double` is
injective and misses every odd room. Packaged as: Nat admits an injective,
non-surjective self-map — Nat is Dedekind-infinite.

Resolution: "full" (every room occupied) and "cannot accommodate more" are
equivalent only for finite hotels. Injections of an infinite set into itself
can waste as much room as we like.
-/

/-- Every guest moves up one room. -/
def shift (n : Nat) : Nat := n + 1

/-- No two guests end up in the same room. -/
theorem shift_injective : ∀ m n, shift m = shift n → m = n := by
  intro m n h
  simp only [shift] at h
  omega

/-- Room 0 is left empty for the newcomer. -/
theorem shift_frees_room_zero (n : Nat) : shift n ≠ 0 := by
  simp only [shift]
  omega

/-- Moving guests to 2n leaves every odd room empty: infinitely many vacancies. -/
theorem double_frees_all_odd_rooms : ∀ m, m % 2 = 1 → ∀ n, double n ≠ m := by
  intro m hm n h
  simp only [double] at h
  omega

/-- Dedekind: Nat is infinite — it has an injective self-map that misses a point. -/
theorem nat_dedekind_infinite :
    ∃ f : Nat → Nat, (∀ m n, f m = f n → m = n) ∧ ¬ Function.Surjective f := by
  refine ⟨shift, shift_injective, fun hsurj => ?_⟩
  cases hsurj 0 with
  | intro n hn => exact shift_frees_room_zero n hn

#eval s!"Hilbert: full hotel, rooms {List.range 8}...; all guests shift n↦n+1 into {(List.range 8).map shift}... — room 0 freed for the newcomer"
#eval s!"Hilbert: infinite bus arrives; guests move n↦2n into {(List.range 8).map double}... — every odd room is now free"

/-
### 3. Zeno's dichotomy and Achilles — motion (5th c. BC)

Story: to cross a unit distance the runner must first cross half, then half
the remainder, and so on — infinitely many tasks, so (says Zeno) motion is
impossible. Achilles, running at speed 2, can never catch a tortoise of
speed 1 that starts 1 ahead: whenever he reaches where it was, it has moved.

Formalized (scaled by 2^n to stay in Nat): `covered n = Σ_{k<n} 2^k` encodes
the distance 1/2 + 1/4 + … + 1/2^n after n stages, scaled by 2^n. We prove
covered n + 1 = 2^n: every stage strictly advances (at the common scale
2^(n+1): 2·covered n < covered (n+1)), the remaining gap is always exactly
1 scaled unit (= 1/2^n, positive), yet the total stays below the scaled
goal 2^n. Achilles: position 2t vs 1+t (scaled by any d):
strictly behind for t < d, meets exactly at t = d, ahead after.

Resolution: infinitely many positive steps can have a finite total; the
geometric series converges. "Infinitely many tasks" is not "infinite time".
Achilles' pursuit determines a definite finite meeting time t = 1.
-/

/-- Distance covered after n Zeno stages, scaled by 2^n (stage k contributes 2^k). -/
def covered : Nat → Nat
  | 0 => 0
  | n + 1 => covered n + 2 ^ n

/-- Closed form: covered n = 2^n − 1, i.e. the runner is at 1 − 1/2^n. -/
theorem covered_add_one (n : Nat) : covered n + 1 = 2 ^ n := by
  induction n with
  | zero => decide
  | succ k ih =>
    have hp : 2 ^ (k + 1) = 2 ^ k * 2 := by rw [Nat.pow_succ]
    simp only [covered]
    omega

/-- Every single stage makes strictly positive progress: infinitely many real
    steps.  Compared at the common scale 2^(n+1) — i.e. 2·covered n vs
    covered (n+1) — the position strictly increases (a stalled runner at a fixed
    position c would give equality 2·(c·2^n) = c·2^(n+1), not <). -/
theorem zeno_every_step_pos (n : Nat) : 2 * covered n < covered (n + 1) := by
  have h := covered_add_one n
  simp only [covered]
  omega

/-- Yet the runner never arrives at any finite stage: total below the goal. -/
theorem zeno_never_arrives (n : Nat) : covered n < 2 ^ n := by
  have h := covered_add_one n
  omega

/-- The remaining gap is always exactly one scaled unit, i.e. 1/2^n > 0. -/
theorem zeno_gap_exact (n : Nat) : 2 ^ n - covered n = 1 := by
  have h := covered_add_one n
  omega

/-- Achilles (speed 2) is strictly behind the tortoise (speed 1, head start d)
    at every scaled time t < d … -/
theorem achilles_behind (d t : Nat) (h : t < d) : 2 * t < d + t := by omega

/-- … catches it exactly at t = d (unscaled: t = 1) … -/
theorem achilles_meets (d : Nat) : 2 * d = d + d := by omega

/-- … and is strictly ahead ever after. Zeno's regress halts at a definite time. -/
theorem achilles_passes (d t : Nat) (h : d < t) : d + t < 2 * t := by omega

#eval (List.range 8).map fun n => s!"Zeno stage {n}: covered {1 - mkRat 1 (2^n)} of the course, gap {mkRat 1 (2^n)}"

/-
### 4. Grandi's series (and Thomson's lamp) — mathematics / supertask

Story: what is 1 − 1 + 1 − 1 + …? Grouping as (1−1)+(1−1)+… gives 0;
as 1+(−1+1)+(−1+1)+… gives 1; Grandi (1703) even argued for 1/2. Thomson's
lamp: toggle a lamp at 1/2 min, 3/4, 7/8, … — after one minute, on or off?

Formalized: the partial sums `grandi n` satisfy grandi n = n % 2 exactly, so
grandi (2N) = 0 and grandi (2N+1) = 1 for every N: beyond any point the
sequence still takes both values 0 and 1 — it has no limit.

Resolution: infinite sums are limits of partial sums, and this one has none;
regrouping/associativity is only guaranteed for convergent series. Thomson's
lamp NOTE: the lamp state after the supertask *is* the limit of this
sequence, so the story's question has no determinate answer — the state at
2 minutes is simply not defined by the sequence of toggles before it.
-/

/-- Partial sums of Grandi's series 1 − 1 + 1 − 1 + … -/
def grandi : Nat → Int
  | 0 => 0
  | n + 1 => grandi n + (if n % 2 = 0 then 1 else -1)

/-- Exact oscillation: the n-th partial sum is n % 2. -/
theorem grandi_eq (n : Nat) : grandi n = ((n % 2 : Nat) : Int) := by
  induction n with
  | zero => decide
  | succ k ih =>
    simp only [grandi]
    rw [ih]
    split
    · omega
    · omega

/-- Even partial sums are 0 forever … -/
theorem grandi_even (N : Nat) : grandi (2 * N) = 0 := by
  rw [grandi_eq]; omega

/-- … odd partial sums are 1 forever. -/
theorem grandi_odd (N : Nat) : grandi (2 * N + 1) = 1 := by
  rw [grandi_eq]; omega

/-- No limit: past every index the sums still take both values 0 and 1. -/
theorem grandi_no_limit :
    ∀ N, ∃ i j, N ≤ i ∧ N ≤ j ∧ grandi i = 0 ∧ grandi j = 1 :=
  fun N => ⟨2 * N, 2 * N + 1, by omega, by omega, grandi_even N, grandi_odd N⟩

#eval s!"Grandi partial sums: {(List.range 12).map fun n => grandi n} — oscillates 0,1 forever, no limit (Thomson's lamp: state 'at 2 min' would be this non-existent limit)"

/-
### 5. St. Petersburg paradox — decision theory (N. Bernoulli 1713)

Story: a fair coin is flipped until the first head; if that happens on flip
k you are paid 2^k. Expected value: Σ 2^k · (1/2^k) = 1 + 1 + 1 + … = ∞.
So a rational agent should pay any finite entry fee — yet nobody would pay
even 50, since half the time the game pays only 2.

Formalized: `stPetersEV n`, the expected payoff of the game truncated at n
rounds, where round k contributes payoff 2^k times probability 1/2^k written
as exact Nat division 2^k / 2^k. Theorem: stPetersEV n = n — each round adds
exactly 1 — hence the truncated EV exceeds every bound M. A `decide` check
verifies the sum-over-outcomes form: among 2^10 equally likely flip
sequences, Σ_k (payoff 2^k)·(number of sequences with first head at k)
= 10 · 2^10.

Resolution: expected value is the wrong guide here. Bounded utility
(Bernoulli's log), or the banker's finite bankroll, truncates the game at
some n, and the fair price stPetersEV n = n grows only logarithmically in
the bankroll 2^n — a 2^40 bankroll justifies an entry fee of about 40.
-/

/-- Expected payoff of the game truncated at n rounds: round k+1 adds
    payoff 2^(k+1) times probability 1/2^(k+1), as exact Nat division. -/
def stPetersEV : Nat → Nat
  | 0 => 0
  | n + 1 => stPetersEV n + 2 ^ (n + 1) / 2 ^ (n + 1)

/-- Each round contributes exactly 1: the truncated EV is n. -/
theorem stPetersEV_eq (n : Nat) : stPetersEV n = n := by
  induction n with
  | zero => rfl
  | succ k ih =>
    have h : 2 ^ (k + 1) / 2 ^ (k + 1) = 1 := Nat.div_self (two_pow_pos (k + 1))
    simp only [stPetersEV]
    omega

/-- The 'fair price' of the untruncated game exceeds every finite bound. -/
theorem stPetersEV_unbounded : ∀ M, ∃ n, stPetersEV n > M := by
  intro M
  exact ⟨M + 1, by rw [stPetersEV_eq]; omega⟩

/-- Sum-over-outcomes check (n = 10): payoff 2^(k+1) times the 2^(10-(k+1))
    length-10 flip sequences whose first head is at flip k+1, summed over
    rounds, equals 10 · 2^10 — EV = 10 after dividing by the 2^10 outcomes. -/
example : ((List.range 10).map (fun k => 2 ^ (k + 1) * 2 ^ (10 - (k + 1)))).sum
    = 10 * 2 ^ 10 := by decide

#eval (List.range 6).map fun k =>
  s!"St. Petersburg round {k+1}: probability 1/{2^(k+1)}, payoff {2^(k+1)}, EV contribution 1"
#eval s!"St. Petersburg: truncated EV grows without bound: {(List.range 7).map (fun n => stPetersEV (10*n))} at n = 0,10,...,60 rounds"

/-
### 6. Olbers' paradox — cosmology (Olbers 1823)

Story: if the universe is infinite, eternal, and uniformly filled with
stars, then every line of sight ends on a star, and the night sky should
blaze like the surface of the sun. It is dark. Contradiction.

Formalized: partition space into concentric shells of equal thickness.
Shell k holds ~(k+1)² stars (area grows quadratically) each appearing
1/(k+1)² as bright (inverse-square law): `shellGlow b k = ((k+1)²·b)/(k+1)²
= b`, a constant per shell. Total from n shells: `skyBrightness b n = n·b`,
which exceeds every bound M — the assumptions entail an infinitely bright sky.

Resolution: the dark night sky is *evidence*: the observable universe is not
an eternal static infinity of stars. Finite age (light from beyond ~14 Gly
hasn't arrived) and cosmological redshift cut the sum down to a finite — and
small — total. Darkness at night is data about cosmology.
-/

/-- Glow of shell k: (k+1)² stars, each dimmed by 1/(k+1)² — quadratic area
    times inverse-square falloff, in exact Nat division. -/
def shellGlow (b k : Nat) : Nat := ((k + 1) * (k + 1) * b) / ((k + 1) * (k + 1))

/-- Every shell contributes the same constant glow b, however distant. -/
theorem shellGlow_const (b k : Nat) : shellGlow b k = b := by
  have hpos : 0 < (k + 1) * (k + 1) := Nat.mul_pos (by omega) (by omega)
  simp only [shellGlow]
  exact Nat.mul_div_cancel_left b hpos

/-- Total brightness from the innermost n shells. -/
def skyBrightness (b : Nat) : Nat → Nat
  | 0 => 0
  | n + 1 => skyBrightness b n + shellGlow b n

/-- Closed form: n shells glow n·b. -/
theorem skyBrightness_eq (b n : Nat) : skyBrightness b n = n * b := by
  induction n with
  | zero => simp only [skyBrightness]; omega
  | succ k ih =>
    simp only [skyBrightness]
    rw [ih, shellGlow_const, Nat.add_mul]
    omega

/-- An eternal static infinite starry universe outshines every bound:
    the dark night sky refutes the assumptions. -/
theorem olbers_unbounded (b : Nat) (hb : 1 ≤ b) : ∀ M, ∃ n, skyBrightness b n > M := by
  intro M
  refine ⟨M + 1, ?_⟩
  rw [skyBrightness_eq]
  have h := Nat.le_mul_of_pos_right (M + 1) hb
  omega

#eval s!"Olbers (per-shell glow b=3): sky brightness after n shells: {(List.range 8).map (skyBrightness 3)} — unbounded; the sky is dark, so the premises are false"

/-
### 7. Ant on a rubber band — motion / analysis

Story: an ant walks 1 cm per day along a 4 cm rubber band; each night the
band stretches uniformly by another 4 cm. The ant seems doomed — the goal
recedes faster than it walks. Yet it arrives: the *fraction* of the band it
gains on day d is 1/(4d), and the harmonic series 1/4·(1 + 1/2 + 1/3 + …)
diverges, so the accumulated fraction passes 1 in finitely many days.

Formalized: running `#eval` demo over exact rationals: antFrac (d+1) =
antFrac d + 1/(4(d+1)); we watch it cross 1 at day 31 (H₃₁ ≈ 4.027 > 4).

Resolution (why a demo, not a theorem): the crossing day is a concrete
computation; the general theorem is harmonic divergence, demonstrated for
this instance by exact Rat arithmetic executed at compile time. Divergence
guarantees arrival for *any* walking speed and stretch rate.
-/

/-- Fraction of the (ever-stretching) band covered after d days. -/
def antFrac : Nat → Rat
  | 0 => 0
  | d + 1 => antFrac d + mkRat 1 (4 * (d + 1))

/-- Decimal view of `antFrac` for readable output. -/
def antFracFloat (d : Nat) : Float :=
  (antFrac d).num.toNat.toFloat / (antFrac d).den.toFloat

#eval ([1, 5, 10, 20, 30, 31].map fun d =>
  s!"ant, day {d}: fraction {antFracFloat d} of the band")
#eval s!"ant first completes the band on day {((List.range 40).find? (fun d => decide (((antFrac d).den : Int) ≤ (antFrac d).num))).getD 0} (exact Rat: antFrac 31 = {antFrac 31})"

/-
### 8. Gabriel's horn / painter's paradox — mathematics (Torricelli 1643)

Story: revolve y = 1/x (x ≥ 1) around the x-axis. The horn's volume is
π·Σ-like ∫1/x² dx = π (finite) but its surface area ≥ 2π·∫1/x dx = ∞.
You can fill it with paint, but you can never paint it.

Formalized: discretized `#eval` demo in Float — the volume-like partial sums
Σ 1/k² stay below 2 (indeed → π²/6 ≈ 1.645) while the surface-like partial
sums Σ 1/k pass any bound.

NOTE (calculus statement): the integral formulation needs real analysis
(∫₁^∞ dx/x² = 1 < ∞, ∫₁^∞ dx/x = ∞), which is out of reach without a real
number library; the series discretization carries the same convergent-vs-
divergent contrast. Resolution: 'paint' of the thought experiment has zero
thickness; finite volume with infinite area is consistent because the horn
thins faster than its skin shrinks.
-/

/-- Discretized volume: partial sums of Σ 1/k² (converges, < 2). -/
def hornVolumeProxy (n : Nat) : Float :=
  (List.range n).foldl (fun acc k => acc + 1.0 / ((k+1).toFloat * (k+1).toFloat)) 0.0

/-- Discretized surface: partial sums of Σ 1/k (diverges). -/
def hornSurfaceProxy (n : Nat) : Float :=
  (List.range n).foldl (fun acc k => acc + 1.0 / (k+1).toFloat) 0.0

#eval ([10, 100, 1000, 10000].map fun n =>
  s!"horn, n={n}: volume-proxy Σ1/k² = {hornVolumeProxy n} (stays < 2), surface-proxy Σ1/k = {hornSurfaceProxy n} (passes any bound)")

/-
### 9. Ross–Littlewood supertask — mathematics / supertask (1953)

Story: at step n, balls 10(n−1)+1 … 10n are added to an urn and ball n is
removed. After all infinitely many steps: the urn's size marched 9, 18, 27,
… towards infinity — yet every single ball k was removed at step k, so the
urn is empty. Infinitely many balls and none at all?

Formalized: `inUrn b n` (ball b present after step n) := n < b ∧ b ≤ 10n.
Theorems: (a) after step n the 9n distinct balls n+1+i (i < 9n) are all
present — cardinality 9n → ∞; (b) for every ball b there is a step (namely
b) after which it is never present again — the limit set is empty.

Resolution / NOTE: the 'limit of the sets' (pointwise: which balls remain)
is ∅, while the 'limit of the cardinalities' is ∞. Cardinality is not
continuous with respect to pointwise set limits: lim |Sₙ| ≠ |lim Sₙ|. Both
answers are correct — to different questions.
-/

/-- Ball b (numbered from 1) is in the urn after step n: it has been added
    (b ≤ 10n) and not yet removed (removal of ball b happens at step b ≤ n). -/
def inUrn (b n : Nat) : Prop := n < b ∧ b ≤ 10 * n

/-- After step n, the 9n distinct balls n+1, n+2, …, 10n are all present:
    the urn's cardinality grows without bound. -/
theorem urn_swells (n i : Nat) (hi : i < 9 * n) : inUrn (n + 1 + i) n :=
  ⟨Nat.lt_of_lt_of_le (Nat.lt_succ_self n) (Nat.le_add_right (n + 1) i),
   Nat.add_assoc n 1 i ▸ Nat.add_comm 1 i ▸ Nat.succ_mul 9 n ▸
     Nat.add_comm n (9 * n) ▸ Nat.add_le_add_left hi n⟩

-- Axiom hygiene (external audit): the previous automated proof
-- (`simp only [inUrn]; omega`) accidentally dragged in `Classical.choice`;
-- even bare `omega` still leaves `propext`/`Quot.sound` behind, so the
-- anonymous-constructor proof above is written in plain terms from core
-- `Nat` lemmas and depends on NO axioms at all — machine-published by
-- `#print axioms` in `Paradoxes/Audit.lean` at every build.

/-- Those witnesses really are 9n *distinct* balls. -/
theorem urn_swells_inj (n i j : Nat) (h : n + 1 + i = n + 1 + j) : i = j := by omega

/-- Yet every individual ball is eventually gone forever: the limit set is empty. -/
theorem every_ball_gone (b : Nat) : ∃ N, ∀ n, N ≤ n → ¬ inUrn b n := by
  refine ⟨b, fun n hn h => ?_⟩
  simp only [inUrn] at h
  omega

/-- Concrete check, step 4: balls 5..40 are present — exactly 9·4 = 36 of them. -/
example : ((List.range 41).countP fun b => decide (4 < b ∧ b ≤ 40)) = 36 := by decide

#eval s!"Ross–Littlewood: urn sizes after each step: {(List.range 8).map (fun n => 9*n)} → ∞, yet ball k leaves at step k and never returns: limit set = ∅"

/-
### 10. Aristotle's wheel — motion (Mechanica, ~4th c. BC)

Story: two concentric circles rigidly joined roll one full turn. Both trace
the same horizontal distance — the circumference of the big circle. So the
small circle 'unrolls' a line longer than its own circumference. How can a
short circle roll out a long line?

NOTE (why not a theorem here): the honest statement matches *points* of two
segments of different length by x ↦ 2x, a bijection [0,1] ↔ [0,2]. Proving
injectivity/cancellation for that map over core `Rat` needs field lemmas
(mul_left_cancel etc.) that core does not ship and that would amount to
rebuilding rational field algebra; the Nat/Int shadow of the statement is
already Galileo's theorem above (`double_injective`/`double_onto_evens`).
So we keep the continuous version as `#eval` spot-checks: doubling matches
sample points of [0,1] to [0,2], and halving inverts it exactly.

Resolution: length is not cardinality. Both segments have equally many
points, but measure is not counted point-by-point. Kinematically, the small
circle does not roll without slipping — it is dragged — so the line it
traces is not its unrolled circumference.
-/

#eval s!"Aristotle's wheel: sample points of [0,1] ↔ [0,2] by x↦2x: {([0,1,2,3,4].map fun k => s!"{mkRat k 4}↦{2 * mkRat k 4}")}"
#eval s!"halving inverts doubling on all samples: {[0,1,2,3,4].all fun k => decide (2 * mkRat k 4 / 2 = mkRat k 4)} — same points, twice the length"

/-! ## Catalog -/

/-- One entry per paradox: (name, status + what was shown). -/
def catalog : List (String × String) := [
  ("Galileo's paradox",
   "THEOREM: n ↦ 2n is an injection of Nat onto its proper subset of evens — whole equinumerous with part (Dedekind-infinite)."),
  ("Hilbert's Hotel",
   "THEOREM: shift n+1 is injective and misses room 0 (full hotel admits a newcomer); n ↦ 2n frees every odd room; Nat proved Dedekind-infinite."),
  ("Zeno: dichotomy & Achilles",
   "THEOREM: scaled sums give covered n + 1 = 2^n — every stage strictly advances, the gap 1/2^n stays positive, the total stays bounded; Achilles trails for t<1, meets at t=1, passes after."),
  ("Grandi's series 1−1+1−…",
   "THEOREM: partial sums equal n % 2 — 0,1,0,1,… forever, so no limit exists; regrouping fails for divergent series (Thomson's lamp NOTE: the lamp's final state is this non-existent limit)."),
  ("St. Petersburg paradox",
   "THEOREM: truncated expected value stPetersEV n = n, unbounded in n; VERIFIED sum-over-outcomes instance at n=10 by decide; resolution: bounded utility / finite bankroll."),
  ("Olbers' paradox",
   "THEOREM: each shell glows constant b ≥ 1 (quadratic star count × inverse-square dimming), so n shells glow n·b > any M — the dark night sky refutes an eternal static infinite starfield."),
  ("Ant on a rubber band",
   "DEMO: exact-Rat #eval — daily fractions 1/(4d) accumulate past 1 on day 31; harmonic divergence guarantees arrival for any stretch rate."),
  ("Gabriel's horn",
   "DEMO: Float #eval — volume-proxy Σ1/k² stays below 2 while surface-proxy Σ1/k passes any bound; NOTE: the integral statement needs real analysis."),
  ("Ross–Littlewood supertask",
   "THEOREM: after step n the urn provably holds 9n distinct balls, yet every ball is eventually gone forever — lim |Sₙ| = ∞ while |lim Sₙ| = 0."),
  ("Aristotle's wheel",
   "NOTE: x ↦ 2x matches the points of segments of different length (Rat #eval spot-checks; halving inverts exactly); core Rat lacks the field lemmas for the continuous proof — length is not cardinality.")
]

#eval catalog.map fun (name, status) => s!"{name} — {status}"

end Paradoxes.Infinity
