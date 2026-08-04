# ─────────────────────────────────────────────────────────────────────────────
# cosmos/stellar_collapse.jl — how stars die, computed from scratch
#
# Everything below is stdlib Julia + hand-rolled RK4. No quoted numbers where
# an integration will do: the Chandrasekhar mass comes out of the Lane–Emden
# equation, the neutron-star maximum mass out of the Tolman–Oppenheimer–
# Volkoff equations, and the collapse threshold appears as what it really is —
# a fold bifurcation, the annihilation of the star's fixed point.
# ─────────────────────────────────────────────────────────────────────────────
module StellarCollapse

section(t) = println("\n── ", t, " ", "─"^max(0, 66 - length(t)))

# physical constants (SI)
const G  = 6.67430e-11
const c  = 2.99792458e8
const ħ  = 1.054571817e-34
const mᵤ = 1.66053907e-27          # atomic mass unit
const M☉ = 1.98892e30
const yr = 3.1557e7

# ═══ Act 1 · A star is a fixed point ═════════════════════════════════════════
section("Act 1 · a star is a fixed point of dP/dr = -Gmρ/r²")
println("""
  Hydrostatic equilibrium: at every radius, pressure gradient balances
  weight. A star is not a thing but a SOLUTION — a fixed point of that
  constraint, held for ten billion years while nuclear burning slowly
  drifts the parameters underneath it. Stellar evolution is what a fixed
  point does when its equation is slowly deformed. Collapse is what it
  does when the equation runs out of solutions.""")

# ═══ Act 2 · Lane–Emden n=3: the Chandrasekhar mass, from scratch ════════════
section("Act 2 · the white dwarf ledge — Chandrasekhar, integrated")
# Ultra-relativistic degenerate electrons: P = K ρ^(4/3), the n=3 polytrope.
# Lane–Emden: θ'' + (2/ξ)θ' + θ³ = 0.  For n=3 the mass is INDEPENDENT of
# central density — one mass for every star on the ledge. That degeneracy of
# solutions is the limit itself.
function lane_emden3(; h = 1e-4)
    ξ, θ, dθ = 1e-6, 1.0, 0.0
    f(ξ, θ, dθ) = (dθ, -(max(θ, 0.0))^3 - 2dθ / ξ)
    while θ > 0
        k1 = f(ξ, θ, dθ)
        k2 = f(ξ + h/2, θ + h/2*k1[1], dθ + h/2*k1[2])
        k3 = f(ξ + h/2, θ + h/2*k2[1], dθ + h/2*k2[2])
        k4 = f(ξ + h,   θ + h*k3[1],  dθ + h*k3[2])
        θ  += h/6 * (k1[1] + 2k2[1] + 2k3[1] + k4[1])
        dθ += h/6 * (k1[2] + 2k2[2] + 2k3[2] + k4[2])
        ξ  += h
    end
    ξ, -ξ^2 * dθ
end
ξ₁, ω₃ = lane_emden3()
μₑ = 2.0                                        # nucleons per electron (C/O)
K  = (ħ * c / 4) * (3π^2)^(1/3) / (μₑ * mᵤ)^(4/3)
M_ch = 4π * ω₃ * (K / (π * G))^(3/2)
println("  Lane–Emden n=3: first zero ξ₁ = ", round(ξ₁, digits = 4),
        ",  ω₃ = -ξ²θ'(ξ₁) = ", round(ω₃, digits = 4))
println("  ⇒ Chandrasekhar mass M_Ch = ", round(M_ch / M☉, digits = 3), " M☉")
println("""
  WHY a limit exists at all: cold matter's last defense is Pauli exclusion —
  degeneracy pressure, stiffness with no temperature. Compress it and the
  electrons go relativistic, and pressure SOFTENS from ρ^(5/3) to ρ^(4/3) —
  and ρ^(4/3) is exactly neutral against gravity: under uniform compression
  both sides of the balance scale as R⁻⁴. Gravity never overpowers the
  quantum; it seduces the equation of state into a scaling law that can no
  longer win. The limit is not a wall — it is a tie, and a tie goes to
  gravity, because gravity is patient.""")

# the number of the ledge: a pure ratio of constants
m_planck = sqrt(ħ * c / G)
println("  The deep numerology: M_Ch ~ (m_Planck/m_proton)³ · m_proton = ",
        round((m_planck / mᵤ)^3 * mᵤ / M☉, digits = 2), " M☉ — every compact-",
        "object\n  mass scale in the universe is set by (ħc/G) and the nucleon mass.")

# ═══ Act 3 · TOV: the neutron star's edge, and the fold ══════════════════════
section("Act 3 · the neutron-star edge — TOV integrated, the fold exposed")
# Past the ledge: electron capture, neutronization, a nucleus 20 km wide.
# Now gravity is general-relativistic: pressure itself gravitates — the TOV
# correction terms make resistance self-defeating near the edge.
# Geometric units G = c = 1, lengths in km, M☉ = 1.4766 km.
# EOS: relativistic polytrope P = Kρ² (Γ = 2), K = 100 km² — a standard toy
# EOS; the TRUE neutron-star EOS is the biggest open question in the field.
const Msun_km = 1.4766
function tov(ρc; K = 100.0, dr = 5e-4)
    P, m, r = K * ρc^2, 0.0, 1e-6
    while P > 1e-14
        ρ = sqrt(P / K); ε = ρ + P                        # rest mass + internal
        dPdr = -(ε + P) * (m + 4π * r^3 * P) / (r * (r - 2m) + eps())
        dmdr = 4π * r^2 * ε
        P += dr * dPdr; m += dr * dmdr; r += dr
        P < 0 && break
    end
    (R = r, M = m / Msun_km, compact = 2m / r)            # compact = r_s/R
end
println("  ρ_c(geo km⁻²)   M (M☉)    R (km)   r_s/R    branch")
ρcs = exp10.(range(log10(4e-4), log10(6e-3); length = 14))
results = [tov(ρc) for ρc in ρcs]
Mmax, imax = findmax([t.M for t in results])
for (i, (ρc, t)) in enumerate(zip(ρcs, results))
    println("  ", rpad(round(ρc, sigdigits = 3), 15), rpad(round(t.M, digits = 3), 10),
            rpad(round(t.R, digits = 1), 9), rpad(round(t.compact, digits = 3), 9),
            i < imax ? "stable   ↑" : i == imax ? "★ THE FOLD" : "unstable ↓")
end
println("""
  Maximum mass for this EOS: $(round(Mmax, digits = 3)) M☉ — a TOY number: the real neutron-star
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
  inhabit. The table's maximum sits at r_s/R ≈ $(round(results[imax].compact, digits = 2)); the gap between
  that and 1 is crossed only in free fall, in milliseconds, once.""")

# ═══ Act 4 · the demographics of dying ═══════════════════════════════════════
section("Act 4 · who becomes what")
for (m, fate) in [("M < ~8 M☉",      "core never ignites past C/O → white dwarf, cools forever on the ledge"),
                  ("~8–20 M☉",       "iron core (fusion's dead end: peak of binding energy) exceeds M_Ch →\n" *
                   " "^18 * "collapse at ~0.25c, bounce on nuclear stiffness, neutrino-driven\n" *
                   " "^18 * "supernova → neutron star"),
                  ("≳ 20–25 M☉",     "fallback or failed explosion → black hole (sometimes silently —\n" *
                   " "^18 * "stars observed to simply vanish)"),
                  ("NS + accretion", "pushed over the TOV fold by a companion's gas → black hole"),
                  ("NS + NS merger", "GW170817: a hypermassive remnant, briefly held up by differential\n" *
                   " "^18 * "rotation, collapsed to a black hole in ~seconds — we WATCHED the fold")]
    println("  ", rpad(m, 16), fate)
end
m1 = m2 = 1.365
println("\n  GW170817 chirp mass 𝓜 = (m₁m₂)^(3/5)/(m₁+m₂)^(1/5) = ",
        round((m1 * m2)^0.6 / (m1 + m2)^0.2, digits = 3),
        " M☉  (LIGO measured 1.188)")

# ═══ Act 5 · timescales: the universe is mostly waiting ══════════════════════
section("Act 5 · the tempo — drift, cliff, and the long silence")
t_ms(M) = 1e10 * M^(-2.5)                                 # main-sequence years, ∝ M/L
t_ff(ρ) = sqrt(3π / (32 * G * ρ))                         # free-fall, ρ in kg/m³
t_hawking(M) = 5120π * G^2 * M^3 / (ħ * c^4)              # evaporation, seconds
println("  main sequence, 1 M☉:            ", round(t_ms(1.0), sigdigits = 2), " yr of quasi-static drift")
println("  main sequence, 20 M☉:           ", round(t_ms(20.0), sigdigits = 2), " yr — the giants die young")
println("  iron-core free fall (ρ=10¹² kg/m³): ", round(t_ff(1e12), digits = 3), " s — the cliff")
println("  neutrino burst carries ~10⁴⁶ J — 99% of the event; the light is a footnote")
using Printf
@printf("  Hawking evaporation, 1 M☉ BH:   %.1e yr\n", t_hawking(M☉) / yr)
println("""
  Ten billion years of drift, a tenth of a second of fall, 10⁶⁷ years of
  evaporation. The universe's autobiography is punctuated equilibrium at
  its most extreme: almost everything is the slow deformation of a stable
  solution; almost all the CHANGE happens in the instants when a solution
  ceases to exist.""")

end # module
