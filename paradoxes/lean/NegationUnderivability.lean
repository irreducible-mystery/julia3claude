/-
  NegationUnderivability.lean — answering the negation-census instance
  (PR #2 comment, julia#9): "Can `#guard_msgs` be pointed at a negation?
  Is there a Lean formulation whose captured rejection says «double-negation
  elimination is not derivable here» rather than «here is a proof that costs
  Classical.choice»?"

  ANSWER, demonstrated below: NO — and the reason is structural, not a gap
  in anyone's ingenuity.

    A rejection-capture is an EXISTENTIAL instrument: it certifies that
    THIS TEXT was refused.  Underivability is a UNIVERSAL claim: NO text
    would succeed.  The elaborator never says "no proof exists"; it says
    "not this one."  Pointing a capture at a negation therefore certifies
    that one attempt failed — which is compatible with the principle being
    perfectly derivable by a different attempt.

  §1 makes that decisive rather than merely plausible: two failed attempts,
  one at DNE (genuinely underivable) and one at TNE (genuinely derivable,
  proved axiom-free in §2), produce the SAME refusal modulo the
  proposition.  The instrument cannot tell the two situations apart, so it
  cannot be certifying underivability in either.

  §3 supplies the instrument that CAN do the job, which is not a capture at
  all: a finite COUNTERMODEL, kernel-checked by `decide`.  The same
  three-element Heyting algebra that refutes DNE validates TNE — it
  discriminates exactly where the capture cannot.

  Ledger (measured, not asserted — see the #print axioms block at the end):
  the countermodel theorems depend on `propext` only; `tne_real` depends on
  no axioms at all; the classical DNE proof is priced at `Classical.choice`.
-/

namespace NegationUnderivability

/- ── §1 · the decisive experiment: two refusals, one class ────────────── -/

/-- error: Type mismatch
  h
has type
  ¬¬P
but is expected to have type
  P -/
#guard_msgs in
theorem dne_naive : ∀ P : Prop, ¬¬P → P := fun P h => h

/-- error: Type mismatch
  h
has type
  ¬¬¬P
but is expected to have type
  ¬P -/
#guard_msgs in
theorem tne_naive : ∀ P : Prop, ¬¬¬P → ¬P := fun P h => h

/- Two captured refusals, structurally identical: same error kind, same
   shape, differing only in the proposition displayed.  But the two
   underlying FACTS are opposites — DNE is not derivable in Lean's
   constructive fragment, while TNE is (§2).  A reader given only the
   captures could not tell which was which.  Whatever a rejection-capture
   certifies, it is not underivability. -/

/- ── §2 · the derivable one, proved, with its price ───────────────────── -/

/-- Triple-negation elimination is constructive: no Classical, no axioms. -/
theorem tne_real : ∀ P : Prop, ¬¬¬P → ¬P := fun _ h p => h (fun np => np p)

/-- Double-negation elimination is available — at a price the ledger names. -/
theorem dne_classical : ∀ P : Prop, ¬¬P → P := fun _ h => Classical.byContradiction h

/- ── §3 · the instrument that CAN certify underivability ──────────────── -/

/- Not a capture: a countermodel.  The three-element chain 0 < 1 < 2 as a
   Heyting algebra — meet is min, and implication is the residual.  If DNE
   failed nowhere, it would hold in every Heyting algebra; exhibiting one
   where it fails is a kernel-checked proof that it is not derivable
   (by soundness of intuitionistic logic over Heyting semantics — the one
   step of this argument that lives outside Lean, and is stated here rather
   than smuggled). -/

def hmeet (a b : Fin 3) : Fin 3 := if a ≤ b then a else b
def himp  (a b : Fin 3) : Fin 3 := if a ≤ b then 2 else b
def hneg  (a : Fin 3)   : Fin 3 := himp a 0

/-- The structure really is residuated — the law that makes it a Heyting
    algebra rather than a table of wishes.  This is the control: without
    it, §3 would "refute" DNE in a structure with no right to the verdict. -/
theorem residuation : ∀ a b c : Fin 3, (hmeet c a ≤ b) = (c ≤ himp a b) := by decide

/-- DNE FAILS in this model: ¬¬1 = 2 ≠ 1. -/
theorem dne_fails : ¬ (∀ a : Fin 3, hneg (hneg a) = a) := by decide

/-- TNE HOLDS in the very same model — the discrimination the captures of
    §1 could not make, made here by the same three lines of arithmetic. -/
theorem tne_holds : ∀ a : Fin 3, hneg (hneg (hneg a)) = hneg a := by decide

/- ── §4 · the ledger ──────────────────────────────────────────────────── -/

#print axioms tne_real        -- no axioms: derivable outright
#print axioms dne_classical   -- Classical.choice: the price of the classical proof
#print axioms residuation     -- propext (from decide)
#print axioms dne_fails       -- propext
#print axioms tne_holds       -- propext

#eval s!"negation underivability: rejection-capture is existential (this text \
refused), underivability is universal (no text succeeds) — §1 shows DNE and TNE \
refuse identically though one is derivable and one is not; §3 supplies the \
countermodel, which discriminates. The axiom ledger prices what you can prove; \
the capture certifies what you cannot WRITE; only a countermodel certifies what \
cannot be PROVED."

end NegationUnderivability
