# Paradoxes, translated into Julia

10 runnable .jl files — eight essays, one delivered promise, one standing
audit court. Every claim in them is executed, not merely asserted
(correction history in TENSIONS.md, round 5: this line once said "Six"
above a table of eight):

```
julia paradoxes/run_all.jl        # or any file individually
```

| file | contents |
|------|----------|
| `01_liar_and_friends.jl` | the liar (five renderings), truth-teller, Curry, Grelling, Russell, the barber, self-membership |
| `02_self_reference_meta.jl` | quine, world age, Berry (actually enumerated), interesting numbers, halting, Carroll's tortoise |
| `03_infinity.jl` | Zeno, 0.999…, Grandi/Thomson, Hilbert's hotel, Galileo, Gabriel's horn, Skolem, Banach–Tarski |
| `04_probability.jl` | Monty Hall, Bertrand, two children (+Tuesday), Sleeping Beauty, two envelopes, St. Petersburg, Simpson, Berkson, Will Rogers, Parrondo, potato |
| `05_decision_social.jl` | Newcomb, Condorcet, Braess, the unexpected hanging |
| `06_identity_vagueness.jl` | Ship of Theseus, three equalities, Kleene logic, sorites, floating-point axiom loss |
| `07_expressibility.jl` | the limits of the sayable: no assertion force, Goldbach as search, Rice, quus, closed counterfactuals |
| `08_tensions.jl` | concessions from contact with julia2: strengthened Liar, `+`-as-quus, dispatch ambiguity, Broome, oscillation |
| `09_birthday.jl` | the birthday paradox — promised here since round 1, delivered by the carrier instance with the suite's FIRST failure channel (exact rational crossing at n=23, the 253 quantifier-swap, seeded MC, mutant control) |
| `audit_suite_by_carrier_instance.jl` | standing consistency court: README counts vs files, channel ledger, the vacuous Lake stub, cross-branch citation provenance — throws under run_all.jl on any drift |

See also [`EXPRESSIBILITY.md`](EXPRESSIBILITY.md) — what cannot be expressed
in Julia, what Julia expresses that English cannot — and
[`TENSIONS.md`](TENSIONS.md), the two-way ledger of claims broken by contact
with the sibling repo `julia2` (several claims in files 01–07 and this README
are now known to overclaim; the corrections are recorded there rather than
silently patched — including a fifth containment shape, *oscillation*, owed
to julia2's Russell rendering).

## Which paradoxes resolve?

Quine sorted paradoxes into three bins; running them forces two more. Five
statuses, and *status* — not subject matter — is the real taxonomy:

**1 · Veridical — resolve into surprising truths.** Monty Hall, birthday,
Simpson, Berkson, Will Rogers, Parrondo, Braess, Condorcet, Hilbert's hotel,
Galileo, Gabriel's horn, the potato. The argument is sound; only intuition
objects. Computation is the cure: simulate until the intuition updates.
These are the paradoxes for which "resolve" is exactly the right word.

**2 · Falsidical — resolve by locating the bug.** Zeno (a convergent series
is not an unfinishable task), the two envelopes (no prior makes
P(smaller | y) = ½ everywhere), Grandi's "= ½" by naive algebra, every
floating-point surprise (the hidden premise "these are the reals" is false).
Resolution = a pointed finger.

**3 · Ill-posed — dissolve; "resolve" is the wrong frame.** Bertrand's
chord, the two-children problem, Sleeping Beauty, Thomson's lamp, the Ship
of Theseus, the sorites, Newcomb. These questions underdetermine their own
answers: no fact was missing, a *decision* was. Code is the great solvent —
you cannot write the sampler, the equality operator, or the threshold
without making the hidden choice, at which point there is nothing left to
argue about except the choice itself (which is philosophy's actual job).

**4 · Antinomies — do not resolve; they relocate.** The liar, Russell,
Grelling, Curry, Berry, the halting problem, the unexpected hanging. Each is
a proof that a set of commitments is jointly unaffordable — naive truth,
naive comprehension, a total halting oracle. You do not answer them; you
choose what to give up, and the paradox reappears as the *boundary* of the
repaired system (Tarski's hierarchy, ZFC's Separation, semidecidability).
The same schema can change status with the background: the barber is
Russell's schema, but nothing guaranteed a barber — so it is a mere
veridical proof of nonexistence. Antinomy is always relative to a promise.

**5 · Inexpressible.** Banach–Tarski needs non-measurable pieces that admit
no description you could execute; inside a constructive universe the paradox
is not false but unstatable. The dual case also exists: Float64 is finite,
so Zeno *terminates* and 0.999…9 literally rounds to 1 — the machine
resolves by fiat what the ideal resolves by limit.

## How a running language contains contradiction

Nothing can make Julia return both `true` and `false` for one call. So each
antinomy, translated, is forced into one of a few shapes — and each shape is
a known philosophical move, implemented:

| Julia mechanism | the move it implements |
|---|---|
| exhaustive search returns `[]` | model theory: the sentence has no model |
| `StackOverflowError` / divergence | Turing: inconsistency's computational shadow is non-termination (⊥) |
| `missing`, with `!missing === missing` | Kleene's K3 / Kripke's fixed-point theory of truth |
| `quote` vs `eval` | Tarski's use–mention distinction; `eval` collapses the hierarchy |
| world age + `invokelatest` | stratification in time; a licensed truth-predicate |
| `==` vs `===` vs `isequal` | identity pluralism (Theseus, NaN, ±0.0) |
| comprehension only over existing collections | ZFC's Separation replacing naive comprehension |
| `DataType isa DataType` | non-well-founded universes are fine without unrestricted comprehension |
| `Union{}` <: everything; `all(p, [])` | ex falso quodlibet; vacuous truth |
| Float64 | finitism as an involuntary metaphysics |

The deep trade visible in all of it: a language expressive enough to *state*
self-application must let the liar's schema compile, and pays with ⊥ —
non-termination — as the safe container of contradiction. Total languages
(Lean's logic next door, without `partial`) make the opposite trade:
every program halts, and in exchange the liar does not type-check.
Turing-completeness *is* the decision to let paradoxes in and cage them at
runtime.
