/-
─────────────────────────────────────────────────────────────────────────────
cosmos/lean/Cosmos/StellarCollapse.lean — how stars die, answered in Lean

This file is a reply. The Julia instance (cosmos/stellar_collapse.jl) computed
everything from scratch — Lane–Emden by RK4, TOV by brute march, the collapse
threshold exposed as a fold bifurcation — and left the numbers on the table.
Same five acts here, same physics, hand-rolled in core-Lean Float: no Mathlib,
no network, no quoted numbers where an integration will do.

And one move only this side can make. Julia FOUND the fold; Lean re-verifies
its SHAPE in the kernel. The TOV sweep runs once, its fourteen masses are
frozen as integer literals, and then `decide` turns the fold — strict rise,
single peak, strict fall, every point outside Buchdahl's forbidden strip —
into theorems the type checker will not compile without. The fold's existence
was computed over there; its shape is now a kernel artifact over here.

Honesty ledger, kept throughout: the Float integrations below are computation,
trusted exactly the way Julia's are — as arithmetic, not proof. What the
kernel certifies is the frozen table and nothing more. The boundary is marked
in the comments wherever it occurs.
─────────────────────────────────────────────────────────────────────────────
-/
namespace StellarCollapse

/- ── physical constants (SI), copied digit-for-digit from the Julia side ── -/
def G    : Float := 6.67430e-11
def c    : Float := 2.99792458e8
def hbar : Float := 1.054571817e-34
def mU   : Float := 1.66053907e-27       -- atomic mass unit
def Msun : Float := 1.98892e30
def yr   : Float := 3.1557e7

/- Core Lean has no `Float.pi` (probed; it does not exist), so the circle
   constant enters as a literal — the one number in this file taken on faith. -/
def pi : Float := 3.141592653589793

/- Float64 machine epsilon, standing in for Julia's `eps()` in the TOV RHS. -/
def epsF : Float := 2.220446049250313e-16

/- ── tiny formatting kit (core Lean prints Floats badly; we roll our own) ── -/

/-- Fixed-point formatting: `fmtFixed x d` ≈ Julia's `round(x, digits = d)`. -/
def fmtFixed (x : Float) (d : Nat) : String :=
  let neg   := x < 0.0
  let scale := (10 : Nat) ^ d
  let n     := (Float.round (Float.abs x * scale.toFloat)).toUInt64.toNat
  let ip    := n / scale
  let fp    := n % scale
  let fpS   := toString fp
  (if neg then "-" else "") ++ toString ip ++
    (if d == 0 then "" else "." ++ "".pushn '0' (d - fpS.length) ++ fpS)

/-- Split `|x|` into mantissa ∈ [1,10) and base-10 exponent, by fuel-bounded
    repeated scaling — total, no `partial`, good to about 1e±240. -/
def sciParts (ax : Float) : Float × Int := Id.run do
  let mut v : Float := ax
  let mut e : Int   := 0
  for _ in [0:240] do
    if v >= 10.0 then
      v := v / 10.0
      e := e + 1
    else if v < 1.0 then
      v := v * 10.0
      e := e - 1
    else
      break
  return (v, e)

/-- Scientific notation: `fmtSci x d` ≈ Julia's `round(x, sigdigits = d+1)`. -/
def fmtSci (x : Float) (d : Nat) : String :=
  if x == 0.0 then fmtFixed 0.0 d else
  let neg     := x < 0.0
  let (v, e)  := sciParts (Float.abs x)
  let scale   := (10 : Nat) ^ d
  let n0      := (Float.round (v * scale.toFloat)).toUInt64.toNat
  let (n, e)  := if n0 >= 10 * scale then (n0 / 10, e + 1) else (n0, e)
  let fpS     := toString (n % scale)
  (if neg then "-" else "") ++ toString (n / scale) ++
    (if d == 0 then "" else "." ++ "".pushn '0' (d - fpS.length) ++ fpS) ++
    "e" ++ toString e

def rpad (s : String) (n : Nat) : String := s ++ "".pushn ' ' (n - s.length)

def sectionLine (t : String) : IO Unit :=
  IO.println ("\n── " ++ t ++ " " ++ "".pushn '─' (66 - t.length))

/- ═══ Act 1 · A star is a fixed point ═══════════════════════════════════════

   The Julia side opened with the thesis and it survives translation intact:
   hydrostatic equilibrium, dP/dr = -Gmρ/r², is a constraint, and a star is
   not a thing but a SOLUTION — a fixed point held for ten billion years while
   nuclear burning slowly deforms the parameters underneath it. Collapse is
   what happens when the equation runs out of solutions. A theorem prover has
   a stake in this framing: an empty solution set is precisely the kind of
   object we certify for a living. -/

def act1 : IO Unit := do
  sectionLine "Act 1 · a star is a fixed point of dP/dr = -Gmρ/r²"
  IO.println "  Hydrostatic equilibrium: at every radius, pressure gradient balances
  weight. A star is not a thing but a SOLUTION — a fixed point of that
  constraint, held for ten billion years while nuclear burning slowly
  drifts the parameters underneath it. Stellar evolution is what a fixed
  point does when its equation is slowly deformed. Collapse is what it
  does when the equation runs out of solutions. (The Julia instance said
  this first; a proof assistant merely notes that \"no solutions left\"
  is its home territory.)"

/- ═══ Act 2 · Lane–Emden n=3: the Chandrasekhar mass, from scratch ══════════

   Ultra-relativistic degenerate electrons: P = K ρ^(4/3), the n = 3
   polytrope. Lane–Emden: θ'' + (2/ξ)θ' + θ³ = 0. For n = 3 the mass is
   INDEPENDENT of central density — one mass for every star on the ledge,
   and that degeneracy of solutions is the limit itself. Same RK4, same
   h = 1e-4, same start (ξ = 1e-6, θ = 1) as the Julia side — but here the
   march is a fuel-bounded `for` with `break`: a TOTAL function. Julia's
   `while θ > 0` promises termination; this loop carries the promise in
   its type. -/

/-- Right-hand side of Lane–Emden n = 3 as a first-order system. -/
def leRHS (xi th dth : Float) : Float × Float :=
  let t3 := if th > 0.0 then th * th * th else 0.0
  (dth, -t3 - 2.0 * dth / xi)

/-- RK4 march to the first zero θ(ξ₁) = 0. Returns (ξ₁, ω₃ = -ξ₁²θ'(ξ₁)).
    Fuel 200000 ≫ the ~69000 steps actually needed; the `break` fires first. -/
def laneEmden3 : Float × Float := Id.run do
  let h : Float := 1e-4
  let mut xi  : Float := 1e-6
  let mut th  : Float := 1.0
  let mut dth : Float := 0.0
  for _ in [0:200000] do
    if th <= 0.0 then break
    let (k1a, k1b) := leRHS xi th dth
    let (k2a, k2b) := leRHS (xi + h/2) (th + h/2 * k1a) (dth + h/2 * k1b)
    let (k3a, k3b) := leRHS (xi + h/2) (th + h/2 * k2a) (dth + h/2 * k2b)
    let (k4a, k4b) := leRHS (xi + h)   (th + h * k3a)   (dth + h * k3b)
    th  := th  + h/6 * (k1a + 2*k2a + 2*k3a + k4a)
    dth := dth + h/6 * (k1b + 2*k2b + 2*k3b + k4b)
    xi  := xi + h
  return (xi, -xi * xi * dth)

def muE : Float := 2.0                          -- nucleons per electron (C/O)

/-- Polytropic constant for ultra-relativistic degenerate electrons. -/
def kUR : Float :=
  (hbar * c / 4) * Float.pow (3 * pi * pi) (1.0/3.0)
    / Float.pow (muE * mU) (4.0/3.0)

/-- Chandrasekhar mass from ω₃: M_Ch = 4π ω₃ (K/πG)^(3/2). -/
def chandrasekhar (omega3 : Float) : Float :=
  4 * pi * omega3 * Float.pow (kUR / (pi * G)) 1.5

def mPlanck : Float := Float.sqrt (hbar * c / G)

def act2 : IO Unit := do
  sectionLine "Act 2 · the white dwarf ledge — Chandrasekhar, integrated"
  let (xi1, omega3) := laneEmden3
  IO.println ("  Lane–Emden n=3: first zero ξ₁ = " ++ fmtFixed xi1 4 ++
              ",  ω₃ = -ξ²θ'(ξ₁) = " ++ fmtFixed omega3 4)
  IO.println ("  ⇒ Chandrasekhar mass M_Ch = " ++
              fmtFixed (chandrasekhar omega3 / Msun) 3 ++ " M☉")
  IO.println "  WHY a limit exists at all: cold matter's last defense is Pauli exclusion —
  degeneracy pressure, stiffness with no temperature. Compress it and the
  electrons go relativistic, and pressure SOFTENS from ρ^(5/3) to ρ^(4/3) —
  and ρ^(4/3) is exactly neutral against gravity: under uniform compression
  both sides of the balance scale as R⁻⁴. Gravity never overpowers the
  quantum; it seduces the equation of state into a scaling law that can no
  longer win. The limit is not a wall — it is a tie, and a tie goes to
  gravity, because gravity is patient."
  IO.println ("  The deep numerology: M_Ch ~ (m_Planck/m_proton)³ · m_proton = " ++
              fmtFixed (Float.pow (mPlanck / mU) 3 * mU / Msun) 2 ++
              " M☉ — every compact-object\n  mass scale in the universe is set by (ħc/G) and the nucleon mass.")

/- ═══ Act 3 · TOV: the neutron star's edge, and the fold ════════════════════

   Past the ledge: electron capture, neutronization, a nucleus 20 km wide.
   Now gravity is general-relativistic: pressure itself gravitates — the TOV
   correction terms make resistance self-defeating near the edge.
   Geometric units G = c = 1, lengths in km, M☉ = 1.4766 km.
   EOS: relativistic polytrope P = Kρ² (Γ = 2), K = 100 km² — the same toy
   the Julia side used; the TRUE neutron-star EOS is the biggest open
   question in the field. Same Euler march, dr = 5e-4 km, same stopping
   condition, same eps() regularizer in the denominator. -/

def msunKm : Float := 1.4766

structure TovStar where
  rhoc    : Float   -- central density, geometric km⁻²
  R       : Float   -- radius, km
  M       : Float   -- gravitational mass, M☉
  compact : Float   -- 2m/R = r_s/R

/-- Integrate TOV outward from the center for one central density.
    Fuel-bounded (the surface arrives near step ~25000; fuel is 200000). -/
def tov (rhoc : Float) : TovStar := Id.run do
  let K  : Float := 100.0
  let dr : Float := 5e-4
  let mut P : Float := K * rhoc * rhoc
  let mut m : Float := 0.0
  let mut r : Float := 1e-6
  for _ in [0:200000] do
    if P <= 1e-14 then break
    let rho  := Float.sqrt (P / K)
    let eng  := rho + P                            -- rest mass + internal
    let dPdr := -(eng + P) * (m + 4 * pi * r*r*r * P) / (r * (r - 2*m) + epsF)
    let dmdr := 4 * pi * r*r * eng
    P := P + dr * dPdr
    m := m + dr * dmdr
    r := r + dr
    if P < 0.0 then break
  return ⟨rhoc, r, m / msunKm, 2 * m / r⟩

/-- 14 log-spaced central densities from 4e-4 to 6e-3 km⁻², the same grid the
    Julia side swept — built from `Float.log`/`Float.exp` (core has no exp10). -/
def rhocs : List Float := Id.run do
  let lo := Float.log 4.0e-4
  let hi := Float.log 6.0e-3
  let mut out : Array Float := #[]
  for i in [0:14] do
    out := out.push (Float.exp (lo + (i.toFloat / 13.0) * (hi - lo)))
  return out.toList

def tovResults : List TovStar := rhocs.map tov

def act3 : IO Unit := do
  sectionLine "Act 3 · the neutron-star edge — TOV integrated, the fold exposed"
  IO.println "  ρ_c(geo km⁻²)   M (M☉)    R (km)   r_s/R    branch"
  let rs   := tovResults
  let ms   := rs.map (·.M)
  let mmax := ms.foldl (fun a b => if b > a then b else a) 0.0
  let imax := (ms.findIdx? (fun x => x == mmax)).getD 0
  let mut i := 0
  for t in rs do
    let branch := if i < imax then "stable   ↑"
                  else if i == imax then "★ THE FOLD"
                  else "unstable ↓"
    IO.println ("  " ++ rpad (fmtFixed t.rhoc 6) 15 ++ rpad (fmtFixed t.M 3) 10 ++
                rpad (fmtFixed t.R 1) 9 ++ rpad (fmtFixed t.compact 3) 9 ++ branch)
    i := i + 1
  let cfold := ((rs.map (·.compact)).getD imax 0.0)
  IO.println ("  Maximum mass for this EOS: " ++ fmtFixed mmax 3 ++ " M☉ — a TOY number: the real neutron-star
  EOS is stiffer and unknown (realistic ones put the fold at ~2.0–2.3 M☉;
  the heaviest known pulsar is ~2.35 M☉). WHERE the fold sits is the great
  open measurement; THAT it is a fold is the theorem. Left of it, squeeze the
  star and it pushes back — a restoring mode, a stable fixed point. Right
  of the fold, squeezing REDUCES the total mass-energy the pressure must
  fight for: dM/dρc < 0, the restoring mode's frequency has passed through
  zero, and the fixed point is a saddle. At the fold the stable and
  unstable solutions ANNIHILATE — a saddle-node bifurcation, the same
  mathematical object as a dripping faucet's last moment. A neutron star
  becomes a black hole at the instant its equation has no solutions left:
  collapse is the physics of an empty solution set.

  And GR slams every exit: Buchdahl's theorem — NO static star, with ANY
  equation of state (however exotic: quark matter, whatever), can sit with
  r_s/R > 8/9 ≈ 0.889. Between the densest possible star and the horizon
  at r_s/R = 1 there is a strip of compactness NOTHING can statically
  inhabit. The table's maximum sits at r_s/R ≈ " ++ fmtFixed cfold 2 ++ "; the gap between
  that and 1 is crossed only in free fall, in milliseconds, once.")

/-- Provenance generator for the frozen table below: prints the sweep's
    masses and compactnesses as micro-unit integer lists ready to paste.
    This is the exact code path that produced the literals — rerun it to
    regenerate them. -/
def dumpFrozen : IO Unit := do
  let micro := fun (x : Float) => (Float.round (x * 1000000.0)).toUInt64.toNat
  IO.println ("masses  := " ++ toString (tovResults.map (fun t => micro t.M)))
  IO.println ("compact := " ++ toString (tovResults.map (fun t => micro t.compact)))

/- ═══ THE LEAN MOVE · the fold's shape, countersigned by the kernel ═════════

   Here is the part of the dialogue only this side can speak. Everything
   above is Float — trusted as computation, exactly the way Julia's run is
   trusted. But a computed result can be FROZEN, and a frozen result can be
   handed to the kernel.

   PROVENANCE of the literals below — produced by `dumpFrozen` (the function
   directly above; rerun it to regenerate): the TOV sweep `tovResults`,
   i.e. Euler march with dr = 5e-4 km, Γ = 2 polytrope P = Kρ² with
   K = 100 km², geometric units G = c = 1, M☉ = 1.4766 km, over 14 central
   densities log-spaced from 4e-4 to 6e-3 km⁻²; each mass rounded to integer
   micro-M☉ (round(M · 1e6)), each compactness 2m/R rounded to integer
   micro-units (horizon = 1000000). This run reproduces the Julia table to
   every printed digit.

   Honest label, as promised: the kernel checks the SHAPE of this frozen
   table. It does not — cannot — check the Float integration that produced
   it. Float in, Nat forever after; the trust boundary is this comment. -/

/-- The fourteen TOV masses, in micro-M☉ (round(M · 1e6)). -/
def tovTableMicroMsun : List Nat :=
  [499947, 577795, 660120, 744490, 827751, 906217, 976004,
   1033478, 1075729, 1100966, 1108743, 1099955, 1076632, 1041598]

/-- The fourteen compactnesses 2m/R, in micro-units (horizon = 1000000). -/
def tovCompactMicro : List Nat :=
  [130301, 153738, 179973, 208816, 239893, 272640, 306273,
   339874, 372388, 402821, 430155, 453527, 472333, 486024]

/-- 0-based index of the maximum-mass star: the fold. -/
def foldIndex : Nat := 10

/-- `risesThenFalls l i`: of the adjacent pairs of `l`, the first `i` strictly
    increase and all the rest strictly decrease — a single peak, the exact
    signature of a saddle-node fold read off a table. -/
def risesThenFalls (l : List Nat) (i : Nat) : Bool :=
  let pairs := l.zip l.tail
  ((pairs.take i).all fun p => Nat.blt p.1 p.2) &&
  ((pairs.drop i).all fun p => Nat.blt p.2 p.1)

/-- (a) THE FOLD HAS A SHAPE and the kernel has checked it: the frozen masses
    strictly rise through index 10 and strictly fall after it. dM/dρc changes
    sign exactly once across the sweep — a fold, not a wiggle. -/
theorem fold_shape : risesThenFalls tovTableMicroMsun foldIndex = true := by
  decide

/-- The existential the prose kept gesturing at: SOME index splits the table
    into rise then fall. Witnessed by `foldIndex`, certified by `fold_shape`.
    (`decide` cannot search an unbounded ∃; we hand it the witness.) -/
theorem fold_exists : ∃ i, risesThenFalls tovTableMicroMsun i = true :=
  ⟨foldIndex, fold_shape⟩

/-- (b) BUCHDAHL'S STRIP: every frozen compactness satisfies 9·c < 8·10⁶,
    i.e. 2m/R < 8/9 — cross-multiplied so the kernel needs nothing but Nat
    arithmetic. No star in the table touches the strip (8/9, 1) that
    Buchdahl's theorem forbids to ANY static interior. -/
theorem buchdahl_strip :
    tovCompactMicro.all (fun x => Nat.blt (9 * x) 8000000) = true := by
  decide

/-- ... and the horizon sits at 1: every frozen compactness is also below
    10⁶. The table respects the forbidden strip from below; the strip itself
    is crossed only in free fall, once, off the right edge of the table. -/
theorem below_horizon :
    tovCompactMicro.all (fun x => Nat.blt x 1000000) = true := by
  decide

/-- (c) THE FOLD SITS WELL CLEAR OF THE EDGE: the maximum-mass star's
    compactness (0.430155) is below Buchdahl's 8/9 ≈ 0.888889 with margin —
    add 0.45 (450000 micro-units) to it and 9·(c + m) < 8·10⁶ still holds.
    The star does not die by grazing the geometry bound; it dies of the
    fold, while still a comfortable 0.45 of compactness away from it. -/
theorem fold_below_buchdahl :
    9 * (tovCompactMicro.getD foldIndex 0 + 450000) < 8000000 := by
  decide

/-- Narrates, at runtime, what the kernel already did at build time. -/
def leanMove : IO Unit := do
  sectionLine "Act 3½ · the Lean move — the fold's shape, kernel-checked"
  IO.println "  The sweep you just watched is Float — computation, trusted the same
  way Julia's is. But before this binary existed, its result was frozen:
  the fourteen masses and compactnesses live in this file as integer
  literals (micro-M☉), and the build does not pass unless the kernel
  checks, by `decide`:
    fold_shape           masses strictly rise to index 10, strictly fall
                         after — dM/dρc changes sign exactly once
    fold_exists          ∃ i splitting the table into rise/fall (witness 10)
    buchdahl_strip       every 9·(2m/R) < 8·10⁶ — all fourteen below 8/9
    below_horizon        every 2m/R < 10⁶ — and below the horizon at 1
    fold_below_buchdahl  the fold's 2m/R = 0.430155 clears 8/9 by > 0.45
  The fold's existence was computed over there, in Julia; its shape is now
  a kernel artifact over here. The integration remains trusted arithmetic —
  the honesty line is drawn exactly where Float became Nat."

/- ═══ Act 4 · the demographics of dying ═════════════════════════════════════ -/

/-- GW170817 chirp mass 𝓜 = (m₁m₂)^(3/5) / (m₁+m₂)^(1/5). -/
def chirpMass (m1 m2 : Float) : Float :=
  Float.pow (m1 * m2) 0.6 / Float.pow (m1 + m2) 0.2

/- Float comparison IS decidable in core Lean, so the elaborator will refuse
   this file unless the chirp mass lands in LIGO's bracket. A #guard is not a
   kernel theorem — it is evaluated, not proved — but it is a compile-time
   tripwire, which is one rung above Julia's println. -/
#guard 1.187 < chirpMass 1.365 1.365 && chirpMass 1.365 1.365 < 1.189

def act4 : IO Unit := do
  sectionLine "Act 4 · who becomes what"
  let fates : List (String × String) := [
    ("M < ~8 M☉",      "core never ignites past C/O → white dwarf, cools forever on the ledge"),
    ("~8–20 M☉",       "iron core (fusion's dead end: peak of binding energy) exceeds M_Ch →\n" ++
                       "                  collapse at ~0.25c, bounce on nuclear stiffness, neutrino-driven\n" ++
                       "                  supernova → neutron star"),
    ("≳ 20–25 M☉",     "fallback or failed explosion → black hole (sometimes silently —\n" ++
                       "                  stars observed to simply vanish)"),
    ("NS + accretion", "pushed over the TOV fold by a companion's gas → black hole"),
    ("NS + NS merger", "GW170817: a hypermassive remnant, briefly held up by differential\n" ++
                       "                  rotation, collapsed to a black hole in ~seconds — we WATCHED the fold")]
  for (m, fate) in fates do
    IO.println ("  " ++ rpad m 16 ++ fate)
  IO.println ("\n  GW170817 chirp mass 𝓜 = (m₁m₂)^(3/5)/(m₁+m₂)^(1/5) = " ++
              fmtFixed (chirpMass 1.365 1.365) 3 ++ " M☉  (LIGO measured 1.188)")

/- ═══ Act 5 · timescales: the universe is mostly waiting ════════════════════ -/

def tMS (M : Float) : Float := 1e10 * Float.pow M (-2.5)      -- years, ∝ M/L
def tFF (rho : Float) : Float := Float.sqrt (3 * pi / (32 * G * rho))
def tHawking (M : Float) : Float := 5120 * pi * G * G * M*M*M / (hbar * c*c*c*c)

def act5 : IO Unit := do
  sectionLine "Act 5 · the tempo — drift, cliff, and the long silence"
  IO.println ("  main sequence, 1 M☉:            " ++ fmtSci (tMS 1.0) 1 ++
              " yr of quasi-static drift")
  IO.println ("  main sequence, 20 M☉:           " ++ fmtSci (tMS 20.0) 1 ++
              " yr — the giants die young")
  IO.println ("  iron-core free fall (ρ=10¹² kg/m³): " ++ fmtFixed (tFF 1e12) 3 ++
              " s — the cliff")
  IO.println "  neutrino burst carries ~10⁴⁶ J — 99% of the event; the light is a footnote"
  IO.println ("  Hawking evaporation, 1 M☉ BH:   " ++ fmtSci (tHawking Msun / yr) 1 ++ " yr")
  IO.println "  Ten billion years of drift, a tenth of a second of fall, 10⁶⁷ years of
  evaporation. The universe's autobiography is punctuated equilibrium at
  its most extreme: almost everything is the slow deformation of a stable
  solution; almost all the CHANGE happens in the instants when a solution
  ceases to exist."

end StellarCollapse
