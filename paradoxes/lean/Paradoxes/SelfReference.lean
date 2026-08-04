/-!
# Paradoxes across domains: Self-Reference and Semantic Paradoxes

Machine-checked formalizations of the classical self-referential and semantic
paradoxes: the Liar and its many costumes (Epimenides, Jourdain's cards,
Pinocchio, the crocodile dilemma), Curry's paradox, Yablo's paradox,
Grelling–Nelson's "heterological", Tarski's undefinability of truth, and
Quine's quotational liar.

The pattern throughout: the *assumptions* of each paradox are explicit theorem
hypotheses, and the theorem shows they are jointly contradictory (or entail a
surprising conclusion).  Natural language can *write* these sentences; the
theorems show that logic has no denotation for them.  Everything is core Lean 4,
no imports, no axioms, no `sorry`.
-/

namespace Paradoxes.SelfReference

/- ======================================================================
   1. THE LIAR PARADOX  (Eubulides of Miletus, 4th c. BC — logic/semantics)

   Story: "This sentence is false."  If it is true, then what it says holds,
   so it is false.  If it is false, then what it says fails, so it is true.

   Formalized: there is NO proposition P with (P ↔ ¬P).  The whole paradox is
   a one-liner from core's `iff_not_self : ¬(a ↔ ¬a)`.

   Resolution / lesson: natural language happily *writes* the liar sentence,
   but the space of propositions contains no denotation for it.  The paradox
   is not a contradiction *in* logic — it is a proof that the assignment
   "this sentence ↦ some proposition P with P ↔ ¬P" is impossible.
   ====================================================================== -/

theorem liar (P : Prop) (h : P ↔ ¬P) : False := iff_not_self h

/-- Finite truth-value analogue, checked exhaustively: no Boolean equals its
own negation.  A two-row truth table, verified by `decide`. -/
theorem liar_bool : ∀ b : Bool, b ≠ !b := by decide

#eval s!"Liar: Bool assignments b with b = !b: {[true, false].filter (fun b => b == !b)} — none; \
no proposition P satisfies P ↔ ¬P (theorem `liar`)"

/- ======================================================================
   2. THE EPIMENIDES 'PARADOX'  (Epimenides the Cretan, ~6th c. BC — logic)

   Story: Epimenides, himself a Cretan, says "All Cretans are liars", i.e.
   "everything a Cretan says is false."  Folklore calls this a paradox — but
   it is NOT one: the situation is merely *informative*, not contradictory.

   Formalized: let `Cretan p` mean "p was asserted by some Cretan", and let E
   be Epimenides' assertion, so E ↔ (∀ p, Cretan p → ¬p), with Cretan E.
   Then (i) ¬E is a theorem — Epimenides spoke falsely; and (ii) classically,
   ∃ p, Cretan p ∧ p — some Cretan at some point said something TRUE.

   Resolution / lesson: unlike the liar, the hypotheses here are consistent;
   they simply *force* an unexpected fact about the world.  The asymmetry
   (E can be false but not true) breaks the vicious circle.
   ====================================================================== -/

/-- Epimenides' statement cannot be true: if it were, it would apply to
itself and refute itself. -/
theorem epimenides_spoke_falsely (Cretan : Prop → Prop) (E : Prop)
    (hE : E ↔ ∀ p, Cretan p → ¬p) (hC : Cretan E) : ¬E :=
  fun he => (hE.mp he) E hC he

/-- Classically, some Cretan once said something true: otherwise "all Cretan
statements are false" would hold, making E true — contradicting the above. -/
theorem some_cretan_spoke_truly (Cretan : Prop → Prop) (E : Prop)
    (hE : E ↔ ∀ p, Cretan p → ¬p) (hC : Cretan E) :
    ∃ p, Cretan p ∧ p :=
  Classical.byContradiction fun hno =>
    have hall : ∀ p, Cretan p → ¬p := fun p hp hpt => hno ⟨p, hp, hpt⟩
    epimenides_spoke_falsely Cretan E hE hC (hE.mpr hall)

#eval s!"Epimenides: NOT a paradox — from 'a Cretan says all Cretan statements are false' \
we derive: his statement is false, AND some Cretan once said something true."

/- ======================================================================
   3. JOURDAIN'S CARD PARADOX  (Philip Jourdain, 1913 — logic/semantics)

   Story: a card reads on the front "The sentence on the back is true" and on
   the back "The sentence on the front is false".  Neither sentence mentions
   itself, yet together they form a liar cycle of length two.

   Formalized: there are no propositions P, Q with (P ↔ Q) and (Q ↔ ¬P).
   Composing the two biconditionals collapses the cycle to P ↔ ¬P.

   Resolution / lesson: self-reference need not be *direct* — reference
   cycles of any length carry the same fixed-point poison, so banning only
   explicit self-mention does not save a naive truth predicate.
   ====================================================================== -/

theorem jourdain (P Q : Prop) (front : P ↔ Q) (back : Q ↔ ¬P) : False :=
  iff_not_self (front.trans back)

/-- Exhaustive Boolean check of the two-card cycle: no assignment works. -/
theorem jourdain_bool : ∀ p q : Bool, ¬(p = q ∧ q = !p) := by decide

#eval s!"Jourdain: Bool solutions to front (p = q) and back (q = !p): \
{[false, true].flatMap (fun p => [false, true].filterMap (fun q => if p == q && q == !p then some (p, q) else none))} — none"

/- ======================================================================
   4. THE PINOCCHIO PARADOX  (Eldridge-Smith, 2010 — semantics/metaphysics)

   Story: Pinocchio's nose grows exactly when he lies (asserts a falsehood).
   Pinocchio says: "My nose will grow now."

   Formalized: let S = "Pinocchio's sentence is true", G = "his nose grows".
   The sentence *asserts* the growth: S ↔ G.  The fairy-tale law makes
   growth the mark of falsehood: G ↔ ¬S.  These two hypotheses are jointly
   contradictory — precisely the Jourdain cycle, hence the liar.

   Resolution / lesson: this is a liar built from a PHYSICAL truth-condition
   (nose growth) rather than a semantic predicate 'true'.  It shows the
   fixed-point problem is not cured by replacing 'is false' with an empirical
   proxy for falsehood: any predicate perfectly correlated with untruth
   re-imports the paradox.  In any consistent world the fairy-tale law and
   the sentence's content cannot both hold.
   ====================================================================== -/

theorem pinocchio (S G : Prop)
    (assertion : S ↔ G)      -- the sentence says: the nose grows
    (fairy_law : G ↔ ¬S)     -- the nose grows exactly when he speaks falsely
    : False :=
  jourdain S G assertion fairy_law

#eval s!"Pinocchio: 'my nose will grow now' + (growth ↔ lying) is jointly impossible — \
a liar with a physical truth-condition (instance of Jourdain's cycle)"

/- ======================================================================
   5. THE CROCODILE DILEMMA  (attributed to the ancient Greeks — logic)

   Story: a crocodile snatches a child and promises: "I will return the child
   iff you correctly predict what I will do."  The parent answers: "You will
   NOT return my child."

   Modeling: let `Return` = "the crocodile returns the child" and `Correct` =
   "the parent's prediction is correct".  The crocodile's promise is
   Return ↔ Correct.  Since the prediction's content is ¬Return, correctness
   means Correct ↔ ¬Return.  Chaining gives Return ↔ ¬Return: the promise
   cannot be kept — the crocodile has no consistent course of action.

   Resolution / lesson: contracts and promises can be *unsatisfiable*: the
   crocodile's conditional promise, applied to this particular prediction, is
   a liar fixed point.  The theorem shows the two hypotheses (promise kept,
   prediction as stated) are jointly impossible.
   ====================================================================== -/

theorem crocodile (Return Correct : Prop)
    (promise : Return ↔ Correct)          -- return the child iff prediction correct
    (prediction : Correct ↔ ¬Return)      -- the parent predicted non-return
    : False :=
  jourdain Return Correct promise prediction

#eval s!"Crocodile: the promise 'return iff predicted correctly' vs the prediction \
'you will not return' has no consistent outcome — Return ↔ ¬Return"

/- ======================================================================
   6. CURRY'S PARADOX  (Haskell Curry, 1942 — logic/set theory)

   Story: "If this sentence is true, then Santa Claus exists."  Suppose the
   sentence is true; then (being a true conditional whose antecedent holds)
   Santa exists.  But that reasoning is exactly a proof of the sentence — so
   it IS true, and Santa Claus exists.  Nothing about negation was used.

   Formalized: from a fixed point P ↔ (P → Q) alone, Q follows — for ANY Q.
   The proof is pure minimal logic: contraction, no negation, no classical
   reasoning.

   Resolution / lesson: a language whose sentences can assert their own
   truth-conditional consequences proves everything.  Naive comprehension
   {x | x ∈ x → Q} manufactures exactly such a fixed point, which is why set
   theory must restrict comprehension — and why 'just drop negation' does
   not tame the semantic paradoxes.
   ====================================================================== -/

theorem curry (P Q : Prop) (h : P ↔ (P → Q)) : Q :=
  have hpq : P → Q := fun hp => (h.mp hp) hp
  hpq (h.mpr hpq)

/-- Boolean shadow, checked exhaustively: whenever p equals the Boolean
implication p → q (i.e. !p || q), q is forced to be true. -/
theorem curry_bool : ∀ p q : Bool, p = (!p || q) → q = true := by decide

#eval s!"Curry: assignments with p = (p → q): \
{[false, true].flatMap (fun p => [false, true].filterMap (fun q => if p == (!p || q) then some (p, q) else none))} \
— in every model of the fixed point, q is true (so a real fixed point proves anything)"

/- ======================================================================
   7. YABLO'S PARADOX  (Stephen Yablo, 1993 — logic/semantics)

   Story: an infinite list of sentences, where sentence n says "every
   sentence after this one is untrue."  No sentence refers to itself, and no
   finite cycle exists — yet no consistent truth assignment is possible.

   Formalized: there is no S : Nat → Prop with
   ∀ n, S n ↔ (∀ m, n < m → ¬ S m).
   Proof: no S n can hold (it would make S (n+1) both false and derivable);
   but then every S n vacuously holds — contradiction at n = 0.

   Resolution / lesson: 'self-reference without self-reference' — the
   pathology lives in the ill-founded pattern of reference, not in any single
   loop.  The finite check below shows infinity is ESSENTIAL: every finite
   Yablo list has a consistent truth assignment (last sentence true, rest
   false), so no `decide` over a finite fragment can exhibit the paradox.
   ====================================================================== -/

theorem yablo (S : Nat → Prop)
    (h : ∀ n, S n ↔ ∀ m, n < m → ¬ S m) : False :=
  have noS : ∀ n, ¬ S n := fun n hn =>
    have hall : ∀ m, n < m → ¬ S m := (h n).mp hn
    hall (n + 1) (Nat.lt_succ_self n)
      ((h (n + 1)).mpr fun m hm => hall m (Nat.lt_trans (Nat.lt_succ_self n) hm))
  noS 0 ((h 0).mpr fun m _ => noS m)

/-- `yabloCheck s = true` iff the Boolean list `s` is a consistent truth
assignment for a FINITE Yablo list: s[i] holds iff all later entries fail. -/
def yabloCheck (s : List Bool) : Bool :=
  (List.range s.length).all fun i =>
    s.getD i false == ((List.range s.length).all fun j =>
      !(decide (i < j)) || !(s.getD j false))

/-- The finite Yablo list of length 5 IS satisfiable (last true, rest false):
the paradox strictly requires infinitely many sentences. -/
theorem finite_yablo_satisfiable :
    yabloCheck [false, false, false, false, true] = true := by decide

#eval s!"Yablo (finite, length 5): assignment FFFFT consistent? {yabloCheck [false, false, false, false, true]}; \
all-false consistent? {yabloCheck [false, false, false, false, false]} — \
finite lists have models; the infinite list (theorem `yablo`) has none"

/- ======================================================================
   8. THE GRELLING–NELSON PARADOX  (Grelling & Nelson, 1908 — linguistics)

   Story: call an adjective HETEROLOGICAL if it does not apply to itself:
   'long' is heterological (it is a short word), 'short' is not.  Is
   'heterological' heterological?  If yes, it applies to itself, so it is
   not; if no, it does not apply to itself, so it is.

   Formalized: for ANY type of words and ANY 'applies' relation, there is no
   word h with ∀ w, applies h w ↔ ¬ applies w w.  Instantiating w := h gives
   the liar biconditional.

   Resolution / lesson: this is Russell's paradox in linguistic clothing
   (applies ≈ membership, h ≈ the Russell set).  Since the proof works for
   every possible 'applies' relation, no semantics for adjectives can contain
   a genuinely heterological-defining word.
   ====================================================================== -/

theorem grelling (Word : Type) (applies : Word → Word → Prop) :
    ¬ ∃ h, ∀ w, applies h w ↔ ¬ applies w w :=
  fun ⟨h, hh⟩ => iff_not_self (hh h)

#eval s!"Grelling–Nelson: no word 'heterological' can exist for ANY applies-relation \
— Russell's paradox in linguistic clothing (theorem `grelling`)"

/- ======================================================================
   9. TARSKI'S UNDEFINABILITY OF TRUTH  (Alfred Tarski, 1933 — logic)

   Story: can a sufficiently rich language define a truth predicate for its
   own sentences?  Tarski: no.  The diagonal (fixed-point) lemma shows that
   for any predicate Tr definable in the language, there is a sentence L
   equivalent to the denial of its own truth: Tr L ↔ ¬ Tr L.

   Formalized (the semantic core): from any Tr : Sentence → Prop and any
   liar-like sentence L with Tr L ↔ ¬ Tr L, False follows.  The syntactic
   half — that diagonalization CONSTRUCTS such an L for every definable Tr —
   is arithmetization (Gödel numbering), not formalized here; this theorem is
   the punchline it feeds into.

   Resolution / lesson: truth for a language is undefinable inside that
   language; a truth predicate must live one level up, in a metalanguage.
   The object/meta distinction is precisely the firewall against the liar.
   ====================================================================== -/

theorem tarski (Sentence : Type) (Tr : Sentence → Prop) (L : Sentence)
    (hL : Tr L ↔ ¬ Tr L) : False :=
  iff_not_self hL

#eval s!"Tarski: any truth predicate admitting a diagonal sentence L with Tr L ↔ ¬Tr L \
is contradictory — truth is definable only in a metalanguage"

/- ======================================================================
   10. QUINE'S PARADOX  (W.V.O. Quine, 1962 — logic/syntax)   [NOTE]

   Story: the sentence
       "yields falsehood when preceded by its quotation"
       yields falsehood when preceded by its quotation.
   describes a string operation (prepend the quotation of a phrase to the
   phrase) and asserts that applying it to the quoted phrase yields a
   falsehood — but the result of that operation is the sentence itself.
   A liar with no indexical 'this sentence' at all.

   Why a NOTE: doing this honestly requires quotation/syntax machinery — a
   datatype of sentences, a quoting function, and a substitution operation,
   i.e. a mini diagonal lemma.  With that machinery the punchline is the
   fixed point Tr L ↔ ¬ Tr L already refuted in `tarski` and `liar`; without
   it there is nothing new to prove.  The #eval below at least performs
   Quine's string construction, showing the sentence reproduce itself.
   ====================================================================== -/

def quinePhrase : String := "yields falsehood when preceded by its quotation"

/-- Quine's construction: precede a phrase by its own quotation. -/
def precededByItsQuotation (p : String) : String := "\"" ++ p ++ "\" " ++ p

#eval s!"Quine's sentence, built by its own recipe: {precededByItsQuotation quinePhrase}"
#eval s!"Quine: the sentence asserts that this very construction yields a falsehood — \
its truth-value is the liar fixed point already refuted in `liar`/`tarski`"

/- ====================================================================== -/

def catalog : List (String × String) := [
  ("Liar (Eubulides)",
   "THEOREM: no proposition P with P ↔ ¬P (plus decide-checked Bool truth table: no b = !b)"),
  ("Epimenides",
   "THEOREM: not a paradox — hypotheses force ¬E and, classically, that some Cretan spoke truly"),
  ("Jourdain's card",
   "THEOREM: no P, Q with (P ↔ Q) ∧ (Q ↔ ¬P); two-sentence liar cycle (plus decide-checked Bool version)"),
  ("Pinocchio",
   "THEOREM: sentence-content S ↔ G plus fairy law G ↔ ¬S is contradictory — liar via physical truth-condition"),
  ("Crocodile dilemma",
   "THEOREM: promise (Return ↔ Correct) plus prediction (Correct ↔ ¬Return) is unsatisfiable"),
  ("Curry's paradox",
   "THEOREM: P ↔ (P → Q) entails Q for arbitrary Q, in minimal logic (plus decide-checked Bool shadow)"),
  ("Yablo's paradox",
   "THEOREM: no S : Nat → Prop with S n ↔ ∀ m > n, ¬S m (VERIFIED by decide: finite length-5 list IS satisfiable)"),
  ("Grelling–Nelson",
   "THEOREM: for every applies-relation, no word h with applies h w ↔ ¬ applies w w"),
  ("Tarski undefinability",
   "THEOREM: Tr L ↔ ¬Tr L is contradictory — the target the diagonal lemma (not formalized here) feeds, so truth is undefinable internally"),
  ("Quine's paradox",
   "NOTE: needs quotation/syntax machinery; fixed-point content identical to liar/Tarski — #eval performs the string construction")
]

end Paradoxes.SelfReference
