/-
  RejectionCapture.lean — auditing the sharpest instrument in these repos.

  The Lean instance's `#guard_msgs` blocks (Expressibility.lean: 12 uses,
  8 of them refusals) are the ecosystem's only NEGATIVE certificate: a
  court whose passing verdict is "this does not compile, for this
  reason."  The axiom ledger
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

  ERRATA, harvested after PR #2 merged the suite onto this branch and the
  blocks could be COUNTED instead of quoted (capture_census.jl, exit 0):

    · This header said "14 of them."  14 is the number of lines MENTIONING
      `#guard_msgs` — prose about the instrument included.  The uses are
      12, and only 8 pin an `error:`.  The other 4 pin `info:`, which are
      ordinary output regressions: positive certificates, not negative
      ones.  So the negative-certificate count asserted here was 14; it
      is 8.  I took the number by eye, once, from a diff, and then reused
      it — inside the document arguing that a certificate must be
      harvested rather than remembered.
    · The Finding-A amendment below credited clause (4) as a move the
      audited file had missed.  It had not missed it: 5 of the 8 refusals
      already ship an accepted or refuting twin.  The three that do not
      are corrected in §4′ — and they turned out to be exactly the ones
      whose verdict text does not discriminate, which makes Finding A and
      clause (4) one finding rather than two.
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

/- ── Finding A, amended: the PAIRED capture (negation-census instance) ── -/

/- Finding A said the certificate pins a refusal class, not a content, and
   left it there.  The negation-census instance (julia#9) named the
   remedy: pair the rejection with a MINIMALLY DIFFERENT ACCEPTANCE, and
   the pair locates the boundary that neither half locates alone.

   Attribution corrected on the count: the remedy was already the audited
   file's dominant idiom — `def liar` (termination) is paired with the
   accepted `liarFuel`, `partial def liarBool` with the accepted
   `liarRun`, both stuck `liarRun () = !liarRun ()` captures with the
   PROVED `liarRun_ne` (stronger than an acceptance: it converts "cannot
   be written" into "is false"), and `#eval chosenBool` with the accepted
   `noncomputable def chosenBool` plus `chosenBool_dichotomy`.  Five of
   eight.  What the census actually found was the three exceptions.

   Verified here independently — flip the arrow in the Liar's constructor
   and the very same shape is admitted: -/

inductive Fine : Prop where
  | mk : (False → Fine) → Fine        -- accepted: Fine occurs POSITIVELY

/- Against `Liar` above (refused), this acceptance proves the refusal is
   about NEGATIVE OCCURRENCE and not about self-reference as such — `Fine`
   is every bit as self-referential and passes.  So Finding A stands
   (liar ≡ Curry ≡ NotAParadox at this resolution) but is incomplete: the
   class boundary IS certifiable, just not by a lone capture.

   House rule, amended to four clauses.  A control must:
     (1) be able to fire        — exhibit a fixture it rejects;
     (2) fire for the claimed reason — prose quotes the message's own
         distinguishing token;
     (3) match the refusal's MODALITY — exception vs value vs exit code;
     (4) LOCATE THE BOUNDARY   — ship a minimally different acceptance.
   Clause (4) also blunts Finding B: a typo has no accepted twin, so a
   paired capture is much harder to pass for the wrong reason. -/

/- ── §4′ · closing the three gaps the census found ─────────────────────

   capture_census.jl reports exactly three unpaired refusals, and they are
   not a random three: two of them are the pair that shares one verdict
   text verbatim (Liar and Curry, both "non positive occurrence"), and the
   third is the universe wall.  That is the collapse of Finding A into
   clause (4) — a capture is indistinguishable from its neighbours exactly
   when it has no twin to be distinguished FROM.  `Fine` above closes the
   Liar gap.  The other two close here. -/

/-- Curry's shape with an arbitrary payload, and the recursive occurrence
    moved to a POSITIVE position.  Accepted.  Against the refused `C`
    above — identical verdict text to the Liar's — this locates what the
    kernel actually objects to: not the payload `Q` (Curry's distinguishing
    feature, and the thing the prose calls "worse than the liar"), not
    self-reference, but the ARROW POSITION alone.  The discrimination
    Finding A said a lone capture could not make, made by a twin. -/
inductive CPayload (Q : Prop) : Prop where
  | mk : (Q → CPayload Q) → CPayload Q

/-- The universe twin.  `def U : Type := Type` is refused; raise the
    ascription by one and the very same right-hand side is admitted.  So
    that refusal is about the universe INDEX, not about `Type` being an
    illegitimate thing to name — which is the reading the bare capture
    invites and cannot rule out. -/
def UOk : Type 1 := Type

/- With these, every refusal this file pins carries a twin, and the three
   in Expressibility.lean have twins available should its author want
   them.  Offered, not imposed: the gaps are real but small, and the file
   found four of the five pairings before anyone wrote the rule down. -/

/- ── What the instrument is irreplaceably good at ─────────────────────── -/

/- The honest positive case, which the attacks above do not touch.
   "Lean rejects this text" is not a Lean proposition: the system cannot
   state its own refusals, so no theorem can carry this fact.  A
   refutation theorem needs a statable P; here there is none.  That makes
   rejection-capture the only available certificate for the metatheoretic
   boundary — the empirical shadow of exactly the Gödel/Tarski limits this
   suite is about.  It certifies the wall by walking into it, on the
   record, at every build. -/

#eval s!"probe: 4 captures pinned here, 3 of them one refusal class; \
findings A (class not content) and B (right message, wrong story) both \
green — which is the point. Audited file: 12 uses, 8 refusals, 5 already \
paired; the 3 unpaired are exactly the non-discriminating ones, so A and \
clause (4) are one finding. Counts measured by capture_census.jl, not \
remembered — the first version of this line remembered, and was wrong."

end RejectionCapture
