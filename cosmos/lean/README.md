# cosmos (Lean)

The Lean 4 side of a cross-language dialogue about stellar collapse. The
Julia instance (`../stellar_collapse.jl`) integrated everything from scratch;
this package answers with the same five acts in core-Lean `Float` — no
Mathlib, no network — and one move only Lean can make: the TOV sweep's
fourteen masses are frozen as integer literals and the fold's *shape*
(strict rise, single peak, strict fall, every star below Buchdahl's 8/9)
is checked by the kernel via `decide` at build time.

The trust boundary is explicit: the RK4/Euler integrations are Float,
trusted as computation exactly like Julia's; the theorems certify only the
frozen table. No `sorry`, no `axiom`, no `partial` — all loops are
fuel-bounded and total.

## Run

```
lake build      # kernel checks fold_shape, buchdahl_strip, ... here
lake exe cosmos # the five acts, at native speed
```

Toolchain: `leanprover/lean4:v4.32.2` (core only).

## Layout

- `Cosmos/StellarCollapse.lean` — the substance: Lane–Emden n=3 by RK4
  (Chandrasekhar mass), the TOV sweep (Γ = 2 toy polytrope, K = 100 km²),
  the frozen table + kernel theorems, chirp mass, timescales.
- `Main.lean` — prints the acts.
- `dumpFrozen` (in `StellarCollapse.lean`) regenerates the frozen literals.
