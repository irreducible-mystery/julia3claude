/-!
# Diagonalization Paradoxes — Set Theory and Computability

One trick, many costumes.  Given any purported *total* listing
`f : A → (A → Prop)` (or `→ Bool`, or a "set of all sets", or a "game of all
games"), build the diagonal object that differs from `f x` exactly at the
point `x` — then ask where the diagonal itself lives.  The answer is always
of the shape `P ↔ ¬ P`.

This file proves the classical diagonal paradoxes as theorems of core Lean 4
(no Mathlib): Russell, the Barber, Cantor's theorem and Cantor's paradox,
Berry (finitist core), the halting-problem diagonal (which also absorbs
Richard's paradox), and Zwicker's hypergame.  Burali-Forti / Girard appears
as a note: Lean's universe hierarchy exists precisely so that it cannot be
stated.  `#eval` lines run finite demonstrations at compile time.
-/

namespace Paradoxes.Diagonal

universe u

/- ====================================================================
1.  RUSSELL'S PARADOX  —  set theory (Russell, 1901)

Story.  Naive comprehension promises a set for every property; in
particular r = { x | x ∉ x }.  Is r a member of itself?  Each answer
implies its own negation.

Formalized.  For ANY type V and ANY binary relation `mem`, no element r
satisfies ∀ x, mem x r ↔ ¬ mem x x: instantiate the specification at r
itself and the biconditional refutes itself (`iff_not_self`).  Corollary:
naive comprehension entails False.  A decidable finite version checks all
16 possible "membership" relations on a two-element universe.

Teaches.  The contradiction uses no set theory at all — only
self-application.  ZF answers with restricted comprehension; type theory
answers with stratification (item 8).
==================================================================== -/

theorem russell {V : Type u} (mem : V → V → Prop) :
    ¬ ∃ r : V, ∀ x : V, mem x r ↔ ¬ mem x x :=
  fun ⟨r, hr⟩ => iff_not_self (hr r)

/-- Naive comprehension — every predicate on the universe is the extension
of some set — is flatly contradictory: feed it the Russell predicate. -/
theorem naive_comprehension_false {V : Type u} (mem : V → V → Prop)
    (comp : ∀ P : V → Prop, ∃ s : V, ∀ x : V, mem x s ↔ P x) : False :=
  russell mem (comp fun x => ¬ mem x x)

/-- All 16 possible "membership" relations on a two-element universe,
coded by the 4 bits of `code`. -/
def memOf (code : Fin 16) (x y : Fin 2) : Bool :=
  (code.val / 2 ^ (2 * x.val + y.val)) % 2 == 1

/-- Decidable finite Russell: none of the 16 relations on a 2-element
universe contains a Russell set — `decide` checks every case. -/
theorem russell_finite :
    ∀ code : Fin 16, ¬ ∃ r : Fin 2, ∀ x : Fin 2,
      memOf code x r = !(memOf code x x) := by decide

#eval s!"[Russell] no universe V with relation mem admits r such that (x ∈ r ↔ x ∉ x); decide confirmed: each of the 16 candidate relations on a 2-element universe is Russell-set-free"

/- ====================================================================
2.  THE BARBER PARADOX  —  logic folklore (Russell's popularization)

Story.  In a village, the barber shaves exactly those villagers who do
not shave themselves.  Who shaves the barber?

Formalized.  Identical skeleton to item 1 with `mem` renamed `shaves`:
no barber b satisfies ∀ p, shaves b p ↔ ¬ shaves p p.

Teaches.  This is Russell's paradox in street clothes — Russell used it
to explain the set-theoretic antinomy.  Unlike naive set theory, here
the resolution is simply that no such barber can exist: the "paradox"
is a proof of nonexistence.
==================================================================== -/

theorem barber {Person : Type u} (shaves : Person → Person → Prop) :
    ¬ ∃ b : Person, ∀ p : Person, shaves b p ↔ ¬ shaves p p :=
  fun ⟨b, hb⟩ => iff_not_self (hb b)

#eval s!"[Barber] the villager who shaves exactly the non-self-shavers cannot exist: instantiating his job description on himself yields (shaves b b ↔ ¬ shaves b b)"

/- ====================================================================
3.  CANTOR'S THEOREM  —  set theory (Cantor, 1891)

Story.  There are strictly more subsets of A than elements of A: no map
from A to its power set is onto.  The proof invented diagonalization.

Formalized.  For any f : A → (A → Prop), f is not surjective.  The
diagonal set g = { x | ¬ f x x } cannot be f a for any a: from
f a = g, `congrFun` at a gives the propositional equation
f a a = ¬ f a a, hence f a a ↔ ¬ f a a, killed by `iff_not_self`.

Teaches.  Even for infinite A there is no "list of all subsets";
cardinalities climb forever.  Every other item in this file is this
theorem wearing a costume.
==================================================================== -/

theorem cantor {A : Type u} (f : A → (A → Prop)) : ¬ Function.Surjective f := by
  intro hsurj
  obtain ⟨a, ha⟩ := hsurj (fun x : A => ¬ f x x)
  have h : f a a ↔ ¬ f a a := iff_of_eq (congrFun ha a)
  exact iff_not_self h

/-- A concrete finite instance for the demo: the "listed subsets" of a
3-element set are the three singletons (rows of the identity matrix). -/
def cantorRows : Fin 3 → Fin 3 → Bool := fun i j => decide (i = j)

#eval s!"[Cantor] listed subsets of a 3-element set (as bit rows): {List.ofFn (fun i => List.ofFn (cantorRows i))}; flipped diagonal: {List.ofFn (fun i => !(cantorRows i i))} — it differs from row i at column i, so it was never listed; no f : A → (A → Prop) is onto"

/- ====================================================================
4.  CANTOR'S PARADOX  —  the set of all sets / greatest cardinal
    (Cantor, 1899)

Story.  Let U be the set of all sets.  Its power set is a set of sets,
so P(U) ⊆ U, giving a surjection U → P(U) — but Cantor's theorem says
there is none.  So there is no set of all sets and no greatest cardinal.

Formalized (note powered by item 3, upgraded to a theorem).  Suppose a
universe U could faithfully code all of its own predicates: a coding
`code : (U → Prop) → U` split by a decoding `decode` with
decode (code P) = P.  Then decode is surjective, contradicting `cantor`.
Together with `naive_comprehension_false` (item 1) this is exactly the
set-of-all-sets contradiction.

Teaches.  "The collection of everything" cannot itself be a thing of
the same kind; ZF makes U a proper class, type theory a higher universe.
==================================================================== -/

theorem cantors_paradox {U : Type u}
    (code : (U → Prop) → U) (decode : U → (U → Prop))
    (retract : ∀ P : U → Prop, decode (code P) = P) : False :=
  cantor decode (fun P => ⟨code P, retract P⟩)

#eval s!"[Cantor's paradox] a universe U coding all of its own predicates (a 'set of all sets') is contradictory: decoding would be a surjection U → (U → Prop), which theorem cantor forbids"

/- ====================================================================
5.  BERRY'S PARADOX, finitist core  —  logic/definability
    (Berry via Russell, 1906)

Story.  "The least number not definable in under sixty letters" defines,
in under sixty letters, a number that by definition it cannot define.

Formalized.  The consistent core: there are only finitely many short
descriptions, so they cannot name every natural number.  For any
g : Fin n → Nat (description i names number g i), g is not surjective.
Witness: 1 + the maximum value named.  The helper `finMax` and the
lemma `le_finMax` (every named value is ≤ the max) are proved from
first principles by induction.

Teaches.  The paradoxical sting is the *self-referential phrase*, not
the counting fact.  Formalizing "definable" as an honest function makes
the argument a theorem; letting "definable" describe itself (as the
English phrase does) is what explodes — cf. items 6 and 9.
==================================================================== -/

/-- Maximum value of `g` over `Fin n` (0 when `n = 0`). -/
def finMax : (n : Nat) → (Fin n → Nat) → Nat
  | 0, _ => 0
  | n + 1, g => Nat.max (g ⟨0, Nat.succ_pos n⟩) (finMax n (fun j => g j.succ))

theorem finMax_succ (n : Nat) (g : Fin (n + 1) → Nat) :
    finMax (n + 1) g
      = Nat.max (g ⟨0, Nat.succ_pos n⟩) (finMax n (fun j => g j.succ)) := rfl

theorem le_finMax : ∀ (n : Nat) (g : Fin n → Nat) (i : Fin n), g i ≤ finMax n g := by
  intro n
  induction n with
  | zero => intro _ i; exact i.elim0
  | succ n ih =>
    intro g i
    cases i with
    | mk iv hlt =>
      rw [finMax_succ]
      cases iv with
      | zero => exact Nat.le_max_left _ _
      | succ k =>
        have hk : k < n := by omega
        have step : g ⟨k + 1, hlt⟩ ≤ finMax n (fun j => g j.succ) :=
          ih (fun j => g j.succ) ⟨k, hk⟩
        exact Nat.le_trans step (Nat.le_max_right _ _)

/-- Berry, finitist core: finitely many descriptions cannot name every
natural number — `1 + finMax n g` is named by none of them. -/
theorem berry (n : Nat) (g : Fin n → Nat) : ¬ Function.Surjective g := by
  intro hsurj
  obtain ⟨i, hi⟩ := hsurj (finMax n g + 1)
  have hle : g i ≤ finMax n g := le_finMax n g i
  omega

def berryDescriptions : Fin 5 → Nat := fun i => [3, 1, 4, 1, 5].getD i.val 0

#eval s!"[Berry] five 'short descriptions' name the numbers {List.ofFn berryDescriptions}; the number {finMax 5 berryDescriptions + 1} = 1 + max is provably named by none — but 'the least number these five descriptions miss' would itself be a sixth short description"

/- ====================================================================
6.  THE HALTING-STYLE DIAGONAL  —  computability (Turing, 1936)
    ... which also absorbs RICHARD'S PARADOX (item 9; Richard, 1905)

Story.  Suppose a universal decoder existed: an enumeration
decode : Nat → (Nat → Bool) hitting every total Boolean predicate.
Flip the diagonal: g n := !(decode n n).  If decode k = g then
decode k k = !(decode k k) — a Boolean equal to its own negation.

Formalized.  No decode : Nat → (Nat → Bool) is surjective.  From
decode k = g, `congrFun` at k gives decode k k = !(decode k k),
killed by cases on the Boolean.

Teaches.  The honest moral of the THEOREM is a cardinality fact: there
is no total enumeration of all of Nat → Bool — Cantor's theorem on
total functions.  "No universal halting decider" does NOT follow from
it (the external audit's correction): the computable predicates ARE
countable, so a surjection Nat → (computable predicates) exists — it is
just not computable — and this theorem quantifies over arbitrary
decode, computable or not.

Informal Turing bridge (commentary only, NOT proved here): genuine
undecidability needs a machine model in which the flipped diagonal
k ↦ !(decode k k) is itself computable whenever decode is — an
interpreter plus negation.  In such a model the diagonal argument then
shows no computable decode enumerates all total computable predicates,
which is the road to the unsolvability of halting.  None of that
machinery (machines, interpreters, a computability predicate) exists in
this file.  Richard's paradox (1905) — diagonalize the enumeration of
all French-definable reals, changing the n-th digit of the n-th real —
is the same theorem with digits for Booleans: what explodes is the
assumption that "definable" is itself a definable total enumeration.
The paradox becomes a theorem about enumerations.
==================================================================== -/

theorem halting_diagonal (decode : Nat → (Nat → Bool)) :
    ¬ Function.Surjective decode := by
  intro hsurj
  obtain ⟨k, hk⟩ := hsurj (fun n => !(decode n n))
  have h : decode k k = !(decode k k) := congrFun hk k
  cases hb : decode k k with
  | false => rw [hb] at h; exact Bool.noConfusion h
  | true  => rw [hb] at h; exact Bool.noConfusion h

/-- A concrete "enumeration" for the demo: row `e` is the bit pattern of
`5 * e + 3`. -/
def demoDecode (e : Nat) : Nat → Bool := fun n => ((5 * e + 3) / 2 ^ n) % 2 == 1

/-- The flipped diagonal of `demoDecode`. -/
def demoDiag (n : Nat) : Bool := !(demoDecode n n)

/-- Decidable check: the flipped diagonal escapes each of the first 8 rows
at that row's own index. -/
theorem demoDiag_escapes :
    ∀ e : Fin 8, demoDiag e.val ≠ demoDecode e.val e.val := by decide

#eval s!"[Turing diagonal] decode e at its own index, e = 0..7: {(List.range 8).map (fun e => demoDecode e e)}; flipped diagonal: {(List.range 8).map demoDiag} — disagrees with every row at that row's index (decide-verified): no total enumeration of all of Nat → Bool (a cardinality fact; the step to 'no halting decider' needs a machine model where the flipped diagonal is itself computable — informal commentary here, not a theorem)"

/- ====================================================================
7.  THE HYPERGAME PARADOX  —  game theory / foundations (Zwicker, 1987)

Story.  Call a game well-founded if every play ends in finitely many
moves.  Hypergame: as your first move, pick any well-founded game; play
then continues in that game.  Is hypergame well-founded?  If yes, both
players may keep choosing hypergame forever — an infinite play, so no.
If no, some infinite play exists, but its first move enters a
well-founded game, which ends — so yes.

Formalized.  Model "position g is reachable by a move from position h"
as `moves g h`, and "well-founded from g" as `Acc moves g`.  There is
no game h whose moves are EXACTLY the well-founded games:
¬ ∃ h, ∀ g, moves g h ↔ Acc moves g.  Proof: any such h would be
accessible (all its predecessors are accessible by specification), hence
h moves to itself, contradicting the lemma that accessible points admit
no self-loop (induction on `Acc`).

Teaches.  "The game of all well-founded games" diagonalizes just like
"the set of all well-founded sets" — hypergame is Russell/Mirimanoff
for games, and `Acc` makes the resolution precise: the specification is
unsatisfiable.
==================================================================== -/

theorem acc_not_self {A : Type u} {r : A → A → Prop} (x : A) (hx : Acc r x) :
    ¬ r x x := by
  induction hx with
  | intro y _hy ih => exact fun hyy => ih y hyy hyy

theorem hypergame {Game : Type u} (moves : Game → Game → Prop) :
    ¬ ∃ h : Game, ∀ g : Game, moves g h ↔ Acc moves g := by
  intro ⟨h, spec⟩
  have accH : Acc moves h := Acc.intro h (fun g hg => (spec g).mp hg)
  exact acc_not_self h accH ((spec h).mpr accH)

#eval s!"[Hypergame] 'first move: pick any well-founded game' — a game whose moves are exactly the well-founded games cannot exist: it would be well-founded, hence a legal first move of itself, an infinite self-loop (theorem hypergame, via Acc)"

/- ====================================================================
8.  BURALI-FORTI / GIRARD  —  ordinals & type universes
    (Burali-Forti 1897; Girard 1972)   [NOTE]

Story.  The collection Ω of all ordinals would be a well-ordered set,
hence itself an ordinal, hence Ω < Ω.  In type theory the same idea
resurfaces as Girard's paradox: a system with `Type : Type` proves
False by building the "ordering of all orderings".

Note, not a theorem — and that is the point.  Lean's universes are
stratified exactly to block this: `Type 0 : Type 1 : Type 2 : ...`, and
the paradoxical premise `Type : Type` is not false here but UNSTATABLE —
writing `(Type 0 : Type 0)` is a type error the file could not contain
and still compile.  The `#check` lines below display the stratification;
`cantors_paradox` (item 4) shows what would go wrong one level down if
a universe could swallow its own predicate space.
==================================================================== -/

#check (Type 0 : Type 1)        -- the type of types lives one level up
#check (Type 1 : Type 2)        -- ... and so on forever: no top, no Ω
#check (Prop : Type 0)
#check (Type u : Type (u + 1))  -- uniformly, at every level

#eval s!"[Burali-Forti/Girard] the ordinal of all ordinals needs Type : Type; Lean's hierarchy Type 0 : Type 1 : Type 2 : ... makes the paradox unstatable rather than false — stratification is the fix shipped in the kernel"

/- ====================================================================
9.  RICHARD'S PARADOX  —  definability (Richard, 1905)   [NOTE]

Folded into item 6: enumerate the reals definable by finite phrases and
change the n-th digit of the n-th real; the result is definable by that
very phrase yet differs from every definable real.  Formally this is
`halting_diagonal` with digit-flipping for Boolean negation: the honest
content is that NO total enumeration Nat → (Nat → Bool) is surjective.
The paradox lives only in the pretense that informal "definability"
enumerates itself; Berry (item 5) is its finitist shadow.
==================================================================== -/

#eval s!"[Richard] change the n-th digit of the n-th definable real: formally identical to the Turing diagonal (item 6) — 'definable' cannot totally enumerate itself"

/-- Catalog of the paradoxes formalized in this file. -/
def catalog : List (String × String) :=
  [ ("Russell's paradox",
     "THEOREM: for any mem : V → V → Prop no r has ∀ x, mem x r ↔ ¬mem x x; naive comprehension refuted; decide-checked over all 16 relations on Fin 2"),
    ("Barber paradox",
     "THEOREM: no barber shaves exactly the non-self-shavers — Russell's diagonal popularized"),
    ("Cantor's theorem",
     "THEOREM: no f : A → (A → Prop) is surjective; the diagonal set {x | ¬ f x x} is missed"),
    ("Cantor's paradox",
     "THEOREM: a universe faithfully coding all its own predicates (set of all sets / greatest cardinal) yields False, via Cantor's theorem"),
    ("Berry paradox",
     "THEOREM: no g : Fin n → Nat is surjective — finitely many short descriptions cannot name every natural; witness 1 + finMax"),
    ("Halting-style diagonal",
     "THEOREM: no decode : Nat → (Nat → Bool) is surjective — no total enumeration of all of Nat → Bool, Cantor on total functions; the Turing bridge to 'no halting decider' is informal commentary (it needs a machine model making the flipped diagonal computable; computable predicates are countable, so the cardinality fact alone does not decide halting); finite escape decide-verified and #eval-demonstrated"),
    ("Hypergame paradox",
     "THEOREM: no game h with ∀ g, moves g h ↔ Acc moves g — accessible points admit no self-loop"),
    ("Burali-Forti / Girard",
     "NOTE: ordinal-of-all-ordinals becomes Girard's paradox under Type:Type; Lean's stratified universes (#check Type 0 : Type 1) make it unstatable"),
    ("Richard's paradox",
     "NOTE: diagonal over an enumeration of definable reals — formally the halting-style diagonal of item 6") ]

end Paradoxes.Diagonal
