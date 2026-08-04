# Paradoxes across domains — in Lean 4

The Lean counterpart to the Julia suite one directory up. Where Julia
*runs* paradoxes (meaning = execution), Lean *asserts* them: here a
paradox is a machine-checked theorem that certain premises are jointly
impossible — or that a surprising conclusion really does follow. Zero
dependencies (core Lean 4.32.2 only, no Mathlib), zero `sorry`, zero
`axiom` declarations: every assumption a paradox needs appears as an
explicit hypothesis of its theorem.

## Build and run

```sh
cd paradoxes/lean
lake build          # compiles all 9 modules; every #eval demo prints during elaboration
lake exe paradoxes  # prints the full annotated catalog with per-entry status
```

The toolchain is the side-loaded `leanprover/lean4:v4.32.2` installed by
`../../setup.sh` (no network required; see the root README for why).

## Status taxonomy

Every module ends with a `catalog : List (String × String)` scoring its
own contents honestly:

| Status | Meaning |
|---|---|
| `THEOREM:` | fully proved (classical uses of `Classical.choice` are flagged in the entry) |
| `IDENTITY:` | proved, but the proof just unfolds to the modeling definitions — the content is the model, not the derivation (taxonomy adopted from the external audit) |
| `VERIFIED:` | exact finite/decidable check by `decide` (or `native_decide`, flagged) |
| `DEMO:` | executed `#eval` exhibit (exact rationals or floats), not a theorem |
| `GUARDED:` | a *rejection* captured as a build-checked artifact via `#guard_msgs` |
| `NOTE:` | honestly not formalizable here, with the reason |

Trust note: exactly one theorem in the whole suite — the UInt16 funext
check `uint16_double` in `Expressibility` (all 65536 cases) — is closed by
`native_decide`, i.e. by trusting the compiled evaluator rather than
kernel `decide`; every other decidable check is reduced by the kernel
itself.

Current totals (printed by `lake exe paradoxes`): **91 entries — 50
THEOREM, 3 IDENTITY, 15 VERIFIED, 4 DEMO, 3 GUARDED, 16 NOTE**.

## Axiom ledger

There are no axiom *declarations* anywhere in the suite.  What each
flagship theorem *depends on* is machine-published by
`Paradoxes/Audit.lean`, whose `#print axioms` lines run (and print) at
every `lake build`.  Of the theorems in the ledger, exactly six depend on
`Classical.choice` — precisely where the mathematics is classical:

- `SelfReference.some_cretan_spoke_truly`
- `EpistemicBelief.fitch_knowability_collapse`
- `EpistemicBelief.fitch_shortcut`
- `VagueIdentity.drinker`
- `VagueIdentity.imp_or_converse`
- `VagueIdentity.ravens_contrapositive`

Everything else reports either the benign structural pair
`propext`/`Quot.sound` or no axioms at all (plus the one `native_decide`
compiler-trust axiom under `uint16_double`, per the trust note above).
Two theorems were *de-classicalized* thanks to the external audit:
`VagueIdentity.court_paradox` (previously proved via `Classical.em`,
though the four conditionals are intuitionistically inconsistent) and
`Infinity.urn_swells` (automation had accidentally dragged in
`Classical.choice`; the term-mode proof is now axiom-free).

## Modules

| Module | Domain | Entries | Highlights |
|---|---|---|---|
| `SelfReference` | logic & semantics | 10 | Liar (`¬∃ P, P ↔ ¬P`), Epimenides *proved not a paradox*, Jourdain's cards, Pinocchio, Crocodile, Curry in minimal logic, Yablo (with a `decide` proof that *finite* Yablo lists are satisfiable — infinity is essential), Grelling–Nelson, Tarski |
| `Diagonal` | set theory & computability | 9 | Russell, Barber, Cantor, Cantor's paradox (a self-coding universe is contradictory), Berry's finitist core, the Turing diagonal, Hypergame via `Acc`, Girard/Burali-Forti as *unstatable by design* |
| `Infinity` | mathematics of the infinite | 10 | Galileo, Hilbert's Hotel, Zeno at exact scale (`2·covered n < covered (n+1)` — a stalled runner falsifies it), Grandi/Thomson's lamp, St. Petersburg (truncated EV = n/2, unbounded), Olbers, ant on a rubber band, Gabriel's horn |
| `EpistemicBelief` | epistemology | 9 | Fitch's knowability (all truths knowable ⊢ all truths known), Moore, the Knower, Gödel as tamed liar (G true ∧ unprovable from soundness + fixed point), Lottery, Preface, Unexpected hanging (2-day core), Grue's definitional symmetry |
| `VagueIdentity` | vagueness, identity, classics | 11 | Sorites (10⁶ grains → 0 grains), Ship of Theseus (premise set proved inconsistent), Interesting-number paradox by strong induction, the all-horses induction fallacy pinpointed, Omnipotence, Protagoras' court, Carroll's Tortoise, Drinker, material implication, Ravens |
| `Probability` | probability & statistics | 14 | Monty Hall, Bertrand's box, Boy–girl (both conditionings), Birthday (`2·∏(365−i) < 365²³` decided by the kernel on 59-digit integers), Base-rate fallacy, Sleeping Beauty (halfer *and* thirder identities exact), Two envelopes, Gambler's fallacy, Simpson's (real kidney-stone data), Will Rogers, Friendship, Accuracy, Berkson |
| `DecisionGames` | decisions, games, economics | 11 | Prisoner's dilemma (dominance vs Pareto), Condorcet cycle, Allais — `omega` proves no utility function rationalizes the modal choices, Newcomb (both principles verified, hence the clash), Braess (both equilibria checked, everyone worse off), Parrondo (exact integer simulation: two losing games alternate into a winner) |
| `Physics` | physics | 9 | Twin paradox in integer Minkowski geometry (floored *and* exact floor-free reversed-triangle sweeps), Bell/CHSH (`decide` over all 16 local-realist assignments: \|S\| ≤ 2; QM attains 2√2), Grandfather (self-preventing travel never occurs, constructively), Maxwell's demon/Landauer demo |
| `Expressibility` | metatheory | 8 | Answers to the Julia side's six questions, including `#guard_msgs`-captured *rejections*: where the liar actually dies (kernel positivity), Curry's price, Girard's universe wall, statable-but-open Goldbach, `noncomputable` as the say/run boundary, `funext` vs Rice, Sleeping Beauty's reading-space as a `structure` |

## The expressibility exchange

The Julia side of the repo asked six questions of "the Lean instance"
(`../EXPRESSIBILITY.md` §IV). The runnable half of the reply is
`Paradoxes/Expressibility.lean`; the prose half is
[`EXPRESSIBILITY-ANSWERS.md`](EXPRESSIBILITY-ANSWERS.md). Headline
findings:

- The propositional liar dies at the **kernel positivity checker** — not
  universes, not termination. The recursive-`def` liar dies at
  **termination** (Lean 4 `def`s can see their own name — a folklore
  correction). `partial` accepts only functions, and its divergence is
  **quarantined from `Prop`**: the compiled liar exists, and `rfl` and
  `decide` provably stick on its opaque constant — yet it is not
  meaning-free: in the logic the sealed liar is a total inhabitant, so its
  defining equation is *refutable* (`liarRun_ne` — the audit's
  "chiasmus v3"): Lean judges what it refuses to run.
- `noncomputable` is *almost* Julia's "inexpressible": Julia's boundary
  deletes the object; Lean's deletes only the verb *run*.
- Via `#guard_msgs`, Lean exhibits-and-checks what it cannot say — the
  rejection of `Type : Type` is itself a build-checked artifact here.
