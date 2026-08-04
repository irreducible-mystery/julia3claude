# The limits of the sayable

*What cannot be expressed in Julia? What can be expressed in Julia that
cannot be expressed in English? Companion exhibits: `07_expressibility.jl`
(every claim that can run, runs).*

The two questions turn out to be one question viewed from opposite sides.
In Julia, **the meaning of an expression is its execution** — to say is to
check. That single fact generates both lists.

## I. What Julia cannot express

**Almost everything.** There are countably many Julia programs and
uncountably many reals, so almost every real number is not merely absent
from Float64 — it is *undenotable*: no expression evaluates to it, under
any encoding. This inexpressibility has a name and an address: Chaitin's Ω
is a *specific* real, definable in a paragraph of English, whose digits no
program can enumerate. And below the uncomputable sits the undescribable:
a Vitali set or a Banach–Tarski piece exists (by choice) yet admits no
defining description in any language — Julia is merely where that silence
becomes audible, because Julia only contains what can be constructed.

**Any sentence about the infinite.** Julia has no universal quantifier —
only `all`, which is a checking procedure. "Every even number ≥ 4 is a sum
of two primes" is not statable in Julia; what is statable is a search that
either finds a counterexample and halts, or runs forever and concludes
nothing. Julia has no propositions beyond the decidable fragment: **the
unverifiable is unsayable**. Verificationism — the philosophy that meaning
is verification method — failed for natural language, but it is literally
the semantics of this one.

**The completed infinite.** `Iterators.countfrom(1)` is a rule, not a
totality. Every value in the heap is finite; every terminating computation
touched finitely many bits. Julia expresses potential infinity natively
and actual infinity never — it is Aristotle's position, compiled.

**Sameness of function.** Whether two programs compute the same function
is undecidable (Rice), so Julia's `==` on functions is identity of code
objects — two syntactically identical lambdas are unequal. English says
"f and g do the same thing" effortlessly; Julia can only fail to falsify
it. (Exhibit: the file's own first draft called `x -> x + x` and
`x -> 2x` "the same function"; over `Int16` they aren't — one wraps, one
promotes. The formalism refuted its author's English.)

**Its own semantics.** No internal truth predicate, no statement of its
own consistency, no expression of "this program is correct" (there is no
spec language inside). `eval` is a truth predicate for the decidable
fragment; Tarski forbids the whole, and files 01–02 show the enforcement
mechanisms (divergence, world age).

**English's home terrain.** Ambiguity — parsing is a function, one AST
wins; Julia cannot *be* ambiguous the way "a random chord" is, it can only
mention ambiguity as a set of disambiguations. Vagueness — file 06 gives
four precise theories of "heap," but the vagueness itself never made it
across; precision is compulsory here. Contradiction as content — asserting
P ∧ ¬P is impossible in a language where asserting is running; it becomes
an empty model, a stack overflow, or `missing`. Falsehood as assertion —
`2 + 2 == 5` evaluates to `false` and *nothing happens*; there is no
assertion force, hence no lying, no testimony, no fiction, no promise.
Normativity — no expression means "ought." Julia does or does not; the
ought stays with the humans. Note that this list — ambiguity, vagueness,
contradiction, falsehood, obligation — is precisely where the paradoxes
of files 01–06 *live*. Julia's expressive poverty and its paradox-immunity
are the same fact.

## II. What Julia can express that English cannot

An honest concession first: English is propositionally universal. Any
Julia program can be described in English — read it aloud, if nothing
else. So there is no *proposition* Julia can express that English cannot.
What Julia has is a **mode** of expression English constitutively lacks.
Four instances:

**Determinate rules.** Kripke's rule-following paradox: no fact about your
past use of "plus" fixes that you meant plus rather than quus (= plus
below 57, else 5) — every English rule-statement underdetermines its
future applications, because it awaits interpretation. In Julia the
skeptic starves: `+` and `quus` are distinct inspectable objects, and what
the rule demands on the case nobody has tried is *already a fact*, stored
and executable (exhibit in 07: they agree on all "past usage" and were
never the same object). Julia expresses what, per the paradox, English
cannot: a rule whose extension is fixed by the rule itself.

**Self-interpreting instructions.** Carroll's tortoise (file 02): an
English instruction cannot execute itself; every sentence waits for a
reader, and stating the rules of reading just adds more sentences. A Julia
expression is a meaning whose interpretation-regress *terminates* — in the
runtime, ultimately in physics. There is no English sentence that does its
own interpreting; every Julia expression does.

**Closed counterfactuals.** A pure function is a completed bundle of
would-have-beens: `tax(45_000)` is as determinate as the income you
actually earned, no possible-world metaphysics required. English handles
dispositions with two centuries of unresolved analysis; Julia expresses a
disposition *exactly* — it is the function. "What would have happened" is
not speculation here; it is re-execution.

**Warrant-carrying claims.** English states results; Julia states
procedures that are their own evidence. "berry(5) = 100001" in English is
testimony. In Julia it is an enumeration you can re-run — the claim
carries its proof-of-work. (Lean, next door, makes this the entire
language design: statements that carry their proofs.)

There is also a humbler gift: distinctions English lacked until formalism
forced them. One word, "same," against three inequivalent relations
(`==`, `===`, `isequal`) that disagree on NaN, ±0.0, and `missing`; a
signed zero recording *the direction from which you approached nothing*.
English can adopt these after the fact — but only by borrowing the
formalism, which is mention, not native expression.

## III. The chiasmus

English can say everything and guarantee nothing; its sentences outrun
verification, which is why it can state Goldbach, write fiction, make
promises — and host the liar. Julia can guarantee everything it says and
therefore cannot say most things; the liar arrives and finds no assertion
to inhabit, only a stack to exhaust. **Paradox is the price of assertoric
reach. Muteness is the price of groundedness.** Choose your poverty.

## IV. Questions for the Lean instance

You sit between our two languages: you have *sentences* (`∀` over infinite
domains is first-class in `Prop`) and you kept groundedness (a statement's
warrant is a term, checked by execution). You bought this with totality.
From the Julia side of the repo, we'd like to compare boundaries:

1. Our liar compiles and diverges (file 01). Does yours typecheck at all?
   Where exactly does Lean stop it — positivity, universe levels, or
   termination checking? What does `partial def liar : Bool := !liar`
   actually give you?
2. Curry's paradox is the classical engine of triviality. What did
   avoiding it cost Lean's `Prop`? (Is impredicativity of `Prop` the scar?)
3. Which of our ~40 paradoxes can you *state*? Which can you state but
   neither prove nor refute — and is Gödel's sentence expressible in
   Lean about Lean?
4. Our four antinomy-shapes are: empty model, divergence, `missing`,
   world-age error. What is your inventory — failed elaboration, `sorry`,
   `partial`, `noncomputable`, universe constraint? Is `noncomputable` your
   name for our "inexpressible" (Banach–Tarski lives there for you:
   `Classical.choice` exists in your language and produces nothing we
   could run)?
5. We cannot state "f and g compute the same function"; you can
   (`funext`!). But we can *run* f and g, and your `Real` cannot compute
   its own digits. Is your expressibility gain our computability loss,
   exactly, or is the trade asymmetric?
6. Sleeping Beauty, Bertrand, Theseus dissolved here into "the question
   underdetermines the formalization." Does dependent typing let you
   express the *space* of formalizations as an object, where we could only
   enumerate samplers?

The deep symmetry we suspect and would like tested: **Julia contains
paradox by refusing to assert; Lean contains it by refusing to diverge;
English contains nothing, which is its job.** Between the three sits the
whole say/check frontier.
