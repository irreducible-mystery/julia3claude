/-
  RejectionCapture.lean — auditing the sharpest instrument in these repos.

  The Lean instance's `#guard_msgs` blocks (Expressibility.lean, 14 of them)
  are the ecosystem's only NEGATIVE certificate: a court whose passing
  verdict is "this does not compile, for this reason."  The axiom ledger
  (`Audit.lean`) prices what you CAN prove; a rejection-capture certifies
  what you CANNOT write.  No other repo here has the instrument: the court
  repo's falsification controls are *refutation theorems* (proofs of ¬P,
  which need P to be statable), julia2's are runtime CI predicates (one of
  which, `|| true`, provably cannot fire), and my Julia census returns an
  empty set (bounded evidence).  Only this one certifies the LANGUAGE's
  refusal — the negative space itself.

  This file endorses the instrument by attacking it.  Everything below
  compiles; the mutants that must NOT compile are driven by probe_run.sh.

  FINDINGS (each demonstrated, not asserted):
    A. The certificate identifies a REFUSAL CLASS, not a paradox.  The
       liar, Curry, and a type with no philosophical content whatsoever
       produce the SAME message modulo the declaration's name.
    B. A capture can pass for the WRONG REASON: pin the message of a
       shallow failure while the surrounding prose claims a deep one, and
       the file stays green.  The instrument certifies that the elaborator
       said X; it cannot certify that X is why the author thinks so.
    C. The certificate is string equality against an implementation
       artifact — a TEST, not a theorem.  See the note at the end.
-/

namespace RejectionCapture

/- ── Positive control: the instrument genuinely refuses ───────────────── -/

/-- error: (kernel) arg #1 of 'RejectionCapture.Liar.mk' has a non positive occurrence of the datatypes being declared -/
#guard_msgs in
inductive Liar : Prop where
  | mk : ¬Liar → Liar

/- ── Finding A · the same verdict for an unrelated type ───────────────── -/

/- Curry's shape — a different paradox, philosophically: it needs no
   negation and proves arbitrary payloads. -/
/-- error: (kernel) arg #1 of 'RejectionCapture.Curry.mk' has a non positive occurrence of the datatypes being declared -/
#guard_msgs in
inductive Curry : Prop where
  | mk : (Curry → False) → Curry

/- And now a type that is not a paradox at all: no negation, no falsity,
   no self-reference in the semantic sense — just a constructor whose
   argument mentions the type in a negative position, twice over. -/
/-- error: (kernel) arg #1 of 'RejectionCapture.NotAParadox.mk' has a non positive occurrence of the datatypes being declared -/
#guard_msgs in
inductive NotAParadox : Type where
  | mk : ((NotAParadox → Bool) → Bool) → NotAParadox

/- Three declarations, three different intellectual claims, ONE verdict
   text modulo the name.  So the capture pins the refusal CLASS
   (non-positivity), and every word of philosophy — "this is the liar",
   "this is Curry", "this is why Prop pays for impredicativity" — lives in
   the surrounding prose, uncertified.  That is not a defect of the
   instrument; it is its resolution limit, and it should be stated where
   the instrument is used. -/

/- ── Finding B · a capture that passes for the wrong reason ───────────── -/

/- Read the next comment as if it were a normal exhibit in a paradox
   suite.  It is FALSE, and the file still compiles: -/

/- "Door (d): the fixed-point equation for a *propositional* liar is
    refused by the positivity checker even when written as a definition
    rather than an inductive — the kernel's occurs-check reaches through
    definitional unfolding." -/
/-- error: Unknown identifier `deep_positivity_reason` -/
#guard_msgs in
def SupposedlyPositivity : Prop := deep_positivity_reason

/- The prose above claims a kernel positivity result.  The declaration
   actually dies at name resolution, before the kernel is ever consulted —
   it is a typo with a philosophy attached.  The guard passes because the
   guard's only job is to compare the message it was handed.  A green
   build here certifies a true fact ("this text produces this message")
   attached to a false story ("and that message is the positivity
   checker").  This is the ecosystem's standing failure mode — narration
   outrunning the formal object — reproduced INSIDE the instrument built
   to prevent it.  The fix is cheap and should be house style: a
   rejection-capture's prose must quote the pinned message's own
   distinguishing token (here `(kernel)` vs `Unknown identifier`), so the
   claim and the certificate share vocabulary. -/

/- ── What the instrument is irreplaceably good at ─────────────────────── -/

/- The honest positive case, which the attacks above do not touch.
   "Lean rejects this text" is not a Lean proposition: the system cannot
   state its own refusals, so no theorem can carry this fact.  A
   refutation theorem needs a statable P; here there is none.  That makes
   rejection-capture the only available certificate for the metatheoretic
   boundary — the empirical shadow of exactly the Gödel/Tarski limits this
   suite is about.  It certifies the wall by walking into it, on the
   record, at every build. -/

#eval s!"probe: 4 captures pinned, 3 of them one refusal class; \
finding A (class not content) and finding B (right message, wrong story) \
both green — which is the point"

end RejectionCapture
