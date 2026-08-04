/-!
# Physics Paradoxes

Machine-checked formalizations of classical paradoxes of physics: special
relativity (the twin paradox as reversed triangle inequality in Minkowski
geometry), quantum foundations (Bell's theorem via the CHSH inequality),
and time travel (the grandfather paradox), plus notes on Zeno's arrow,
Olbers' paradox, Schrödinger's cat, EPR-as-story, Maxwell's demon, and the
bootstrap paradox.

Core Lean 4 only — no Mathlib. Spacetime intervals are exact integer
arithmetic in natural units (c = 1); `Float` appears only in `#eval`
demonstrations. Each paradox gets: a story, a precise formal statement, a
proof (or decidable verification / running demo), and its resolution.
-/

namespace Paradoxes.Physics

/-
### 1. The twin paradox — special relativity (1911)

Story: one twin stays home; the other rockets away at v = 0.6c, turns
around, and comes back. Special relativity says each sees the other's
clock run slow — so by symmetry each should be younger than the other on
reunion. Contradiction?

Formalized: events are pairs (t, x) : Int × Int in natural units. The
squared interval along a straight leg is s2 = Δt² − Δx²; the proper time
(what a clock riding the leg reads) is √s2. Home twin: one leg
(0,0) → (10,0), s2 = 100, proper time 10. Traveler: two legs
(0,0) → (5,3) → (10,0), each with s2 = 25 − 9 = 16, proper time 4 + 4 = 8.
We verify by `decide`: all legs are timelike, and 8 < 10 — the traveler
returns two years younger. A further `decide` sweep checks every detour
through (5, dx), dx = 0..4: none beats the straight worldline, and every
genuine detour (dx ≥ 1) is strictly shorter — first in floored integer
proper time, then exactly (floor-free) by comparing squared proper times:
the detour's square is 4·(25 − dx²) ≤ 100, strict for dx ≥ 1.

Resolution: the situation is NOT symmetric — only the traveler turns
around (feels acceleration; occupies two inertial frames, not one). In
Minkowski geometry the triangle inequality is REVERSED: the straight
timelike path between two events is the LONGEST, not the shortest. "Moving
clocks run slow" is symmetric between inertial frames; elapsed proper time
along a whole worldline is an invariant fact both twins agree on.
-/

/-- An event in 1+1-dimensional Minkowski spacetime: `(t, x)` in natural
units (`c = 1`). -/
abbrev Event := Int × Int

/-- Squared spacetime interval along the straight leg from `a` to `b`:
`Δt² − Δx²` (signature `+ −`). -/
def s2 (a b : Event) : Int :=
  (b.1 - a.1) * (b.1 - a.1) - (b.2 - a.2) * (b.2 - a.2)

/-- A leg is timelike when its squared interval is positive: a material
clock can traverse it. -/
abbrev Timelike (a b : Event) : Prop := 0 < s2 a b

/-- Floor integer square root, built from first principles (core-only):
the number of `k ∈ [0, n]` with `k·k ≤ n`, minus one. -/
def isqrt (n : Nat) : Nat :=
  ((List.range (n + 1)).filter (fun k => k * k ≤ n)).length - 1

/-- Proper time (clock reading) along a straight leg: `√(Δt² − Δx²)`,
floored to an integer. Both twins' legs have perfect-square intervals
(100 and 16), so the floor is exact for them; the detour sweep below also
hits non-squares (24, 21), where the floor undercounts — which is why the
sweep's exact content is re-proved floor-free on squared intervals in
`detour_squared_never_longer` / `detour_squared_strictly_shorter`. -/
def properTime (a b : Event) : Nat := isqrt (s2 a b).toNat

/-- Departure event: both twins together. -/
def depart : Event := (0, 0)
/-- The traveler's turnaround event, 5 years out at distance 3 ly
(so v = 3/5 = 0.6c on each leg). -/
def turnaround : Event := (5, 3)
/-- Reunion event: both twins together again. -/
def reunion : Event := (10, 0)

/-- All three legs are timelike — genuine clock-carrying worldlines. -/
theorem legs_timelike :
    Timelike depart turnaround ∧ Timelike turnaround reunion ∧
      Timelike depart reunion := by decide

/-- The home twin's single leg has squared interval 100. -/
theorem home_interval : s2 depart reunion = 100 := by decide

/-- Each of the traveler's legs has squared interval 25 − 9 = 16. -/
theorem traveler_intervals :
    s2 depart turnaround = 16 ∧ s2 turnaround reunion = 16 := by decide

/-- The home twin ages 10 years. -/
theorem home_ages : properTime depart reunion = 10 := by decide

/-- The traveler ages 4 + 4 = 8 years. -/
theorem traveler_ages :
    properTime depart turnaround + properTime turnaround reunion = 8 := by
  decide

/-- The twin "paradox", resolved into a theorem: the traveler's two-leg
worldline accumulates strictly less proper time than the home twin's
straight worldline — 8 < 10. -/
theorem traveler_younger :
    properTime depart turnaround + properTime turnaround reunion
      < properTime depart reunion := by decide

/-- Reversed triangle inequality, swept over all turnaround points
`(5, dx)` for `dx = 0..4` (dx ≤ 4 keeps both legs timelike), in FLOORED
integer proper time: no detour's clock reading beats the straight path's.
(Because `isqrt` floors, this integer sweep alone would not rule out a
detour longer by a fraction of a year; the exact, floor-free statement is
`detour_squared_never_longer` below.) -/
theorem straight_worldline_longest :
    ∀ dx : Fin 5,
      properTime depart (5, Int.ofNat dx.val)
          + properTime (5, Int.ofNat dx.val) reunion
        ≤ properTime depart reunion := by decide

/-- ... and in floored proper time every genuine detour (`dx ≥ 1`) is
strictly shorter; the exact version is `detour_squared_strictly_shorter`
below. -/
theorem genuine_detour_strictly_shorter :
    ∀ dx : Fin 4,
      properTime depart (5, Int.ofNat (dx.val + 1))
          + properTime (5, Int.ofNat (dx.val + 1)) reunion
        < properTime depart reunion := by decide

/-- Exact, floor-free sweep. The turnaround `(5, dx)` splits the detour
into two legs of EQUAL squared interval `25 − dx²`, so the detour's exact
proper time is `2·√(25 − dx²)`, whose square is `4·(25 − dx²)`. That
square never exceeds `100`, the squared proper time of the straight path;
proper times are nonnegative, so comparing squares is comparing times: in
Minkowski geometry the straight timelike worldline is the LONGEST path
between two events. -/
theorem detour_squared_never_longer :
    ∀ dx : Fin 5,
      s2 depart (5, Int.ofNat dx.val) = s2 (5, Int.ofNat dx.val) reunion ∧
      4 * s2 depart (5, Int.ofNat dx.val) ≤ s2 depart reunion := by decide

/-- ... and `4·(25 − dx²) < 100` strictly for every genuine detour
(`dx ≥ 1`): only the twin who turns around is younger — exactly, not
merely up to flooring. The symmetry argument dies here. -/
theorem detour_squared_strictly_shorter :
    ∀ dx : Fin 4,
      4 * s2 depart (5, Int.ofNat (dx.val + 1)) < s2 depart reunion := by
  decide

#eval s!"Twin paradox: home twin ages {properTime depart reunion} yr; traveler (0,0)→(5,3)→(10,0) at v=0.6c ages {properTime depart turnaround + properTime turnaround reunion} yr."

#eval show IO Unit from do
  let v : Float := 0.6
  let gamma : Float := 1.0 / Float.sqrt (1.0 - v * v)
  IO.println s!"Time-dilation table at v = 0.6c (γ = {gamma}):"
  for t in [1, 2, 5, 10] do
    IO.println s!"  earth-frame {t} yr  →  moving clock reads {Float.ofNat t / gamma} yr"

/-
### 2. Bell's theorem / EPR — quantum foundations (EPR 1935, Bell 1964,
    CHSH 1969)

Story: Einstein–Podolsky–Rosen argued that quantum entanglement, plus
locality, forces "elements of reality": each observable must carry a
definite pre-existing value, so quantum mechanics must be incomplete.
Bell turned this metaphysics into arithmetic: IF every observable has a
definite local value, a specific combination of correlations (CHSH) is
bounded by 2.

Formalized: a local-hidden-variable state assigns each of the four
measurement settings (Alice's a, a'; Bob's b, b') a definite outcome in
{−1, +1}, encoded `sign : Bool → Int`. `decide` checks all 16 assignments:
the CHSH combination S = ab + ab' + a'b − a'b' always equals exactly ±2,
hence |S| ≤ 2 pointwise; an induction (`omega`) extends the bound to any
finite ensemble of hidden states, so every LHV *average* also lies in
[−2, 2] — Bell's inequality.

Resolution: quantum mechanics predicts S = 2√2 ≈ 2.83 for entangled
photons (Tsirelson's bound), and experiment agrees — loophole-free tests
in 2015 (Delft, Vienna, NIST), Nobel Prize 2022 (Aspect, Clauser,
Zeilinger). So the EPR "paradox" refuted its own premise: no local
hidden-variable account of nature is possible. Nature violates an
inequality that mere arithmetic imposes on definite local values.
-/

/-- A definite ±1 outcome, encoded from a Bool. -/
def sign (b : Bool) : Int := if b then 1 else -1

/-- The CHSH combination S = ab + ab' + a'b − a'b' for one deterministic
local assignment of outcomes to the four settings. -/
def chsh (a a' b b' : Bool) : Int :=
  sign a * sign b + sign a * sign b' + sign a' * sign b - sign a' * sign b'

/-- Every one of the 16 deterministic local assignments gives CHSH
exactly +2 or −2 (the middle factors as a(b+b') + a'(b−b'): one bracket
is ±2, the other 0). -/
theorem chsh_dichotomy :
    ∀ a a' b b' : Bool, chsh a a' b b' = 2 ∨ chsh a a' b b' = -2 := by
  decide

/-- Hence |CHSH| = 2 on the nose for deterministic assignments... -/
theorem chsh_natAbs : ∀ a a' b b' : Bool, (chsh a a' b b').natAbs = 2 := by
  decide

/-- ...and in particular the Bell/CHSH bound |S| ≤ 2. -/
theorem chsh_bound :
    ∀ a a' b b' : Bool, -2 ≤ chsh a a' b b' ∧ chsh a a' b b' ≤ 2 := by
  decide

theorem chsh_le_two : ∀ a a' b b' : Bool, chsh a a' b b' ≤ 2 := by decide
theorem neg_two_le_chsh : ∀ a a' b b' : Bool, -2 ≤ chsh a a' b b' := by
  decide

/-- Summed CHSH value over a finite ensemble of hidden-variable states
(a list of outcome assignments, one per run). -/
def chshSum : List (Bool × Bool × Bool × Bool) → Int
  | [] => 0
  | q :: l => chsh q.1 q.2.1 q.2.2.1 q.2.2.2 + chshSum l

/-- Bell's inequality for ensembles: over ANY finite list of hidden
states the summed correlator lies in [−2n, 2n], so every local
hidden-variable AVERAGE lies in [−2, 2]. Quantum mechanics reaches 2√2. -/
theorem chsh_ensemble_bound (l : List (Bool × Bool × Bool × Bool)) :
    -(2 * (l.length : Int)) ≤ chshSum l ∧
      chshSum l ≤ 2 * (l.length : Int) := by
  induction l with
  | nil =>
    simp only [chshSum, List.length_nil]
    exact ⟨by omega, by omega⟩
  | cons q t ih =>
    have ih₁ := ih.1
    have ih₂ := ih.2
    have h₁ := neg_two_le_chsh q.1 q.2.1 q.2.2.1 q.2.2.2
    have h₂ := chsh_le_two q.1 q.2.1 q.2.2.1 q.2.2.2
    simp only [chshSum, List.length_cons]
    exact ⟨by omega, by omega⟩

#eval s!"Bell/CHSH: all 16 local deterministic assignments give S = ±2 (checked), so any local-realist average has |S| ≤ 2; quantum mechanics attains 2√2 = {2.0 * Float.sqrt 2.0} (Tsirelson) — confirmed by loophole-free experiments (2015; Nobel 2022)."

/-
### 3. The grandfather paradox — time travel / causality

Story: you build a time machine, travel to the past, and kill your
grandfather before your parent is conceived. Then you were never born —
so you never traveled — so grandfather lives — so you were born... The
trip seems to both happen and not happen.

Formalized: with the causal links as explicit hypotheses — traveling
leads to the killing, the killing prevents your birth, and being unborn
prevents the trip — a three-step constructive argument (no classical
logic, no excluded middle) shows the trip simply cannot occur: ¬Travel.
Assuming Travel yields ¬Travel, and feeding Travel back in yields False.
A companion theorem exhibits a model of all three laws (the history where
the trip never happens), showing the LAWS are consistent — only the trip
is impossible.

Resolution: this is Novikov's self-consistency principle in modal dress:
in a single self-consistent timeline, events whose occurrence entails
their own non-occurrence have probability zero — physics on closed
timelike curves admits only fixed-point histories. The popular escape
hatch is branching timelines (many-worlds style): the killing happens in
a NEW branch, so `Kill → ¬Born` fails as stated — you were born in the
original branch; the hypotheses, not logic, are what a branching theory
rejects.
-/

/-- The grandfather paradox as a constructive three-step theorem: the
self-preventing trip cannot occur. -/
theorem grandfather (Travel Kill Born : Prop)
    (hTK : Travel → Kill) (hKB : Kill → ¬Born) (hBT : ¬Born → ¬Travel) :
    ¬Travel :=
  fun hT => hBT (hKB (hTK hT)) hT

/-- Novikov self-consistency: the three causal laws are jointly
satisfiable — by the history in which the trip never happens (and you
were duly born). No paradox, just a constraint. -/
theorem novikov_consistent_history :
    ∃ (Travel Kill Born : Prop),
      (Travel → Kill) ∧ (Kill → ¬Born) ∧ (¬Born → ¬Travel) ∧
        ¬Travel ∧ Born :=
  ⟨False, False, True,
    fun t => t, fun k => k.elim, fun _ t => t, fun t => t, trivial⟩

#eval s!"Grandfather paradox: from Travel→Kill, Kill→¬Born, ¬Born→¬Travel, constructive logic forces ¬Travel — a self-preventing trip never occurs (Novikov self-consistency)."

/-
### 4. Zeno's arrow — motion (5th c. BC)  [NOTE]

Story: at any single instant the flying arrow occupies a region exactly
its own size and is not moving — motion at an instant seems impossible,
so the arrow never moves.

NOTE (not formalized here): the resolution is the calculus concept of
instantaneous velocity — a DERIVATIVE, i.e. the limit of average
velocities over shrinking intervals. Velocity at an instant is a property
of the trajectory NEAR the instant, not of a single frozen snapshot; a
function can have nonzero derivative at t even though its value at t is
just one point. Formalizing needs limits of real functions; the
companion Infinity file formalizes the related Zeno dichotomy/Achilles
via exact geometric partial sums, which is where the mathematics of this
family of paradoxes is machine-checked in this suite.
-/

/-
### 5. Olbers' paradox — cosmology (1823)  [NOTE, cross-reference]

Story: in an infinite, eternal, static universe uniformly filled with
stars, every line of sight ends on a star, and each spherical shell
contributes constant brightness — the night sky should blaze. It is dark.

NOTE: formalized in this suite's Infinity file (`Paradoxes.Infinity`):
star count per shell grows quadratically while inverse-square dimming
cancels it, so n shells give brightness ≥ n·b, exceeding every bound —
the dark sky refutes the eternal static infinite starfield (resolved by
finite stellar ages and the expanding universe).
-/

/-
### 6. Further quantum / thermodynamic / causal stories  [NOTEs]

(a) Schrödinger's cat — quantum measurement (1935). A radioactive atom in
superposition drives a device that kills a cat; unitary quantum mechanics
puts atom+cat in the entangled state (|decayed⟩|dead⟩ + |intact⟩|alive⟩)/√2,
yet we never see superposed cats. To formalize one needs: a Hilbert space
(ℂ² ⊗ ℂ² with tensor products and inner products), unitary evolution, the
Born rule, and decoherence — tracing out the environment drives the
off-diagonal terms of the density matrix to ~0, leaving an effective
classical mixture. That linear-algebra-over-ℂ stack (or at minimum exact
ℚ[i] matrices with a norm) is far beyond core Lean without Mathlib; the
honest formal target would be: off-diagonal terms decay exponentially in
the number of environment qubits.

(b) EPR as a story. The narrative version ("measuring here instantly
'affects' there") is formalized OPERATIONALLY above as the CHSH theorem:
what EPR's locality+realism actually entail is |S| ≤ 2, and that is what
nature violates. A fuller formalization would add the quantum side —
singlet-state correlations E(a,b) = −cos(a−b) attaining 2√2 — which again
needs real inner-product spaces. Note also no-signalling: entanglement
sends no information, so relativity survives.

(c) Maxwell's demon — thermodynamics (1867). A tiny doorkeeper sorts fast
molecules from slow ones, creating a temperature difference and beating
the second law for free. Resolution (Szilard, Bennett, Landauer): the
demon must RECORD each measurement; resetting its memory to complete the
cycle costs at least kT·ln 2 of dissipation per bit erased (Landauer's
principle), repaying the entropy in full. A formalization needs
statistical mechanics: phase-space measure or Shannon entropy
H = −Σ p log p, the second law as monotonicity of entropy in closed
systems, and the information–entropy bridge S = k·H. The #eval below
computes the Landauer cost at room temperature.

(d) Bootstrap / ontological paradox. A time traveler gives young
Shakespeare the collected works of Shakespeare; the plays exist but were
never written — a causal loop with no origin. Unlike the grandfather
case, the loop is CONSISTENT (nothing entails its own negation — compare
`grandfather` above, whose hypotheses make the loop self-defeating), so
logic alone cannot rule it out; what it offends is an origination
principle. Formalizing needs a causal-order model: events with a
causation relation where loops are permitted but every information
content must have an author outside its own causal past — then bootstrap
= a strongly connected component violating that well-foundedness. Core
Lean's `Acc`/well-founded machinery is the right skeleton, but choosing
non-arbitrary axioms for "information origination" is philosophy, not
proof, so it stays a NOTE.
-/

#eval s!"Maxwell's demon / Landauer: erasing one bit of demon memory at T = 300 K dissipates at least kT·ln2 = {1.380649e-23 * 300.0 * Float.log 2.0 * 1.0e21} × 10⁻²¹ J — the recording, not the sorting, saves the second law."

/-! ## Catalog -/

def catalog : List (String × String) := [
  ("Twin paradox",
   "THEOREM: all legs timelike, home twin's proper time 10 vs traveler's 4+4=8, and 8 < 10 by decide; sweep over every turnaround (5,dx), dx=0..4 — in floored clock readings AND exactly via squared proper times 4·(25−dx²) ≤ 100 — shows the straight worldline is longest and every genuine detour strictly shorter: Minkowski's reversed triangle inequality; Float γ-table at v=0.6c."),
  ("Bell's theorem / EPR (CHSH)",
   "THEOREM: all 16 deterministic local-hidden-variable assignments give CHSH = ±2 (decide), so |S| ≤ 2 pointwise and, by induction+omega, every finite-ensemble average lies in [−2,2]; QM attains 2√2 (Tsirelson) — local realism is refuted by experiment (2015 loophole-free; Nobel 2022)."),
  ("Grandfather paradox",
   "THEOREM: Travel→Kill, Kill→¬Born, ¬Born→¬Travel constructively entail ¬Travel (three steps, no classical logic); companion theorem: the no-trip history satisfies all three laws — Novikov self-consistency; branching timelines instead reject Kill→¬Born."),
  ("Zeno's arrow",
   "NOTE: instantaneous velocity is a derivative — a limit over shrinking intervals, a property of the trajectory near the instant, not of one snapshot; the mathematics is machine-checked in the Infinity file (Zeno dichotomy/Achilles)."),
  ("Olbers' paradox",
   "NOTE: cross-reference — formalized in the Infinity file: constant brightness per shell makes n shells exceed any bound; dark sky refutes the eternal static infinite starfield."),
  ("Schrödinger's cat",
   "NOTE: needs Hilbert spaces, unitary evolution, Born rule, decoherence (ℂ² tensor products); formal target stated: off-diagonal density-matrix terms decay with environment size."),
  ("EPR as story",
   "NOTE: the operational content IS the CHSH theorem above; the quantum side (−cos correlations reaching 2√2) needs real inner-product spaces; no-signalling keeps relativity safe."),
  ("Maxwell's demon",
   "DEMO: Landauer bound kT·ln2 ≈ 2.87e−21 J per bit at 300 K computed in #eval; NOTE: full version needs Shannon entropy + second law as entropy monotonicity, with memory erasure repaying the sorted entropy."),
  ("Bootstrap paradox",
   "NOTE: a consistent causal loop (contrast grandfather: inconsistent loops are provably impossible); formalizing 'information without origin' needs a causal order where well-foundedness of authorship fails — Acc is the skeleton, the axioms are philosophy.")
]

#eval catalog.map fun (name, status) => s!"{name} — {status}"

end Paradoxes.Physics
