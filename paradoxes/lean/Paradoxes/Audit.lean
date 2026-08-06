import Paradoxes.SelfReference
import Paradoxes.Diagonal
import Paradoxes.Infinity
import Paradoxes.EpistemicBelief
import Paradoxes.VagueIdentity
import Paradoxes.Probability
import Paradoxes.DecisionGames
import Paradoxes.Physics
import Paradoxes.Expressibility

/-!
# Axiom ledger — kernel-published, at every build

Requested by the external audit: this module machine-publishes what each
flagship theorem of the suite actually depends on.  Every `#print axioms`
line below is executed by the compiler on every `lake build`, so the ledger
can never silently rot: if a proof change drags a new axiom into a theorem,
the build output changes with it.

How to read the output:

* **does not depend on any axioms** — the proof is checked by the kernel
  from the type theory alone.
* **`propext` / `Quot.sound`** — the two benign structural axioms of core
  Lean (propositional extensionality; soundness of quotient types).  Most
  `decide`/`omega`/`simp` automation leaves at least `propext` behind.
* **`Classical.choice`** — genuinely classical reasoning (excluded middle,
  `byContradiction`, choice).  In this suite it appears exactly where the
  mathematics is classical: Fitch's collapse, the drinker paradox, the
  material-implication split, and the classical direction of Hempel's
  contrapositive.  Two former members of this club — `court_paradox` and
  `urn_swells` — were de-classicalized after the audit showed their
  classicality was an accident of proof style, not of content.
* **`…_native.native_decide.ax_1_1`** — the per-theorem compiler-trust
  axiom minted by `native_decide` (it stands on `Lean.ofReduceBool` /
  `Lean.trustCompiler`: trusting the compiled evaluator, not just the
  kernel).  Exactly one theorem in the suite uses it (`uint16_double`,
  65536 cases), and its line below shows the extra trust in plain sight —
  that is the point of publishing the ledger.
-/

/-! ## Self-reference and semantics -/

#print axioms Paradoxes.SelfReference.liar
#print axioms Paradoxes.SelfReference.curry
#print axioms Paradoxes.SelfReference.yablo
#print axioms Paradoxes.SelfReference.some_cretan_spoke_truly

/-! ## Diagonalization -/

#print axioms Paradoxes.Diagonal.cantor
#print axioms Paradoxes.Diagonal.hypergame

/-! ## The infinite -/

#print axioms Paradoxes.Infinity.urn_swells

/-! ## Knowledge and belief -/

#print axioms Paradoxes.EpistemicBelief.fitch_knowability_collapse
#print axioms Paradoxes.EpistemicBelief.fitch_shortcut

/-! ## Vagueness, identity, and the classics -/

#print axioms Paradoxes.VagueIdentity.court_paradox
#print axioms Paradoxes.VagueIdentity.drinker
#print axioms Paradoxes.VagueIdentity.imp_or_converse
#print axioms Paradoxes.VagueIdentity.ravens_contrapositive

/-! ## Probability and statistics -/

#print axioms Paradoxes.Probability.monty_hall
#print axioms Paradoxes.Probability.base_rate_fallacy
#print axioms Paradoxes.Probability.sleeping_beauty_thirder
#print axioms Paradoxes.Probability.simpsons_paradox

/-! ## Decisions, games, and economics -/

#print axioms Paradoxes.DecisionGames.prisoners_dilemma
#print axioms Paradoxes.DecisionGames.allais_no_expected_utility
#print axioms Paradoxes.DecisionGames.newcomb_ev_favors_one_boxing
#print axioms Paradoxes.DecisionGames.braess_old_split_destabilized

/-! ## Physics -/

#print axioms Paradoxes.Physics.traveler_younger
#print axioms Paradoxes.Physics.chsh_bound
#print axioms Paradoxes.Physics.grandfather

/-! ## Expressibility -/

#print axioms Paradoxes.Expressibility.liarRun_ne
#print axioms Paradoxes.Expressibility.uint16_double
