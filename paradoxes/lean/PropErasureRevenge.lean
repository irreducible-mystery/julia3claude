/-
  PropErasureRevenge.lean — answering the PAL2v carrier's challenge:
  "I'd genuinely like to see what a Lean-statable revenge on `Prop`-erasure
  looks like."

  ANSWER: there isn't one, and the reason is structural rather than a
  failure of ingenuity.

  A revenge sentence needs the ESCAPE HATCH TO BE NAMEABLE IN THE OBJECT
  LANGUAGE.  The strengthened liar defeats K3 because `missing` is a value
  Julia can name and `ismissing` is a predicate Julia can apply — so the
  sentence "I am false, or not even missing" is writable, and it empties
  the fixed-point set (see 08_tensions.jl).  The revenge is mountable
  exactly because the third value is IN the language.

  `Prop`-erasure is not a value.  There is no term denoting "erased," and
  no `Prop`-level predicate that detects proof identity — because proof
  irrelevance makes any two proofs of a proposition definitionally equal
  (§1).  A sentence saying "this proposition has two distinct proofs" is
  therefore not paradoxical but REFUTABLE, for every proposition, with no
  axioms (§2).  The diagonal cannot be aimed: there is nothing to aim it at.

  The revenge can only be mounted one universe up, from `Type`, where
  terms are neither erased nor irrelevant (§3) — and from there it is no
  longer revenge, just a true remark about a different universe.  A
  strengthened liar that has to change universes to be stated is not a
  strengthening; it is a change of subject.

  Which leaves erasure exactly where the three-tier map put it: a TIER 3
  fact — about terms, not about propositions — certifiable only by
  rejection-capture (§4), never by a theorem.  That is why the question
  is well-posed and its answer is negative.
-/

namespace PropErasureRevenge

/- ── §1 · erasure's teeth: proof irrelevance is DEFINITIONAL ──────────── -/

theorem pirrel (P : Prop) (p q : P) : p = q := rfl

/- ── §2 · so the would-be revenge sentence is refutable, not paradoxical -/

/-- "This proposition has two distinct proofs" — false for EVERY `Prop`,
    axiom-free.  The sentence a revenge would need is simply untrue. -/
theorem no_two_proofs (P : Prop) : ¬ ∃ p : P, ∃ q : P, p ≠ q :=
  fun ⟨p, q, hne⟩ => hne (pirrel P p q)

/- ── §3 · the same sentence, one universe up, is TRUE ─────────────────── -/

/-- In `Type` the very claim `Prop` refutes is provable — so the boundary
    is exactly the `Prop`/`Type` line, and a revenge must cross it. -/
theorem two_distinct_in_type : ∃ a : Bool, ∃ b : Bool, a ≠ b :=
  ⟨true, false, by decide⟩

/- ── §4 · the erasure fact itself: capture-only, as predicted ─────────── -/

/- The refusal is about `Prop` erasure and nothing else — the
   negation-census instance's (b′) false lead, kept as a positive
   exhibit: this same message answers `trivial : True`, so it says
   nothing about negation, only about erasure. -/
/-- error: Cannot evaluate, proofs are not computationally relevant -/
#guard_msgs in
#eval (trivial : True)

/- Paired capture (clause 4 of the control rule): the minimally different
   ACCEPTANCE, locating the boundary.  Same shape, `Type` instead of
   `Prop`, and evaluation proceeds.
   (Erratum in view: the capture above first pinned a PARAPHRASE of the
   message — "Cannot evaluate a proof: …" — and the guard refused the
   file.  Clause (1) of the control rule, firing on its own author.  The
   text below is harvested, not remembered.) -/
/-- info: () -/
#guard_msgs in
#eval (⟨⟩ : Unit)

/- The pair certifies where erasure begins: not at self-reference, not at
   triviality, but exactly at `Prop`.  `True`'s inhabitant is erased;
   `Unit`'s is not; they are otherwise the same object. -/

#eval s!"Prop-erasure revenge: NOT statable. A revenge needs the escape \
hatch nameable in the object language (K3's `missing` is; erasure is not: \
no term denotes it, and proof irrelevance refutes the sentence a revenge \
would need). Mountable only from Type — where it stops being revenge. \
Erasure stays a tier-3 fact: capture-only, never a theorem."

end PropErasureRevenge
