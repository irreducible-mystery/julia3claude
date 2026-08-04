/-!
# The limits of the sayable — the Lean half of the conversation

Answers, as runnable machine-checked exhibits, the six questions posed by the
Julia side of this repo in `paradoxes/EXPRESSIBILITY.md` §IV.  The essay's
conjecture: *Julia contains paradox by refusing to assert; Lean contains it by
refusing to diverge; English contains nothing, which is its job.*

The exhibits below test that conjecture at the boundary.  Two kinds of artifact
appear, and both are checked by the compiler:

* **Theorems** — positive exhibits, checked as always.
* **Rejections** — negative exhibits, captured with core's `#guard_msgs`:
  the file *compiles cleanly* while containing declarations Lean refuses,
  because each refusal is pinned to its exact error message.  A rejection
  becomes a checked artifact: if a future Lean stopped rejecting the liar,
  this file would stop compiling.  (Julia's essay could only *describe* what
  Julia cannot say; Lean can *exhibit* what Lean cannot say, and check the
  exhibit.  That asymmetry is already half the answer.)

Everything is core Lean 4 — no imports, no `sorry`, no axiom declarations.
`partial` and `noncomputable` appear because they are the subject matter.

Exhibit map: E1↦Q1 (the liar's four doors), E2↦Q2 (Curry's price),
E3↦Q2 (the universe wall / Girard), E4↦Q3 (statable but open),
E5↦Q4+Q5 (`noncomputable` = the run/say boundary), E6↦Q5 (funext vs Rice),
E7↦Q6 (the space of formalizations as an object), E8 (assertion force).
-/

namespace Paradoxes.Expressibility

/- ======================================================================
   E1 (Q1): THE LIAR'S FATE IN LEAN — four doors, all shown

   Julia's liar (`liar() = !liar()`, file 01) compiles and diverges: the
   paradox is *contained by the runtime*.  Question 1 asks where exactly Lean
   stops it — positivity, universe levels, or termination?  Answer: it
   depends on which door the liar knocks at, and each door has a different
   guard.  None of them is the universe checker: the liar, unlike Girard
   (E3), is not a size problem.

   Door (a) — the PROPOSITIONAL liar: a proposition equivalent to its own
   negation, built as an inductive fixed point.  This is where the real liar
   dies, and the guard is the STRICT POSITIVITY checker: `Liar` may not occur
   to the left of an arrow in its own constructor.  Note the error prefix
   `(kernel)`: positivity is not an elaboration nicety, it is enforced by the
   trusted kernel itself.  If this inductive were admitted, `theorem liar` in
   SelfReference.lean (no P with P ↔ ¬P) would give False outright.
   ====================================================================== -/

/--
error: (kernel) arg #1 of 'Paradoxes.Expressibility.Liar.mk' has a non positive occurrence of the datatypes being declared
-/
#guard_msgs in
inductive Liar : Prop where
  | mk : ¬Liar → Liar

/- ----------------------------------------------------------------------
   Door (b) — the DEFINITIONAL liar: `def liar : Prop := ¬liar`.  A finding
   that refines the folklore: in Lean 4 this is NOT an unknown-identifier
   error.  `def` bodies DO see the name being defined (every `def` is
   potentially recursive; the equation compiler decides), so the syntactic
   door is open — and the liar walks straight into the TERMINATION checker.
   Structural recursion needs a shrinking argument; well-founded recursion
   needs an argument at all; a 0-ary self-reference has neither.  Julia
   answers the same knock by compiling the recursion and letting it diverge;
   Lean refuses at the door because a `Prop`-valued definition, once
   admitted, would be a *value*, and values here are total.
   ---------------------------------------------------------------------- -/

/--
error: fail to show termination for
  Paradoxes.Expressibility.liar
with errors
failed to infer structural recursion:
no parameters suitable for structural recursion

well-founded recursion cannot be used, `Paradoxes.Expressibility.liar` does not take any (non-fixed) arguments
-/
#guard_msgs in
def liar : Prop := ¬liar

/- ----------------------------------------------------------------------
   Door (c) — the ESCAPE HATCH, `partial`.  Q1 asks what
   `partial def liar : Bool := !liar` "actually gives you".  First surprise:
   for a bare VALUE, nothing — Lean rejects it.  `partial` applies only to
   function types: a closed term of type `Bool` must BE one of the two bits;
   only a *computation* is allowed to diverge.  (Julia's 0-ary `liar()` is
   still a function you call — so the honest mirror is `Unit → Bool`.)
   ---------------------------------------------------------------------- -/

/--
error: invalid use of `partial`, `Paradoxes.Expressibility.liarBool` is not a function
  Bool
-/
#guard_msgs in
partial def liarBool : Bool := !liarBool

/-- The liar Lean DOES accept — Julia's liar, verbatim: a diverging
computation.  This compiles.  Do NOT `#eval liarRun ()`: it loops forever,
exactly like file 01's `liar()`.  What `partial` actually buys is this:
the definition is compiled for the runtime but made OPAQUE to the kernel —
elaborated via an `unsafe` recursive twin and then sealed behind an opaque
constant, so its defining equation `liarRun () = !liarRun ()` is *not*
available to the logic.  The kernel never unfolds `liarRun`; it knows only
that some inhabitant of `Unit → Bool` exists (which is why `partial`
requires the return type to be `Inhabited` — soundness needs the sealed
constant to denote *something*).  Consequence, demonstrated below: the
liar's fixed-point equation is UNPROVABLE.  Lean quarantines divergence
from `Prop`; the diverging liar exists but carries zero assertoric
content.  Julia's containment (run it and hang) and Lean's containment
(admit it and strip its meaning) are the same wall, seen from the two
sides: Julia keeps the running and loses nothing else because it never had
assertion; Lean keeps assertion and therefore must confiscate the run. -/
partial def liarRun (_ : Unit) : Bool := !liarRun ()

/- The confiscation, exhibited twice.  `rfl` fails: there is no definitional
   unfolding of `liarRun` for the kernel to compute with.  -/

/--
error: Type mismatch
  rfl
has type
  ?m.3 = ?m.3
but is expected to have type
  liarRun () = !liarRun ()
-/
#guard_msgs in
example : liarRun () = !liarRun () := rfl

/- And `decide` gets STUCK — the decision procedure needs to evaluate
   `liarRun ()` to a literal `true` or `false`, and the opaque constant
   refuses to reduce.  The error message is a photograph of the quarantine:
   reduction halts at the very `match` on the liar's value.  (This is the
   precise cash value of "opaque": not forbidden, not false — *stuck*.)  -/

/--
error: Tactic `decide` failed for proposition
  liarRun () = !liarRun ()
because its `Decidable` instance
  instDecidableEqBool (liarRun ()) !liarRun ()
did not reduce to `isTrue` or `isFalse`.

After unfolding the instances `instDecidableEqBool` and `Bool.decEq`, reduction got stuck at the `Decidable` instance
  match liarRun (), !liarRun () with
  | false, false => isTrue ⋯
  | false, true => isFalse ⋯
  | true, false => isFalse ⋯
  | true, true => isTrue ⋯
-/
#guard_msgs in
example : liarRun () = !liarRun () := by decide

/- ----------------------------------------------------------------------
   Door (d) — the TOTAL liar: make the divergence itself an inspectable
   object by paying for it in fuel.  `liarFuel n` runs the liar's negation
   loop for n steps and answers `none` if the fuel runs out — and every
   finite approximation returns `none`.  This is Julia's infinite regress
   made total: not only can each stage be run (#eval below), the whole
   pattern of divergence becomes a THEOREM, proved by induction.  The liar,
   forced through the totality door, is the everywhere-undefined value —
   which is precisely its classical diagnosis (Kripke: the liar is
   ungrounded; the fixed point of x ↦ !x on Option Bool ⊥-approximants is ⊥
   at every stage).
   ---------------------------------------------------------------------- -/

/-- Fuel-bounded liar: `none` at fuel 0, negate at each step. -/
def liarFuel : Nat → Option Bool
  | 0 => none
  | n + 1 => (liarFuel n).map (!·)

/-- info: [none, none, none, none, none, none] -/
#guard_msgs in
#eval (List.range 6).map liarFuel

/-- Divergence made total and provable: the liar denotes at NO fuel level. -/
theorem liarFuel_none : ∀ n, liarFuel n = none
  | 0 => rfl
  | n + 1 => by rw [liarFuel, liarFuel_none n]; rfl

#eval s!"E1 liar: door (a) positivity-rejected, door (b) termination-rejected, \
door (c) partial compiles but is opaque (equation unprovable, decide stuck), \
door (d) fuel: liarFuel n = none for ALL n (theorem liarFuel_none)"

/- ======================================================================
   E2 (Q2): CURRY'S PRICE — what avoiding triviality cost `Prop`

   Curry's paradox needs only the fixed point P ↔ (P → Q) to prove any Q
   (theorem `curry` in SelfReference.lean, in minimal logic — no negation).
   So the entire safety question is: can the fixed point be FORMED?  Below:
   no — and note it dies at the SAME door as the liar, with the same kernel
   positivity error, because Curry IS the liar with a payload (take
   Q := False and `(C → False) → C` is literally `¬C → C`, half the liar;
   the paradox machinery only ever needed the C → ... occurrence).

   What did this cost Lean's `Prop`?  The essay guesses "impredicativity is
   the scar" — close, but the ledger is more precise.  Prop KEEPS
   impredicativity (∀ p : Prop, ... : Prop quantifies over the very
   collection it lands in — that is Julia-inexpressible and even
   Type-inexpressible, see E3).  Impredicativity + unrestricted fixed
   points would be Curry, i.e. triviality.  Lean pays with three fences:
   (1) STRICT POSITIVITY — the rejection below; no self-application, no
       `{x | x ∈ x → Q}`;
   (2) PROOF IRRELEVANCE — any two proofs of a Prop are equal, so a proof
       cannot smuggle data that diagonalization could act on;
   (3) RESTRICTED LARGE ELIMINATION — you cannot in general case-analyze a
       Prop to produce data in Type; a mere existence proof does not yield
       a witness-extracting program.
   Fence (3) is the visible scar, and it is load-bearing for the whole
   file: it is exactly why `noncomputable` must exist (E5) — classical
   proofs live in Prop, and Prop's exit door to computation is barred.
   ====================================================================== -/

/--
error: (kernel) arg #1 of 'Paradoxes.Expressibility.C.mk' has a non positive occurrence of the datatypes being declared
-/
#guard_msgs in
inductive C : Prop where
  | mk : (C → False) → C

#eval s!"E2 Curry: the fixed point P ↔ (P → Q) cannot be FORMED — positivity again \
(Curry is the liar with a payload); Prop keeps impredicativity and pays with \
positivity + proof irrelevance + restricted large elimination"

/- ======================================================================
   E3 (Q2, the universe wall): GIRARD RENDERED UNSTATABLE

   The other classical engine of triviality is Girard's paradox —
   Burali-Forti run inside type theory, derivable whenever `Type : Type`.
   Lean's answer is not a clever proof that Girard's argument fails; it is
   a TYPE ERROR.  `Type 0` lives in `Type 1`, never in itself; the
   stratification Type 0 : Type 1 : Type 2 : ... makes the paradox's first
   premise ill-typed.  The paradox is not refuted but rendered unstatable —
   Lean does to Girard precisely what Julia does to the universal
   quantifier: pushes it outside the language.  (Meanwhile `Prop : Type`,
   yet `∀ p : Prop, p → p : Prop` — Prop is the ONE impredicative floor,
   safe only because of E2's fences.  One impredicative universe is
   consistent; two stacked ones would not be.)
   ====================================================================== -/

/--
error: Type mismatch
  Type
has type
  Type 1
of sort `Type 2` but is expected to have type
  Type
of sort `Type 1`
-/
#guard_msgs in
def U : Type := Type

#eval s!"E3 Girard: 'Type : Type' is a type error — Type 0 : Type 1 : Type 2 : ...; \
the paradox is not refuted but unstatable (the universe wall; the liar never needed it)"

/- ======================================================================
   E4 (Q3): STATABLE BUT OPEN — the sentence Julia cannot say, plus the
   search Julia can run, in ONE language

   The essay: "Every even number ≥ 4 is a sum of two primes" is not statable
   in Julia — only a search that halts on a counterexample or runs forever.
   Here is the sentence, as a first-class object of type Prop, built from a
   from-scratch decidable primality test (trial division — every bound in
   sight is finite, so the pieces are Julia-runnable; only the ∀ is new).
   ====================================================================== -/

/-- Trial-division primality, from scratch: p ≥ 2 and no d with 2 ≤ d < p
divides it.  A checking procedure — this much Julia says natively. -/
def primeBool (p : Nat) : Bool :=
  decide (2 ≤ p) && (List.range p).all fun d => decide (d < 2) || p % d != 0

/-- Primality as a PROPOSITION, with its decision procedure attached. -/
def IsPrime (p : Nat) : Prop := primeBool p = true

instance (p : Nat) : Decidable (IsPrime p) :=
  inferInstanceAs (Decidable (primeBool p = true))

example : IsPrime 101 := by decide
example : ¬IsPrime 91 := by decide  -- 7 × 13

/-- Goldbach's conjecture — a COMPLETED universally quantified sentence over
all of Nat.  This definition is the exact thing the essay says Julia cannot
express.  It typechecks; it is a value; E7 will even put such sentences
inside data structures. -/
def GoldbachSays : Prop :=
  ∀ n : Nat, 4 ≤ n → n % 2 = 0 → ∃ p q, IsPrime p ∧ IsPrime q ∧ p + q = n

/-- info: Paradoxes.Expressibility.GoldbachSays : Prop -/
#guard_msgs in
#check GoldbachSays

/-- The Julia mode, in the same language: a bounded search for witnesses. -/
def goldbachWitness (n : Nat) : Option (Nat × Nat) :=
  (List.range (n + 1)).findSome? fun p =>
    if primeBool p && primeBool (n - p) then some (p, n - p) else none

def goldbachCheckedUpTo (limit : Nat) : Bool :=
  (List.range (limit + 1)).all fun n =>
    !(decide (4 ≤ n) && decide (n % 2 = 0)) || (goldbachWitness n).isSome

/-- info: true -/
#guard_msgs in
#eval goldbachCheckedUpTo 300

/-- info: some (7, 293) -/
#guard_msgs in
#eval goldbachWitness 300

/- ----------------------------------------------------------------------
   One language, both modes: the SENTENCE (GoldbachSays : Prop) and the
   SEARCH (#eval ... = true up to 300).  What separates them is exactly one
   unproved implication — a proof of GoldbachSays would subsume every run
   of the search; no number of runs adds up to the sentence.

   Q3's inventory: essentially ALL of the repo's ~40 paradoxes are
   STATABLE here — SelfReference.lean states ten of them as theorems whose
   hypotheses are the paradox and whose conclusion is False.  The
   interesting class is statable-but-open / statable-but-undecidable:
   - GoldbachSays (above): statable, decidable at every instance, open as
     a whole.  Lean does not know whether it is provable.
   - Con(Lean): EXPRESSIBLE — not in this core-only file, but in principle
     and in practice: the lean4lean project formalizes Lean's kernel in
     Lean, so "no proof of False checks" is a Lean sentence about Lean.
     Gödel II then applies: if Lean's foundation is consistent, that
     sentence is unprovable in Lean.  Gödel's sentence for Lean-about-Lean
     exists, and Lean can even prove the meta-theorem THAT it exists.
   - CH: statable (Mathlib states it) and provably independent.
   So where Julia's boundary is "unverifiable = unsayable", Lean's sayable
   strictly contains its provable, and Lean can PROVE that the containment
   is strict for named sentences.  Tarski still holds one floor up: Lean
   cannot define TRUTH for Lean, only provability-in-Lean (theorem `tarski`
   next door applies to Lean itself).
   ---------------------------------------------------------------------- -/

#eval s!"E4 Goldbach: sentence GoldbachSays : Prop typechecks (unsayable in Julia); \
search verified up to 300: {goldbachCheckedUpTo 300} (this part IS Julia); \
witness for 300: {goldbachWitness 300}"

/- ======================================================================
   E5 (Q4 + Q5): `noncomputable` — THE RUN/SAY BOUNDARY, NAMED

   Q4 asks for Lean's inventory of antinomy-shapes, matching Julia's
   {empty model, divergence, `missing`, world-age error}.  Assembled from
   this file: (i) POSITIVITY rejection (E1a, E2 — the kernel's own no),
   (ii) TERMINATION rejection (E1b), (iii) UNIVERSE error (E3),
   (iv) `partial` — divergence admitted but sealed away from Prop (E1c),
   (v) `noncomputable` — this exhibit: definition admitted but sealed away
   from execution, (vi) `sorry` — assertion without warrant, tracked and
   shamed by the compiler (absent from this file by design), and
   (vii) #guard_msgs — the reflective move: a REJECTION turned into a
   checked artifact, which is how this file exists at all.

   Below: Classical.choice conjures a Bool out of a mere existence proof.
   The definition typechecks — the object is fully SAYABLE — but Lean
   demands the marker `noncomputable`: no code is generated, and #eval is
   refused (captured).  Yet we can still PROVE things about the ghost:
   `chosenBool = true ∨ chosenBool = false` is a theorem — it IS a Bool,
   we just cannot find out which one by running it.
   ====================================================================== -/

/-- A Bool chosen by the axiom of choice from the bare fact that Bools
exist.  Sayable, provable-about, unrunnable. -/
noncomputable def chosenBool : Bool := Classical.choice ⟨true⟩

/--
error: failed to compile definition, consider marking it as 'noncomputable' because it depends on 'chosenBool', which is 'noncomputable'
-/
#guard_msgs in
#eval chosenBool

/-- The ghost is still a Bool, and logic reaches it even though execution
cannot: excluded middle by case analysis on a value no program can produce. -/
theorem chosenBool_dichotomy : chosenBool = true ∨ chosenBool = false := by
  cases h : chosenBool
  · exact Or.inr rfl
  · exact Or.inl rfl

/- ----------------------------------------------------------------------
   Is `noncomputable` Lean's name for Julia's "inexpressible"?  Almost —
   and the ALMOST is the answer to Q5's symmetry question.  This is where
   Banach–Tarski's pieces live for Lean: definable (Mathlib literally
   defines the equidecomposition), provable-about (the theorem is proved),
   unrunnable (every construction is noncomputable — Classical.choice
   produces terms with no code, exactly the essay's 'exists in your
   language and produces nothing we could run').  But the asymmetry with
   Julia is real: Julia cannot even SAY these objects — there is no
   expression denoting a Vitali set, and the silence is total.  Lean says
   them, quantifies over them, proves dichotomies about them, and forfeits
   ONLY their execution.  The trade is not symmetric: Julia's boundary
   deletes the object; Lean's boundary deletes one verb.  (The same
   one-verb forfeit prices Lean's Real: a quotient over classical Cauchy
   sequences that cannot compute its own digits — full sentences about ℝ,
   no printout of √2.  Julia's Float64 is the mirror cell: all printout,
   no sentences.)
   ---------------------------------------------------------------------- -/

#eval s!"E5 noncomputable: chosenBool is sayable and provable-about \
(dichotomy is a theorem) but #eval is refused — Banach–Tarski's Lean address; \
Julia deletes the object, Lean deletes only the verb 'run'"

/- ======================================================================
   E6 (Q5): FUNEXT vs RICE — "same function" as a sentence, with the
   essay's Int16 episode repaired

   Rice's theorem makes "f and g compute the same function" undecidable, so
   Julia's `==` on functions is code identity and the claim is unstatable.
   In Lean, function extensionality makes it a THEOREM.  Here is the
   essay's own example, over Nat — the sentence Julia cannot state:
   ====================================================================== -/

/-- Two different PROGRAMS (an addition and a multiplication), one equal
FUNCTION — an identity of infinitely many cases, closed by two tactics. -/
theorem double_eq_twice : (fun x : Nat => x + x) = (fun x : Nat => 2 * x) := by
  funext x
  omega

/- ----------------------------------------------------------------------
   The essay confesses that its first draft called `x -> x + x` and
   `x -> 2x` "the same function" and was refuted over Int16: in Julia,
   `x + x` stays Int16 and WRAPS, while `2x` PROMOTES to Int64 and doesn't.
   The refutation came from PROMOTION — i.e. from the domain being ambient,
   negotiated by the compiler mid-expression, rather than stated.  In Lean
   the domain is part of the claim, so the same sentence over the wrapping
   type is simply TRUE — `(2 : UInt16) * x` cannot promote; both sides wrap
   identically, and the identity holds in all 65536 cases.

   Core Lean has no `Decidable (∀ x : UInt16, _)` instance, so we build the
   bridge ourselves — UInt16 is in bijection with Nat below 2^16, and
   bounded ∀ over Nat is decidable (this instance is itself a small answer
   to Q6: the finiteness of the domain becomes a typeclass FACT).  The
   kernel could in principle check all 2^16 cases by reduction, but times
   out at the default heartbeat budget; `native_decide` runs the very same
   decision procedure through the compiler instead — trading kernel-only
   trust for the compiler's word, one more run/say boundary made visible.
   ---------------------------------------------------------------------- -/

instance decForallUInt16 (p : UInt16 → Prop) [DecidablePred p] :
    Decidable (∀ x : UInt16, p x) :=
  match Nat.decidableBallLT (2 ^ 16) (fun n _ => p (UInt16.ofNat n)) with
  | .isTrue h => .isTrue fun x => by
      have hx := h x.toNat x.toNat_lt
      rwa [UInt16.ofNat_toNat] at hx
  | .isFalse h => .isFalse fun hall => h fun n _ => hall (UInt16.ofNat n)

/-- The Int16 episode, repaired: with the domain IN the sentence, doubling
is exactly twice — both sides wrap the same way, all 65536 cases checked. -/
theorem uint16_double : ∀ x : UInt16, x + x = 2 * x := by native_decide

-- And the Julia mode of the same fact, as a plain run (checked at compile time).
#guard (List.range 65536).all fun n =>
  UInt16.ofNat n + UInt16.ofNat n == 2 * UInt16.ofNat n

#eval s!"E6 funext vs Rice: (fun x => x + x) = (fun x => 2 * x) over Nat is a THEOREM \
(unstatable in Julia); over UInt16 it is TRUE (65536 cases) — Julia's Int16 \
counterexample was the ambient domain shifting, not the functions differing"

/- ======================================================================
   E7 (Q6): THE SPACE OF FORMALIZATIONS AS AN OBJECT

   Sleeping Beauty (file 05) dissolved in Julia into two samplers that
   yield 1/2 and 1/3 — but Julia could only ENUMERATE the samplers; the
   claim "the question underdetermines the formalization" stayed in the
   comments.  Dependent typing promotes that claim into the language:
   `CredenceQuestion` is the TYPE OF READINGS of "what is your credence
   that the coin landed heads?", indexed by the number N of coin-flip runs.
   Each disambiguation is an inhabitant; what each reading answers is a
   THEOREM about that inhabitant; and their disagreement is a theorem too.
   ====================================================================== -/

/-- A reading of Sleeping Beauty's question: given N runs of the experiment,
what population is being sampled, and which members count as favorable? -/
structure CredenceQuestion where
  population : Nat → Nat
  favorable : Nat → Nat

/-- The HALFER reading: sample the RUNS.  In 2N fair runs there are 2N runs,
N of them heads-runs. -/
def perRun : CredenceQuestion :=
  { population := fun n => 2 * n, favorable := fun n => n }

/-- The THIRDER reading: sample the AWAKENINGS.  In 2N fair runs there are
N·1 + N·2 = 3N awakenings, N of them heads-awakenings. -/
def perAwakening : CredenceQuestion :=
  { population := fun n => 3 * n, favorable := fun n => n }

/-- Under the per-run reading the credence is exactly 1/2 — for EVERY N,
not merely in a sample: favorable is half the population, definitionally. -/
theorem perRun_half : ∀ n, 2 * perRun.favorable n = perRun.population n :=
  fun _ => rfl

/-- Under the per-awakening reading the credence is exactly 1/3. -/
theorem perAwakening_third :
    ∀ n, 3 * perAwakening.favorable n = perAwakening.population n :=
  fun _ => rfl

/-- The two readings genuinely differ — they already disagree about what is
being counted, before any probability is computed. -/
theorem readings_disagree : perRun.population 1 ≠ perAwakening.population 1 := by
  decide

/- ----------------------------------------------------------------------
   The paradox's "answer" is a FUNCTION of which CredenceQuestion you mean;
   the dispute between halfers and thirders is a dispute about which
   inhabitant of this type the English question denotes — and THAT TYPE is
   the object Julia could only sample from.  Both theorems hold with ∀ N
   and rfl: the disagreement is not statistical, it is definitional.

   The same shape covers the rest of the repo's ambiguity family:
   Bertrand's "random chord" is a type of chord-measures with (at least)
   three inhabitants yielding 1/2, 1/3, 1/4; Theseus's ship is a type of
   identity-relations (continuity-of-parts vs continuity-of-form) whose
   inhabitants disagree on which successor is "the" ship.  English is
   ambiguous, Julia enumerates disambiguations, Lean TYPES them — the
   ambiguity itself, not just its resolutions, becomes a term you can
   quantify over: e.g. `∀ q : CredenceQuestion, ...` is a sentence ABOUT
   the ambiguity.
   ---------------------------------------------------------------------- -/

#eval s!"E7 Sleeping Beauty: perRun answers 1/2 (2·fav = pop, ∀N by rfl), \
perAwakening answers 1/3 (3·fav = pop, ∀N by rfl) — the 'paradox' is the choice \
of inhabitant of CredenceQuestion, and that type is itself a Lean object"

/- ======================================================================
   E8: ASSERTION FORCE — what happens to a falsehood

   The essay: in Julia, `2 + 2 == 5` evaluates to `false` and NOTHING
   HAPPENS — no assertion force, hence no lying.  In Lean, `2 + 2 = 5` is
   not an event that quietly returns false; it is a first-class Prop: you
   can STATE it (it typechecks below), you can REFUTE it (a theorem), and
   you cannot ASSERT it (asserting means exhibiting a proof term, and the
   refutation says no such term exists).  Three languages, three fates for
   a falsehood: English can lie, Julia cannot assert, Lean asserts only
   with warrant.
   ====================================================================== -/

/-- The falsehood as a citizen: stating it is legal and commits you to nothing. -/
def TwoPlusTwoIsFive : Prop := 2 + 2 = 5

/-- The refutation: Lean's response to a falsehood is not `false` (a value)
but `¬` (a sentence), itself asserted with warrant. -/
theorem two_plus_two_ne_five : ¬(2 + 2 = 5) := by decide

/-- Same claim through the named Prop — the def above and the refutation are
definitionally the one sentence. -/
example : ¬TwoPlusTwoIsFive := two_plus_two_ne_five

#eval s!"E8 assertion force: '2 + 2 = 5' is statable (a Prop), refutable (a theorem), \
unassertable (no proof exists) — English can lie, Julia cannot assert, \
Lean asserts only with warrant"

/- ====================================================================== -/

def catalog : List (String × String) := [
  ("E1 The liar's fate (Q1)",
   "GUARDED: propositional liar dies at kernel POSITIVITY, definitional liar at TERMINATION, partial VALUE rejected; partial liarRun compiles but is opaque — its equation unprovable (rfl and decide both guarded); THEOREM: liarFuel n = none at every fuel"),
  ("E2 Curry's price (Q2)",
   "GUARDED: the Curry fixed point (C → False) → C dies at the same positivity wall — Curry is the liar with a payload; Prop keeps impredicativity, pays with positivity + proof irrelevance + restricted large elimination"),
  ("E3 Girard / universe wall (Q2)",
   "GUARDED: 'Type : Type' is a type error (Type : Type 1) — Girard's paradox not refuted but rendered unstatable"),
  ("E4 Statable but open (Q3)",
   "VERIFIED: GoldbachSays : Prop typechecks (the sentence Julia cannot say) and its bounded search passes to 300 (the search Julia can run) — one language, both modes; Con(Lean) expressible via lean4lean, unprovable by Gödel II"),
  ("E5 noncomputable (Q4+Q5)",
   "THEOREM: chosenBool = true ∨ chosenBool = false, about a choice-conjured Bool; GUARDED: #eval chosenBool refused — Banach–Tarski's address: Julia deletes the object, Lean deletes only the verb 'run'"),
  ("E6 funext vs Rice (Q5)",
   "THEOREM: (fun x => x + x) = (fun x => 2 * x) over Nat by funext+omega, and ∀ x : UInt16, x + x = 2 * x by native_decide over all 65536 cases — Julia's Int16 counterexample was ambient promotion; domains belong in sentences"),
  ("E7 Space of formalizations (Q6)",
   "THEOREM: perRun answers 1/2 and perAwakening answers 1/3, each ∀N by rfl, and they provably differ — Sleeping Beauty dissolves into the inhabited type CredenceQuestion, which is itself a Lean object"),
  ("E8 Assertion force",
   "THEOREM: ¬(2 + 2 = 5) — the falsehood is statable, refutable, unassertable; English can lie, Julia cannot assert, Lean asserts only with warrant")
]

/- The verdict on the essay's closing conjecture, as one sentence. -/
#eval s!"Chiasmus verdict: confirmed, with one refinement — Julia contains paradox by \
refusing to ASSERT (meaning = execution, so the liar merely runs forever), and Lean \
contains it not by refusing divergence outright but by QUARANTINING it from Prop \
(partial divergence may exist but carries no assertoric content, choice may be \
spoken but never run) — and the trade is asymmetric: Julia loses the objects, \
Lean only loses one verb."

end Paradoxes.Expressibility
