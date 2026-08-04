/-!
# Paradoxes across domains: Knowledge and Belief (Epistemology)

Machine-checked formalizations of the classical epistemic paradoxes: Fitch's
paradox of knowability, Moore's paradox ("it's raining but I don't believe
it"), the Knower paradox (Kaplan–Montague), Gödel's first incompleteness
theorem viewed as the tamed liar (with the Curry/Löb connection), the lottery
paradox, the preface paradox, a two-day miniature of the unexpected hanging,
and Goodman's "grue" (the new riddle of induction).

The pattern throughout: the epistemic principles that generate each paradox
are explicit theorem hypotheses — abstract operators `K`, `B`, `D`, `Prov` of
type `Prop → Prop` together with the axioms the story attributes to them.
Each theorem then shows those principles are jointly contradictory, or entail
the story's surprising conclusion.  Everything is core Lean 4: no imports, no
axioms, no `sorry`.
-/

namespace Paradoxes.EpistemicBelief

/- ======================================================================
   1. FITCH'S PARADOX OF KNOWABILITY  (Frederic Fitch 1963 — epistemology)

   Story: the *knowability principle* — beloved of verificationists and
   anti-realists — says every truth could in principle be known.  Fitch
   showed this modest-sounding thesis collapses into the wildly immodest
   "every truth is (actually) known", using only that knowledge is factive
   and distributes over conjunction.

   Formalized: `K p` = "p is known (at some time, by someone)", `D p` =
   "p is possible".  Hypotheses: `dist` (K distributes over ∧), `fact`
   (knowledge implies truth), `necneg` (a false proposition is not
   possible — the modal rule from ⊢ ¬p infer ⊢ ¬◇p, here strengthened to
   an implication for a propositional setting), and `knowable` (every
   truth is possibly known).  Conclusion: ∀ q, q → K q.

   Resolution / lesson: the engine is the Moore sentence `q ∧ ¬K q`
   ("q, but q is not known"), which is *provably unknowable* (lemma
   below).  If q were an unknown truth, that Moore sentence would be a
   truth whose knowledge is impossible — contradicting knowability.  So
   under the knowability principle there are no unknown truths.  Either
   give up verificationism or weaken the knowability principle.
   ====================================================================== -/

/-- The Moore sentence `q ∧ ¬K q` can never be known, for any factive `K`
that distributes over conjunction: knowing it would yield both `K q` and
(via factivity of the second conjunct) `¬K q`. -/
theorem moore_unknowable (K : Prop → Prop)
    (dist : ∀ p q, K (p ∧ q) → K p ∧ K q)
    (fact : ∀ p, K p → p)
    (q : Prop) : ¬ K (q ∧ ¬ K q) := fun h =>
  (fact _ (dist _ _ h).2) (dist _ _ h).1

/-- Fitch's collapse: if every truth is possibly known, every truth is known.
Classical logic is used exactly once (`Classical.byContradiction`). -/
theorem fitch_knowability_collapse (K D : Prop → Prop)
    (dist : ∀ p q, K (p ∧ q) → K p ∧ K q)
    (fact : ∀ p, K p → p)
    (necneg : ∀ p, ¬ p → ¬ D p)
    (knowable : ∀ p, p → D (K p)) :
    ∀ q, q → K q := fun q hq =>
  Classical.byContradiction fun hnKq =>
    necneg (K (q ∧ ¬ K q)) (moore_unknowable K dist fact q)
      (knowable (q ∧ ¬ K q) ⟨hq, hnKq⟩)

#eval IO.println s!"Fitch: 'every truth is knowable' + factive, ∧-distributing K ⟹ \
'every truth is KNOWN' (theorem fitch_knowability_collapse) — verificationism collapses omniscience-ward."

/- ======================================================================
   2. MOORE'S PARADOX  (G. E. Moore, 1940s — epistemology/philosophy of language)

   Story: "It is raining, but I don't believe it is raining."  The sentence
   can perfectly well be TRUE (it rains and I'm oblivious), yet no one can
   coherently *assert* or *know* or *self-transparently believe* it.

   Formalized: the lemma `moore_unknowable` above IS the formal core of
   Moore's paradox for knowledge: `K (q ∧ ¬K q)` is contradictory even
   though `q ∧ ¬K q` is contingent.  For belief — which is NOT factive —
   we prove the belief version: an agent whose beliefs distribute over ∧,
   are positively introspective (`B p → B (B p)`), and are consistent
   (never `B p` and `B ¬p` together) cannot believe a Moore sentence.

   Resolution / lesson: Moorean sentences mark the gap between what is
   true and what one subject can coherently represent as true from the
   inside.  Absurdity of *attitude*, not of *content* — the same engine
   that drives Fitch's collapse.
   ====================================================================== -/

/-- Moore's paradox for belief: a consistent, ∧-distributing, positively
introspective believer can never believe "q, but I don't believe q" —
even though that sentence may well be true. -/
theorem moore_unbelievable (B : Prop → Prop)
    (dist : ∀ p q, B (p ∧ q) → B p ∧ B q)
    (introspect : ∀ p, B p → B (B p))
    (consistent : ∀ p, B p → B (¬ p) → False)
    (q : Prop) : ¬ B (q ∧ ¬ B q) := fun h =>
  consistent (B q) (introspect _ (dist _ _ h).1) (dist _ _ h).2

#eval IO.println s!"Moore: 'q but I don't believe q' can be TRUE, yet is unknowable \
(moore_unknowable) and unbelievable for any consistent introspective believer (moore_unbelievable)."

/- ======================================================================
   3. THE KNOWER PARADOX  (Kaplan & Montague 1960 — epistemology/logic)

   Story: consider the sentence S = "S is not known."  If knowledge is
   factive (`K S → S`) and successful proof yields knowledge
   (necessitation `S → K S`, read: 'this very reasoning establishes S,
   hence S is known'), the sentence explodes just like the liar.

   Formalized: hypotheses `hfix : S ↔ ¬ K S`, `hfact : K S → S`,
   `hnec : S → K S` jointly yield `False` — no possible world, no
   interpretation of K, satisfies all three.

   Resolution / lesson: Montague's theorem — a predicate of *sentences*
   obeying even these weak epistemic laws cannot exist for a language
   with self-reference; knowledge must be an operator stratified away
   from the syntax it speaks about, or the laws must be weakened.  The
   liar tamed by 'true' becomes the Knower tamed by 'known'.
   ====================================================================== -/

theorem knower (K : Prop → Prop) (S : Prop)
    (hfix : S ↔ ¬ K S) (hfact : K S → S) (hnec : S → K S) : False :=
  have hnKS : ¬ K S := fun hKS => hfix.mp (hfact hKS) hKS
  hnKS (hnec (hfix.mpr hnKS))

#eval IO.println s!"Knower: S ↔ ¬K S + factivity + necessitation ⟹ False (theorem knower) — \
'known' cannot be a self-applicable sentence predicate."

/- ======================================================================
   4. GÖDEL'S FIRST INCOMPLETENESS THEOREM AS THE TAMED LIAR
      (Kurt Gödel 1931 — logic/epistemology)

   Story: the liar ("this sentence is false") is contradictory.  Gödel's
   move: replace *truth* by *provability*.  The sentence G = "G is not
   provable" is no longer paradoxical — it is simply TRUE and UNPROVABLE,
   provided the proof system is sound.

   Formalized: from `hsound : ∀ p, Prov p → p` and the fixed point
   `hfix : G ↔ ¬ Prov G` we derive `G ∧ ¬ Prov G`.  Compare `knower`
   above: identical skeleton, but dropping necessitation (`p → Prov p`
   is exactly what FAILS for provability) turns contradiction into
   theorem.  That failure IS incompleteness.

   Löb/Henkin/Curry connection: the Henkin sentence H ↔ Prov H ("this
   sentence is provable") is — surprisingly — actually PROVABLE, by
   Löb's theorem.  Our propositional skeleton cannot derive that: Löb's
   proof needs the internal derivability conditions and a fixed point
   for `Prov L → p`, and its engine is precisely Curry's paradox with
   provability in place of truth.  We prove the pure propositional Curry
   core below: a fixed point C ↔ (C → p) alone proves the arbitrary p —
   no negation, no classical logic.  This is why naive 'truth' (which
   satisfies full necessitation and hence delivers such fixed points'
   assumptions) is lethal, while 'provability' merely yields Löb's law.
   ====================================================================== -/

theorem goedel_tamed_liar (Prov : Prop → Prop) (G : Prop)
    (hsound : ∀ p, Prov p → p) (hfix : G ↔ ¬ Prov G) :
    G ∧ ¬ Prov G :=
  have hnP : ¬ Prov G := fun hP => hfix.mp (hsound G hP) hP
  ⟨hfix.mpr hnP, hnP⟩

/-- Curry's paradox, the engine inside Löb's theorem: a proposition
asserting "if I hold, then p" proves p outright — purely constructively. -/
theorem curry_core (C p : Prop) (hfix : C ↔ (C → p)) : p :=
  have hC : C := hfix.mpr (fun hC' => hfix.mp hC' hC')
  hfix.mp hC hC

#eval IO.println s!"Gödel: G ↔ ¬Prov G + soundness ⟹ G ∧ ¬Prov G (goedel_tamed_liar): \
the liar, tamed — true and unprovable.  Curry core: C ↔ (C → p) ⊢ p (curry_core), \
the engine of Löb's theorem."

/- ======================================================================
   5. THE LOTTERY PARADOX  (Henry Kyburg 1961 — epistemology)

   Story: a fair 1000-ticket lottery.  For each ticket i, P(ticket i
   loses) = 0.999, so it is rational to *accept* "ticket i loses".  But
   accepting all such claims and conjoining them yields "every ticket
   loses" — while you also rationally believe "some ticket wins".

   Formalized (3-ticket miniature): `B L1`, `B L2`, `B L3` (each ticket
   believed to lose), conjunctive closure of belief, belief that not all
   lose, and consistency of belief.  These five principles are jointly
   contradictory.

   Resolution / lesson: high-probability acceptance is NOT closed under
   conjunction — probabilities multiply while acceptance naively
   aggregates.  One of: reject conjunctive closure (Kyburg), reject the
   acceptance rule, or tolerate inconsistent-but-rational belief sets.
   ====================================================================== -/

theorem lottery (B : Prop → Prop) (L1 L2 L3 : Prop)
    (hB1 : B L1) (hB2 : B L2) (hB3 : B L3)
    (agg : ∀ p q, B p → B q → B (p ∧ q))
    (someWinner : B (¬ (L1 ∧ L2 ∧ L3)))
    (consistent : ∀ p, B p → B (¬ p) → False) : False :=
  consistent (L1 ∧ L2 ∧ L3) (agg _ _ hB1 (agg _ _ hB2 hB3)) someWinner

#eval
  let p : Rat := 999/1000
  IO.println s!"Lottery (exact): P(ticket i loses) = {p} — accept each; \
but P(tickets 1∧2∧3 lose) = {p * p * p}, already sliding, and beliefs \
conjoined 1000 times contradict 'someone wins' (theorem lottery)."

#eval
  let pAllLose : Float := Float.pow 0.999 1000.0
  IO.println s!"Lottery (numeric): P(ALL 1000 tickets lose) = 0.999^1000 ≈ {pAllLose} — \
far below any acceptance threshold: high probability is not closed under ∧."

/- ======================================================================
   6. THE PREFACE PARADOX  (David Makinson 1965 — epistemology)

   Story: a careful author believes every individual claim C1, ..., Cn in
   her book, yet writes in the preface: "errors doubtless remain" — i.e.
   she also believes NOT every claim is true.  Same five principles,
   same contradiction.

   Formalized: literally the lottery theorem instantiated with book
   claims for lottery tickets and the modest preface for "some ticket
   wins" — a one-line instance.

   Resolution / lesson: identical skeleton, opposite moral emphasis.
   The lottery is usually read as an argument AGAINST an acceptance rule
   for beliefs; the preface as evidence that rational agents can — and
   even should — hold jointly inconsistent beliefs.  Formally there is
   nothing to choose between them, which is itself the point.
   ====================================================================== -/

theorem preface (B : Prop → Prop) (C1 C2 C3 : Prop)
    (h1 : B C1) (h2 : B C2) (h3 : B C3)
    (agg : ∀ p q, B p → B q → B (p ∧ q))
    (modestPreface : B (¬ (C1 ∧ C2 ∧ C3)))
    (consistent : ∀ p, B p → B (¬ p) → False) : False :=
  lottery B C1 C2 C3 h1 h2 h3 agg modestPreface consistent

#eval IO.println s!"Preface: believe every claim in your book AND 'errors remain' — \
the very lottery inconsistency (theorem preface := lottery), worn with pride."

/- ======================================================================
   7. THE UNEXPECTED HANGING, 2-DAY MINIATURE
      (surprise-examination paradox, 1940s folklore — epistemology)

   Story: the judge announces "you will be hanged Monday or Tuesday, and
   you will not know the day in advance."  Prisoner: "Tuesday is out —
   by Monday evening I'd know it.  But then Monday is out too — with
   Tuesday excluded, Monday would be predictable."  He rules out every
   day... and is hanged, completely surprised, on Monday.

   Formalized: the honest propositional content of the prisoner's
   argument for two days: `hOne : H1 ∨ H2` (the announced hanging),
   `hSurprise2 : ¬H2` (a Tuesday hanging would not surprise), and
   `hSurprise1 : ¬H1` (once Tuesday's exclusion is common knowledge,
   Monday would not surprise either).  Trivial or-elimination shows the
   three are jointly inconsistent.

   Resolution / lesson: the inconsistency is the whole propositional
   story — the judge's announcement, taken as common knowledge USABLE in
   the prisoner's own deductions, is self-defeating.  What the paradox
   really demands is an epistemic modal logic with temporally indexed
   knowledge operators, where 'surprise' means ¬K-the-evening-before;
   there the announcement is a Moore-like blindspot (compare item 2),
   not a plain proposition.  This propositional miniature honestly
   records only the contradiction, not the modal diagnosis.
   ====================================================================== -/

theorem unexpected_hanging_two_day (H1 H2 : Prop)
    (hOne : H1 ∨ H2) (hSurprise2 : ¬ H2) (hSurprise1 : ¬ H1) : False :=
  hOne.elim hSurprise1 hSurprise2

/-- Backward-induction elimination trace (fuel-indexed): repeatedly drop the
last remaining day, as the prisoner argues no last-remaining day can surprise. -/
def elimTrace : Nat → List String → List (List String)
  | 0, l => [l]
  | n + 1, l => l :: elimTrace n l.dropLast

#eval
  let days := ["Mon", "Tue", "Wed", "Thu", "Fri"]
  IO.println s!"Unexpected hanging: prisoner's backward induction {elimTrace days.length days} — \
every day eliminated, yet a Wednesday noose still surprises; the 2-day core is theorem \
unexpected_hanging_two_day."

/- ======================================================================
   8. GOODMAN'S GRUE — THE NEW RIDDLE OF INDUCTION
      (Nelson Goodman 1955 — epistemology/philosophy of science)

   Story: call an object GRUE if it is green when examined (before t)
   and blue otherwise; BLEEN likewise with the colors swapped.  Every
   emerald observed so far confirms "all emeralds are green" and "all
   emeralds are grue" EQUALLY — yet the two hypotheses disagree about
   every unexamined emerald.  Why is 'green' projectible and 'grue' not?

   Formalized: with Bool data (examined, green, blue) per object, define
   grue/bleen from green/blue.  Verified exhaustively by `decide`: green
   is exactly (if examined then grue else bleen), and blue is exactly
   (if examined then bleen else grue) — the very schema that defined
   grue from green.  So "grue is gerrymandered / positional / defined
   with a time clause" is TRUE ONLY RELATIVE to taking green/blue as
   primitive: a grue/bleen speaker says the same of green with equal
   right.  The asymmetry cannot be stated language-neutrally.

   Resolution / lesson: projectibility ('entrenchment', natural-kind
   status) is extra structure beyond extension and definability — pure
   logic, as this decidable symmetry shows, will never supply it.
   ====================================================================== -/

/-- An object is grue iff green-when-examined, blue-when-not. -/
def grue (examined green blue : Bool) : Bool := if examined then green else blue

/-- An object is bleen iff blue-when-examined, green-when-not. -/
def bleen (examined green blue : Bool) : Bool := if examined then blue else green

/-- The definitional symmetry, exhaustively checked over all Bool worlds:
green/blue are definable from grue/bleen by exactly the "gerrymandered"
schema that defined grue/bleen from green/blue. -/
theorem grue_green_symmetry : ∀ e g b : Bool,
    (g = if e then grue e g b else bleen e g b) ∧
    (b = if e then bleen e g b else grue e g b) := by decide

#eval
  let emeralds : List (Bool × Bool × Bool) :=
    [(true, true, false), (true, true, false), (true, true, false)]
  let allGreen := emeralds.all fun (_, g, _) => g
  let allGrue  := emeralds.all fun (e, g, b) => grue e g b
  IO.println s!"Grue: all {emeralds.length} examined emeralds green? {allGreen}; all grue? {allGrue} — \
identical evidence for rival futures, and by grue_green_symmetry 'green' is exactly as \
gerrymandered in grue-speak as 'grue' is in green-speak."

/- ====================================================================== -/

def catalog : List (String × String) :=
  [("Fitch's knowability paradox",
    "THEOREM: knowability + factive ∧-distributing K entail, classically, every truth is already known"),
   ("Moore's paradox",
    "THEOREM: 'q but I don't know/believe q' is unknowable, and unbelievable for consistent introspective belief"),
   ("The Knower (Kaplan–Montague)",
    "THEOREM: S ↔ ¬K S with factivity and necessitation is contradictory"),
   ("Gödel I as tamed liar",
    "THEOREM: sound Prov with G ↔ ¬Prov G yields G true and unprovable; Löb/Henkin noted"),
   ("Curry core of Löb's theorem",
    "THEOREM: C ↔ (C → p) proves p outright, constructively"),
   ("Lottery paradox",
    "THEOREM: per-ticket belief + conjunctive closure + 'someone wins' + consistency are jointly inconsistent"),
   ("Preface paradox",
    "THEOREM: same skeleton as lottery, instantiated for book claims and a modest preface"),
   ("Unexpected hanging (2-day)",
    "THEOREM: the announcement premises are jointly inconsistent; full diagnosis needs epistemic modal logic"),
   ("Goodman's grue",
    "VERIFIED: by decide, green = (if examined then grue else bleen) — the symmetry is language-relative")]

end Paradoxes.EpistemicBelief
