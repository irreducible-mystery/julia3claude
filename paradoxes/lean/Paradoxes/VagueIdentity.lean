/-!
# Vagueness, Identity, and Classical Philosophical Chestnuts

Eleven classical philosophical paradoxes formalized as machine-checked
theorems in core Lean 4 (no Mathlib).  Each paradox states its folk
assumptions as explicit hypotheses; the theorem then shows either that the
assumptions are jointly contradictory or that they entail the surprising
conclusion.  The `#eval` lines are small executable demonstrations that run
at compile time.

Covered: vagueness (Sorites), identity over time (Ship of Theseus),
well-ordering as humor (interesting numbers), flawed induction (Polya's
horses), rational choice (Buridan's ass), self-reference about ability
(omnipotence), self-undermining contracts (Protagoras v. Euathlus), the
status of inference rules (Carroll's tortoise), and the quirks of classical
material implication (drinker paradox, implication oddities, Hempel's
ravens).
-/

namespace Paradoxes.VagueIdentity

/- ---------------------------------------------------------------------
1. THE SORITES (HEAP) PARADOX — philosophy of language / vagueness.

Story: a million grains of sand make a heap.  Removing a single grain from
a heap surely still leaves a heap — that is the "tolerance" intuition that
makes `heap` a vague predicate.  But iterate the tolerance step a million
times and zero grains is a heap.

Formalized: `Heap 1000000` together with the tolerance principle
`∀ n, Heap (n+1) → Heap n` entails `Heap 0`.  The helper `heap_descend`
does induction on the number of grains removed.  `sorites_contradiction`
adds the obvious `¬ Heap 0` and derives `False`.

Resolution / lesson: tolerance + classical logic + a sharp bivalent
predicate cannot coexist; one must go.  Epistemicists keep classical logic
and accept a sharp (but unknowable) cutoff; supervaluationists and fuzzy
logicians weaken the logic; contextualists deny that `Heap` picks out one
fixed predicate.  The #eval shows the epistemicist's cost concretely: any
sharp Boolean cutoff violates tolerance at exactly one point.
--------------------------------------------------------------------- -/

theorem heap_descend (Heap : Nat → Prop) (step : ∀ n, Heap (n + 1) → Heap n) :
    ∀ d j, Heap (j + d) → Heap j := by
  intro d
  induction d with
  | zero => exact fun _ h => h
  | succ d ih => exact fun j h => ih j (step (j + d) h)

theorem sorites (Heap : Nat → Prop) (h : Heap 1000000)
    (step : ∀ n, Heap (n + 1) → Heap n) : Heap 0 :=
  heap_descend Heap step 1000000 0 (by rw [Nat.zero_add]; exact h)

theorem sorites_contradiction (Heap : Nat → Prop) (h : Heap 1000000)
    (step : ∀ n, Heap (n + 1) → Heap n) (h0 : ¬ Heap 0) : False :=
  h0 (sorites Heap h step)

/-- A sharp (epistemicist) heap predicate: heap iff at least `threshold` grains. -/
def sharpHeap (threshold n : Nat) : Bool := decide (threshold ≤ n)

#eval s!"Sorites: a sharp cutoff (heap iff at least 10 grains) violates tolerance at exactly one point, n = {(List.range 100).filter (fun n => sharpHeap 10 (n + 1) && !(sharpHeap 10 n))}: removing one grain from 10 'destroys' the heap."

/- ---------------------------------------------------------------------
2. THE SHIP OF THESEUS — metaphysics / identity over time.

Story: Theseus' ship has its planks replaced one at a time; after 1000
replacements no original plank remains, yet at every single step it was
"the same ship".  Meanwhile a scavenger reassembles the discarded original
planks into a second ship — surely THAT is the same ship as the original.

Formalized: `Same` is assumed reflexive, symmetric, and transitive (as
identity should be); `ships : Nat → Ship` with `Same (ships k) (ships
(k+1))` (one plank changes nothing); and `Same (ships 0) rebuilt` (the
reassembled original planks ARE the original ship).  A chain lemma by
induction gives `Same (ships 0) (ships n)` for every `n`, hence
`Same (ships 1000) rebuilt`: the plank-swapped ship and the scavenger's
ship are THE SAME SHIP.  Anyone who also holds `¬ Same (ships 1000)
rebuilt` — as common sense insists, since they are two distinct hulls
floating side by side — holds a contradiction.

Resolution / lesson: the folk intuitions about artifact identity are
jointly inconsistent; you must pick your poison — deny the step tolerance
(mereological essentialism: any plank change ends identity), deny that the
reassembled ship is the original, deny transitivity (but then `Same` is
not identity), or relativize identity to a sortal / accept four-dimensional
"worm" theory where both are stages of overlapping objects.
--------------------------------------------------------------------- -/

theorem theseus_chain {Ship : Type} (Same : Ship → Ship → Prop)
    (hrefl : ∀ a, Same a a)
    (htrans : ∀ a b c, Same a b → Same b c → Same a c)
    (ships : Nat → Ship)
    (hstep : ∀ k, Same (ships k) (ships (k + 1))) :
    ∀ n, Same (ships 0) (ships n) := by
  intro n
  induction n with
  | zero => exact hrefl (ships 0)
  | succ n ih => exact htrans _ _ _ ih (hstep n)

theorem theseus_identity {Ship : Type} (Same : Ship → Ship → Prop)
    (hrefl : ∀ a, Same a a)
    (hsymm : ∀ a b, Same a b → Same b a)
    (htrans : ∀ a b c, Same a b → Same b c → Same a c)
    (ships : Nat → Ship) (rebuilt : Ship)
    (hstep : ∀ k, Same (ships k) (ships (k + 1)))
    (hrebuilt : Same (ships 0) rebuilt) :
    Same (ships 1000) rebuilt :=
  htrans _ _ _
    (hsymm _ _ (theseus_chain Same hrefl htrans ships hstep 1000))
    hrebuilt

theorem theseus_paradox {Ship : Type} (Same : Ship → Ship → Prop)
    (hrefl : ∀ a, Same a a)
    (hsymm : ∀ a b, Same a b → Same b a)
    (htrans : ∀ a b c, Same a b → Same b c → Same a c)
    (ships : Nat → Ship) (rebuilt : Ship)
    (hstep : ∀ k, Same (ships k) (ships (k + 1)))
    (hrebuilt : Same (ships 0) rebuilt)
    (hdiff : ¬ Same (ships 1000) rebuilt) : False :=
  hdiff (theseus_identity Same hrefl hsymm htrans ships rebuilt hstep hrebuilt)

/-- After `k` one-plank swaps on a `total`-plank ship, this many originals remain. -/
def originalPlanks (total k : Nat) : Nat := total - k

#eval s!"Theseus: original planks remaining after k swaps (of 1000): k=0 -> {originalPlanks 1000 0}, k=500 -> {originalPlanks 1000 500}, k=1000 -> {originalPlanks 1000 1000}; the rebuilt ship has all 1000 originals, yet step-tolerance + equivalence force Same(ships 1000, rebuilt)."

/- ---------------------------------------------------------------------
3. THE INTERESTING NUMBER PARADOX — mathematics folklore / well-ordering.

Story: claim — every natural number is interesting.  For suppose some were
uninteresting; then there would be a LEAST uninteresting number, and being
the least uninteresting number is a decidedly interesting property.
Contradiction.

Formalized: the hypothesis says exactly "being the least uninteresting
number is absurd": if `n` is uninteresting and everything below `n` is
interesting, we get `False`.  Strong induction (`Nat.strongRecOn`) then
proves that no number is uninteresting at all.

Resolution / lesson: well-ordering weaponized as humor.  The formal core
is airtight; what is soft is the premise, which trades on 'interesting'
shifting its meaning to swallow the metalevel property 'least member of
the uninteresting set'.  The paradox dissolves once you refuse to let the
predicate absorb facts about its own extension.
--------------------------------------------------------------------- -/

theorem no_uninteresting (Uninteresting : Nat → Prop)
    (h : ∀ n, Uninteresting n → (∀ m, m < n → ¬ Uninteresting m) → False) :
    ∀ n, ¬ Uninteresting n := by
  intro n
  induction n using Nat.strongRecOn with
  | ind n ih => exact fun hu => h n hu ih

/-- Toy notion of interesting: small, or a perfect square. -/
def isSquareB (n : Nat) : Bool := (List.range (n + 1)).any (fun k => k * k == n)

def toyInteresting (n : Nat) : Bool := decide (n < 10) || isSquareB n

#eval s!"Interesting numbers: under a toy notion (n < 10 or a perfect square), the least 'uninteresting' number is {((List.range 100).find? (fun n => !toyInteresting n)).getD 0} — but 'least uninteresting number' is itself an interesting distinction, and the theorem turns that joke into: no number is uninteresting."

/- ---------------------------------------------------------------------
4. ALL HORSES ARE THE SAME COLOR — flawed induction (Polya).

Story: "Proof" by induction that any n horses have the same color.  Base
n = 1: one horse, one color.  Step: given n+1 horses, the first n share a
color by hypothesis, the last n share a color by hypothesis, and the
overlap ties the two groups together.  Hence all horses are the same color.

Formalized: colors are `Bool`; `AllSame l` says any two members of `l` are
equal.  We prove the base case honestly (`horses_base`, every singleton is
AllSame, by `decide`) and then refute the conclusion of the very first
application of the step: `¬ AllSame [true, false]`, also by `decide`.

Resolution / lesson: the induction step is valid only for n ≥ 2.  Going
from n = 1 to n = 2, the "first n" group is [h1] and the "last n" group is
[h2]; their overlap is EMPTY, so nothing ties the two color classes
together.  A single missing base case (n = 2) sinks the whole induction —
the counterexample [true, false] lives exactly at that seam.
--------------------------------------------------------------------- -/

abbrev AllSame (l : List Bool) : Prop :=
  ∀ a, a ∈ l → ∀ b, b ∈ l → a = b

theorem horses_base : ∀ x : Bool, AllSame [x] := by decide

theorem horses_step_fails : ¬ AllSame [true, false] := by decide

/-- Executable check of the AllSame property. -/
def allSameB (l : List Bool) : Bool := l.all (fun a => l.all (fun b => a == b))

#eval s!"Horses: allSame [true,true,true] = {allSameB [true, true, true]}; allSame [true] = {allSameB [true]} and allSame [false] = {allSameB [false]} (both sub-'groups' fine), yet allSame [true,false] = {allSameB [true, false]}: the 1 -> 2 step has an empty overlap."

/- ---------------------------------------------------------------------
5. BURIDAN'S ASS — rational choice.  (NOTE + lemma)

Story: an ass stands exactly midway between two identical bales of hay.
Having no reason to prefer either, and acting only on strict preference,
it starves.

Formalized (lemma only): with exactly two distinct options of equal
utility, there is NO option strictly better than every other — a
symmetric utility function has no strict/unique argmax.  That much is a
theorem.

NOTE — why the rest is only a note: the paradoxical *starvation*
conclusion is not a logical consequence of anything formalizable here; it
needs substantive decision-theoretic premises (that rational action
requires strict preference, that the ass is perfectly rational, that
utilities stay constant while it deliberates, that dying is worse than
either bale).  The standard resolution: rationality permits *picking*
(arbitrary selection among optimal options) as opposed to *choosing* (by
strict preference), so the lemma below is a fact about argmaxes, not a
death sentence for donkeys.
--------------------------------------------------------------------- -/

theorem buridan_no_strict_best {Opt : Type} (u : Opt → Nat) (a b : Opt)
    (hne : a ≠ b) (hsym : u a = u b) (hall : ∀ y : Opt, y = a ∨ y = b) :
    ¬ ∃ x, ∀ y, y ≠ x → u y < u x := by
  intro hex
  cases hex with
  | intro x hx =>
    cases hall x with
    | inl hxa =>
      have hba : b ≠ x := fun hbx => hne (hbx.trans hxa).symm
      have h1 : u b < u x := hx b hba
      rw [hxa] at h1
      omega
    | inr hxb =>
      have hab : a ≠ x := fun hax => hne (hax.trans hxb)
      have h2 : u a < u x := hx a hab
      rw [hxb] at h2
      omega

def bales : List Nat := [5, 5]

#eval s!"Buridan: bale utilities {bales}; options strictly better than every other: {(List.range bales.length).filter (fun i => (List.range bales.length).all (fun j => i == j || decide (bales.getD j 0 < bales.getD i 0)))} — none, so an agent who acts only on strict preference is stuck."

/- ---------------------------------------------------------------------
6. THE OMNIPOTENCE PARADOX — philosophy of religion / self-reference.

Story: can an omnipotent being make a stone so heavy that it cannot lift
it?  If yes, there is a task (lifting that stone) it cannot do; if no,
there is already a task (making such a stone) it cannot do.  Either way it
is not omnipotent.

Formalized: tasks are an inductive type — make the unliftable stone, or
lift stone `s`.  The single hypothesis `hstone` captures what "unliftable"
MEANS: if the being can make the stone, some stone exists that it cannot
lift.  Conclusion: `¬ (∀ t, Can b t)` — universal ability is untenable.
Note the theorem needs no case split: if the being could do everything, it
could make the stone, which yields a stone it cannot lift, contradicting
that it could do everything.

Resolution / lesson: omnipotence-as-universal-ability over a task space
containing self-referential tasks is inconsistent.  Aquinas' resolution:
omnipotence is power over all that is *logically possible*; 'a stone its
maker cannot lift' describes, for a genuinely omnipotent being, a logical
impossibility — and inability to do the logically impossible is no lack
of power.
--------------------------------------------------------------------- -/

inductive Task (StoneId : Type) where
  | makeUnliftableStone : Task StoneId
  | lift (s : StoneId) : Task StoneId

theorem no_omnipotence {StoneId Being : Type} (b : Being)
    (Can : Being → Task StoneId → Prop)
    (hstone : Can b Task.makeUnliftableStone → ∃ s, ¬ Can b (Task.lift s)) :
    ¬ (∀ t, Can b t) := by
  intro hall
  cases hstone (hall Task.makeUnliftableStone) with
  | intro s hs => exact hs (hall (Task.lift s))

#eval s!"Omnipotence: 'can make a stone its maker cannot lift' + 'can perform every task' is contradictory (machine-checked); Aquinas: omnipotence ranges over the logically possible, and the stone task, for an omnipotent maker, is not."

/- ---------------------------------------------------------------------
7. PROTAGORAS v. EUATHLUS (THE COURT PARADOX) — law / self-reference.

Story: Protagoras taught Euathlus law, payment due when Euathlus wins his
first case.  Euathlus takes no cases, so Protagoras sues for the fee.
Protagoras: "If the court rules for me, he must pay (verdict); if it rules
against me, he has won his first case, so he must pay (contract)."
Euathlus: "If the court rules for me, I need not pay (verdict); if it
rules against me, I have not yet won a case, so I need not pay
(contract)."

Formalized: `V` = the court rules for Protagoras (orders payment).  The
four advocated conditionals `V → Pay`, `¬V → Pay`, `V → ¬Pay`, `¬V → ¬Pay`
are jointly inconsistent, by excluded middle on `V`.

Resolution / lesson: each advocate cherry-picks which authority — verdict
or contract — governs each branch, and the four picks cannot all be right:
in the branch where they clash, verdict and contract give opposite orders.
A consistent legal system needs a priority rule (e.g. the verdict
supersedes the contract, or res judicata plus a second suit after this
victory-by-Euathlus triggers the contract).
--------------------------------------------------------------------- -/

theorem court_paradox (V Pay : Prop)
    (protagoras_verdict : V → Pay)
    (protagoras_contract : ¬V → Pay)
    (euathlus_contract : V → ¬Pay)
    (euathlus_verdict : ¬V → ¬Pay) : False := by
  cases Classical.em V with
  | inl hv => exact euathlus_contract hv (protagoras_verdict hv)
  | inr hnv => exact euathlus_verdict hnv (protagoras_contract hnv)

#eval String.intercalate " | "
  ([(true, "verdict", "contract"), (false, "contract", "verdict")].map
    (fun (v, pArg, eArg) =>
      s!"court rules for Protagoras = {v}: Protagoras cites the {pArg} and demands payment; Euathlus cites the {eArg} and refuses"))

/- ---------------------------------------------------------------------
8. CARROLL'S 'WHAT THE TORTOISE SAID TO ACHILLES' — logic / inference.

Story: the Tortoise grants `P` and `P → Q` but refuses to accept `Q` until
Achilles adds the premise "if P and (P → Q) then Q" — and then refuses
again pending a further premise about THAT, forever.

Formalized: modus ponens is a two-symbol PROOF TERM, `fun hp f => f hp` —
a rule we USE, not a premise we cite.  The second theorem shows the
Tortoise's demanded extra premise is powerless: even after adding
`P → (P → Q) → Q` as a hypothesis, one still discharges the goal by
APPLYING it — the very act the Tortoise refuses.

Resolution / lesson: the regress dissolves because inference rules are not
premises.  Treating modus ponens as one more proposition to be granted is
precisely what spawns the infinite regress; in type theory the rule is
function application itself, built into the judgment, not written among
the hypotheses.
--------------------------------------------------------------------- -/

theorem mp (P Q : Prop) : P → (P → Q) → Q :=
  fun hp f => f hp

theorem tortoise_premise_gains_nothing (P Q : Prop) :
    P → (P → Q) → (P → (P → Q) → Q) → Q :=
  fun hp hpq hC => hC hp hpq

#eval s!"Carroll: modus ponens is the term 'fun hp f => f hp' — application itself; adding it as a premise C still requires applying C, so the regress never starts for rules."

/- ---------------------------------------------------------------------
9. THE DRINKER PARADOX — classical first-order logic.

Story: in every (non-empty) pub there is someone such that, if THEY are
drinking, then EVERYONE in the pub is drinking.

Formalized: for any inhabited `Pub` and any predicate `D`, classically
`∃ x, D x → ∀ y, D y`.  By cases on `∀ y, D y`: if everyone drinks, any
patron works; otherwise, by contradiction there is a non-drinker `w`, and
the implication from `D w` is vacuously true.

Resolution / lesson: it sounds absurd because natural language hears
"if x drinks then everyone drinks" as a causal or dispositional claim
about a magically influential patron.  Materially it is just
`¬ D x ∨ ∀ y, D y`, and classical logic (excluded middle picking the
witness non-constructively) always supplies such an x.  The witness
depends on the drinking pattern — which is exactly why no constructive
proof exists.
--------------------------------------------------------------------- -/

theorem drinker {Pub : Type} (p0 : Pub) (D : Pub → Prop) :
    ∃ x, D x → ∀ y, D y := by
  cases Classical.em (∀ y, D y) with
  | inl hall => exact ⟨p0, fun _ => hall⟩
  | inr hnall =>
    have hex : ∃ w, ¬ D w :=
      Classical.byContradiction fun hne =>
        hnall (fun y => Classical.byContradiction fun hny => hne ⟨y, hny⟩)
    cases hex with
    | intro w hw => exact ⟨w, fun hdw => absurd hdw hw⟩

def pubDrinks : List Bool := [true, false, true, true]

#eval s!"Drinker: drinking pattern {pubDrinks}; witness index for 'if this one drinks, all drink': {if pubDrinks.all (fun b => b) then some 0 else pubDrinks.findIdx? (fun b => !b)} — a non-drinker makes the implication vacuous (any patron works when all drink)."

/- ---------------------------------------------------------------------
10. MATERIAL IMPLICATION ODDITIES — classical propositional logic.

Story: material implication validates sentences that sound wrong out loud:
"either (if P then Q) or (if Q then P)" holds for ANY two propositions —
e.g. either 'if it rains, 2+2=5' or 'if 2+2=5, it rains'.  And a false
antecedent makes any conditional true: 'if the moon is cheese, I am king'.

Formalized: `(P → Q) ∨ (Q → P)` by cases on `P` (if `P` holds, the RIGHT
disjunct `Q → P` holds constantly; if not, the LEFT holds vacuously) — and
`¬P → (P → Q)`, vacuous truth itself.

Resolution / lesson: `→` is truth-functional; English 'if' carries
relevance and counterfactual force that `→` deliberately drops.  These
'paradoxes' are the purchase price of truth-functionality — what they
teach is that formalizing 'if' as `→` is a modeling decision, not a
discovery.
--------------------------------------------------------------------- -/

theorem imp_or_converse (P Q : Prop) : (P → Q) ∨ (Q → P) := by
  cases Classical.em P with
  | inl hp => exact Or.inr (fun _ => hp)
  | inr hnp => exact Or.inl (fun hp' => absurd hp' hnp)

theorem vacuous_truth (P Q : Prop) (hnp : ¬P) : P → Q :=
  fun hp => absurd hp hnp

#eval s!"Material implication: (P -> Q) or (Q -> P) holds on all four Boolean rows: {[(false, false), (false, true), (true, false), (true, true)].all (fun (p, q) => (!p || q) || (!q || p))}; false antecedent rows make P -> Q true: {[(false, false), (false, true)].all (fun (p, q) => !p || q)}."

/- ---------------------------------------------------------------------
11. HEMPEL'S RAVENS — philosophy of science / confirmation.

Story: 'all ravens are black' is logically equivalent to 'all non-black
things are non-ravens'.  A green apple is a non-black non-raven, so it
confirms the second hypothesis — and, by equivalence, apparently confirms
'all ravens are black'.  Indoor ornithology!

Formalized: the equivalence itself, the engine of the paradox:
`(∀ x, Raven x → Black x) ↔ (∀ x, ¬Black x → ¬Raven x)`.  The forward
direction is constructive; the reverse uses classical `byContradiction`
(double negation elimination on `Black x`).

Resolution / lesson: the equivalence is impeccable, so whatever confirms
one side confirms the other.  The standard (Bayesian) resolution keeps the
equivalence and bites the bullet quantitatively: the green apple DOES
confirm 'all ravens are black', but by a minuscule amount, because
non-black things vastly outnumber ravens.  The felt absurdity mistakes
'confirms negligibly' for 'confirms not at all'.
--------------------------------------------------------------------- -/

theorem ravens_contrapositive {α : Type} (Raven Black : α → Prop) :
    (∀ x, Raven x → Black x) ↔ (∀ x, ¬ Black x → ¬ Raven x) :=
  ⟨fun h x hnb hr => hnb (h x hr),
   fun h x hr => Classical.byContradiction fun hnb => h x hnb hr⟩

/-- A toy world: (name, is-raven, is-black). -/
def world : List (String × Bool × Bool) :=
  [("raven-A", true, true), ("raven-B", true, true),
   ("green apple", false, false), ("white shoe", false, false)]

#eval
  let allRavensBlack := world.all (fun (_, r, b) => !r || b)
  let contrapositive := world.all (fun (_, r, b) => b || !r)
  s!"Ravens: in a 4-object world, 'all ravens are black' = {allRavensBlack} and 'all non-black things are non-ravens' = {contrapositive}; the green apple and the white shoe are evidence for both or for neither — the equivalence is the engine of the paradox."

/- ---------------------------------------------------------------------
Catalog: one (name, status) entry per paradox.
--------------------------------------------------------------------- -/

def catalog : List (String × String) :=
  [("Sorites (heap)",
    "THEOREM: Heap 1000000 + tolerance step entail Heap 0 (and with ¬Heap 0, False): tolerance, classical logic, and a sharp predicate cannot coexist"),
   ("Ship of Theseus",
    "THEOREM: equivalence axioms + plank-at-a-time sameness + rebuilt-is-original force Same (ships 1000) rebuilt, so also denying that yields False"),
   ("Interesting number paradox",
    "THEOREM: 'the least uninteresting number would be interesting' entails no number is uninteresting, by strong induction (Nat.strongRecOn)"),
   ("All horses same color",
    "VERIFIED: decide proves every singleton Bool-list AllSame but refutes AllSame [true, false] — the 1 -> 2 induction step has empty overlap"),
   ("Buridan's ass",
    "NOTE: starvation needs decision-theoretic premises beyond logic; proved lemma: two distinct equal-utility options admit no strictly-best option"),
   ("Omnipotence paradox",
    "THEOREM: 'can make a stone its maker cannot lift' refutes 'can do every task'; Aquinas restricts omnipotence to the logically possible"),
   ("Protagoras v. Euathlus",
    "THEOREM: the four advocated verdict/contract conditionals are jointly inconsistent by excluded middle on the verdict"),
   ("Carroll's Tortoise",
    "THEOREM: modus ponens is the proof term fun hp f => f hp — a rule, not a premise; the added premise still needs the rule, hence the regress"),
   ("Drinker paradox",
    "THEOREM: classically some patron's drinking entails everyone's — a pure artifact of material implication plus excluded middle"),
   ("Material implication oddities",
    "THEOREM: (P -> Q) or (Q -> P) always holds classically, and ¬P entails P -> Q (vacuous truth)"),
   ("Hempel's ravens",
    "THEOREM: 'all ravens are black' is equivalent to its contrapositive, so a green apple confirms both sides equally")]

end Paradoxes.VagueIdentity
