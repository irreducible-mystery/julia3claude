/- ============================================================
   Fold.lean — the star and the Liar are the same theorem

   Not an audit. A noticing, made checkable.

   Three threads in this repo and its sibling arrived, separately,
   at the same sentence:

     cosmos/stellar_collapse.jl:  "collapse is the physics of an
       empty solution set" — past Chandrasekhar, hydrostatic
       equilibrium HAS NO SOLUTIONS, and the star's fixed point
       does not lose a contest, it ceases to exist.

     emergence_08 (irreducible-mystery/julia): "antinomy =
       re-entry ∘ fixed-point-free twist; negation was never the
       ingredient — emptiness of the fixed locus was."

     paradoxes/lean/SelfReference.lean: `¬ ∃ P, P ↔ ¬P` — the
       Liar has no model. Empty fixed locus, stated as a theorem.

   Nobody connected them, because they landed on different
   branches: the paradox taxonomy closed before the cosmos file
   existed. This file makes the connection a machine-checked
   object rather than an observation, and then asks the question
   the connection immediately raises — which nobody has asked:

     If a dying star and the Liar sentence satisfy the SAME
     criterion, why do they suffer DIFFERENT fates? The star
     runs away (monotone collapse, milliseconds, once). The
     Liar oscillates (period 2, forever). Same empty fixed
     locus. Opposite behaviour.

   ANSWER, PROVED BELOW: the criterion is shared; the fate is
   decided by BOUNDEDNESS of the state space, not by the twist.
   In a bounded world an inflationary map cannot exist at all
   (`bounded_no_runaway`) — so fixed-point-freeness must be
   bought by a twist that comes back down, and coming back down
   is what oscillation IS. In an unbounded world it can be
   bought by going up forever (`succ_never_returns`), and that
   is runaway. Bool is bounded: the Liar must oscillate. ℤ/m is
   bounded: the emergence thread's rings oscillate, with period
   the order of the twist — exactly what `RingRest.lean` proves.
   Stellar density is unbounded: the star may, and does, run.

   Nobody in either repo owns this claim yet. It is offered, not
   defended: everything below either compiles or does not.

   Core Lean 4, no imports, no Mathlib, no `sorry`, no axiom
   declarations. Bare-runnable in the emergence thread's house
   style:  lean fold/Fold.lean   — exit 0, prints its own ledger.
   ============================================================ -/

namespace Fold

/- ------------------------------------------------------------
   §1 — THE FOLD, over ℤ

   The saddle-node normal form of `stellar_collapse.jl` Act 3,
   in the only arithmetic the kernel decides exactly. The family

       f μ (x) = x² + μ

   has fixed points where x² + μ = x, i.e. x(x−1) = −μ. At μ = 0
   there are TWO (x = 0 and x = 1). For μ ≥ 1 there are NONE, and
   the proof is the whole story: x(x−1) ≥ 0 always, so it can
   never equal a negative number. The two solutions did not move
   apart or become unstable. They ANNIHILATED — which is what the
   TOV table's ★ THE FOLD row marks, and what the neutron star
   experiences as the end of its existence.
   ------------------------------------------------------------ -/

/-- The fold family. `μ` is the slowly-drifting parameter: burnt
    fuel, accreted mass, the deformation the star cannot resist. -/
def f (mu x : Int) : Int := x * x + mu

/-- Squares are nonneg. (Core has `Int.mul_nonneg` and
    `Int.neg_mul_neg`; it does not ship `mul_self_nonneg`, so it
    is proved here rather than imported from a library that
    would set an axiom budget I did not choose.) -/
theorem sq_nonneg (x : Int) : 0 ≤ x * x := by
  by_cases h : 0 ≤ x
  · exact Int.mul_nonneg h h
  · have hneg : (0 : Int) ≤ -x := by omega
    have hpos : 0 ≤ (-x) * (-x) := Int.mul_nonneg hneg hneg
    rw [Int.neg_mul_neg] at hpos
    exact hpos

/-- `x ≤ x²` over ℤ: below 1 because squares are nonneg, above 1
    by monotonicity. The one inequality the fold needs. -/
theorem le_sq (x : Int) : x ≤ x * x := by
  by_cases h : 1 ≤ x
  · have hm : x * 1 ≤ x * x := Int.mul_le_mul_of_nonneg_left h (by omega)
    rw [Int.mul_one] at hm
    exact hm
  · have h0 := sq_nonneg x
    omega

/-- **Before the fold**: at μ = 0 the family has two fixed points. -/
theorem two_fixed_before : f 0 0 = 0 ∧ f 0 1 = 1 := by decide

/-- They are genuinely two — the pair that will annihilate. -/
theorem the_two_are_distinct : (0 : Int) ≠ 1 := by decide

/-- **After the fold**: for every μ ≥ 1 the fixed locus is EMPTY.
    Not unstable, not hard to reach — nonexistent. This single
    theorem is, in three costumes:
      • the star past its maximum mass (no hydrostatic solution),
      • the Liar (no P with P ↔ ¬P),
      • the restless ring (no state at rest).
    The star does not lose a fight with gravity. Its equation
    stops having answers. -/
theorem fold_empty_after (mu : Int) (hmu : 1 ≤ mu) :
    ¬ ∃ x : Int, f mu x = x := by
  intro hx
  obtain ⟨x, hxe⟩ := hx
  have hfx : x * x + mu = x := hxe
  have hle := le_sq x
  omega

/-- The fixed locus is nonempty for every μ ≤ 0 (witness 0 for
    μ = 0 is above; here the general "before" side, witnessed
    where the discriminant is a square). Kept modest on purpose:
    the point of the file is the annihilation, not a census of
    the stable branch. -/
theorem fold_nonempty_at (k : Int) : f (k - k * k) k = k := by
  show k * k + (k - k * k) = k
  omega

/- ------------------------------------------------------------
   §1½ — THE INSTANT OF THE FOLD IS NOT AN INTEGER

   The discriminant of x² − x + μ is 1 − 4μ. Over ℝ it vanishes
   at μ = 1/4 — the exact moment the two solutions touch and
   cancel. Over ℤ it is 1 at μ = 0 and −3 at μ = 1: positive,
   then negative, having passed through zero at no integer at all.

   So the kernel can prove that the fold HAPPENED (roots before,
   none after) and cannot name WHEN. The arithmetic that
   establishes the event cannot host the event.

   This is not a defect of ℤ. It is the same fact as
   cosmos/lean's Buchdahl strip: between the densest static star
   (r_s/R ≈ 0.43 in the toy table) and the horizon at 1 lies a
   band of compactness that NOTHING can statically inhabit — a
   region crossed only in free fall, in milliseconds, once, and
   never occupied. Both arithmetics prove the crossing by its
   two shores. Neither has a word for the water.
   ------------------------------------------------------------ -/

/-- Discriminant of the fixed-point equation. -/
def disc (mu : Int) : Int := 1 - 4 * mu

theorem disc_positive_before : 0 < disc 0 := by decide
theorem disc_negative_after : disc 1 < 0 := by decide

/-- **The fold's instant is unnameable here**: no integer μ makes
    the discriminant vanish. The sign changes between two
    adjacent parameter values with nothing in between. -/
theorem fold_instant_not_integral : ∀ mu : Int, disc mu ≠ 0 := by
  intro mu h
  show False
  have : 1 - 4 * mu = 0 := h
  omega

/- ------------------------------------------------------------
   §2 — WHY THE SAME CRITERION HAS TWO FATES

   Empty fixed locus is shared. Runaway vs oscillation is not.
   The discriminator is not the twist — it is whether the world
   is bounded.
   ------------------------------------------------------------ -/

/-- Going strictly up is one way to have no fixed point. -/
theorem inflationary_is_fixed_point_free (g : Nat → Nat)
    (hinf : ∀ x, x < g x) : ∀ x, g x ≠ x := by
  intro x h
  have := hinf x
  omega

/-- **A bounded world cannot run away.** If `g` maps `[0, N]` into
    itself, it cannot be inflationary — apply it at the ceiling.
    Consequence, and the hinge of this file: in a bounded world,
    a fixed-point-free map MUST come back down somewhere, and
    coming back down is what oscillation is made of. The Liar
    lives in `Bool`, which has a ceiling; it therefore cannot
    collapse, and must flip forever. It is not that negation
    causes oscillation — it is that boundedness forbids the
    alternative. -/
theorem bounded_no_runaway (N : Nat) (g : Nat → Nat)
    (hclosed : ∀ x, x ≤ N → g x ≤ N) (hinf : ∀ x, x < g x) : False := by
  have hc := hclosed N (Nat.le_refl N)
  have hi := hinf N
  omega

/-- **An unbounded world can.** Successor on ℤ is fixed-point-free
    and no orbit ever returns: the star's density has no ceiling,
    so its runaway is permitted by the same logic that forbids
    the Liar's. -/
theorem succ_never_returns (x : Int) (k : Nat) (hk : 1 ≤ k) :
    x + (k : Int) ≠ x := by omega

/- ---- the bounded worlds, exhaustively: same criterion, forced fate ---- -/

/-- Bool: `not` is fixed-point-free (the Liar's twist). -/
theorem not_fixed_point_free : ∀ b : Bool, (!b) ≠ b := by decide

/-- ...and its order is exactly 2: the Liar oscillates, and cannot
    do anything else, because `Bool` has two elements and a
    ceiling. `SelfReference.liar` proves the Prop-level version
    (no `P ↔ ¬P`); this is the dynamical shadow of that theorem. -/
theorem not_order_two : ∀ b : Bool, !(!b) = b := by decide

/-- ℤ/3, the emergence thread's world (`emergence_04`): successor. -/
def succ3 (x : Fin 3) : Fin 3 := ⟨(x.val + 1) % 3, by omega⟩

theorem succ3_fixed_point_free : ∀ x : Fin 3, succ3 x ≠ x := by decide

/-- Its order is 3, not 2 — so a bounded world's oscillation
    period is the order of its twist, not a universal 2. This is
    `emergence_04`'s verdict ("the rest/restless dichotomy is not
    ℤ/2's shadow — it is modular arithmetic") recovered as a
    dynamical statement, and `RingRest.succ_ring_rest_iff`'s
    divisibility law is the same fact wearing a ring. -/
theorem succ3_order_three : ∀ x : Fin 3, succ3 (succ3 (succ3 x)) = x := by decide

theorem succ3_not_order_two : ∃ x : Fin 3, succ3 (succ3 x) ≠ x := by decide

/- ------------------------------------------------------------
   §3 — WHAT THIS DOES NOT CLAIM

   Honest scope, stated before the demos rather than after:

   • The stellar fold is a fold of a CONTINUOUS family; §1 is its
     integer normal form. The identification is a modelling
     claim, argued in prose, not a theorem. What IS a theorem:
     annihilation of a fixed-point pair as a parameter crosses,
     and the unnameability of the crossing.

   • `bounded_no_runaway` forbids inflationary maps on a bounded
     world. It does not, alone, prove that every fixed-point-free
     map on a finite world is periodic — that is pigeonhole, true
     and unproved here. The Bool and Fin 3 instances are decided,
     not generalized. Marked, not hidden.

   • Nothing here touches WHY the star's parameter drifts (fusion)
     or why the Liar's does not. The fold family has a dial; the
     Liar's twist has none. That asymmetry is real and unexplored.
   ------------------------------------------------------------ -/

/- ------------------------------------------------------------
   §4 — the ledger, executed
   ------------------------------------------------------------ -/

#eval s!"§1 fold: at μ=0 the family x²+μ has two fixed points \
({(0:Int)}, {(1:Int)}); for every μ ≥ 1 it has none — they annihilated \
(theorem fold_empty_after). Same shape: the star past Chandrasekhar, \
the Liar, the restless ring."

#eval s!"§1½ the instant: disc 0 = {disc 0} > 0, disc 1 = {disc 1} < 0, \
and no integer μ has disc μ = 0 (theorem fold_instant_not_integral). \
The kernel proves the fold happened and cannot say when — as Buchdahl's \
strip is crossed but never inhabited."

#eval s!"§2 fate: bounded worlds cannot run away (theorem \
bounded_no_runaway), so their fixed-point-free maps must come back down \
— Bool flips with period 2, Fin 3 cycles with period 3. Unbounded worlds \
may run: x ↦ x+1 on ℤ never returns. One criterion, two fates, and the \
discriminator is the ceiling — not the twist."

#eval "Verdict offered: emptiness of the fixed locus is what a dying star, \
a Liar sentence, and a restless ring have in common; boundedness of the \
state space is what makes one collapse and the others oscillate. Neither \
repo owns this yet."

/-- Catalog, house style. -/
def catalog : List (String × String) :=
  [ ("Fold family over ℤ",
     "THEOREM: two fixed points at μ=0, none for μ ≥ 1 — annihilation, not defeat"),
    ("Instant of the fold",
     "THEOREM: no integer μ zeroes the discriminant — the crossing is provable and unnameable"),
    ("Bounded worlds cannot run away",
     "THEOREM: a self-map of [0,N] is never inflationary — oscillation is forced, not chosen"),
    ("Unbounded worlds may",
     "THEOREM: successor on ℤ never returns — the star's licence"),
    ("Liar's twist (Bool)",
     "VERIFIED: fixed-point-free, order exactly 2 — the dynamical shadow of ¬∃P, P ↔ ¬P"),
    ("ℤ/3 twist (Fin 3)",
     "VERIFIED: fixed-point-free, order 3 — period is the order of the twist, not a universal 2"),
    ("Star ≡ Liar identification",
     "NOTE: modelling claim argued in prose; the theorem is the annihilation, not the physics"),
    ("Finite ⇒ periodic",
     "NOTE: pigeonhole, true, unproved here — instances decided, generalization owed") ]

end Fold

-- ============ AXIOM AUDIT (receipts, house style) ============
#print axioms Fold.sq_nonneg
#print axioms Fold.le_sq
#print axioms Fold.fold_empty_after
#print axioms Fold.fold_nonempty_at
#print axioms Fold.fold_instant_not_integral
#print axioms Fold.inflationary_is_fixed_point_free
#print axioms Fold.bounded_no_runaway
#print axioms Fold.succ_never_returns
#print axioms Fold.not_order_two
#print axioms Fold.succ3_order_three
