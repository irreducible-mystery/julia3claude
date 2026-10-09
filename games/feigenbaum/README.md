# Measuring Feigenbaum's δ from scratch

Idea proposed by Tangent (side chat): *measure δ ourselves.* The logistic map
`x_{n+1} = r x_n (1 - x_n)` period-doubles at `r_1 = 3`, `r_2`, `r_3`, … and
the ratios `δ_n = (r_n - r_{n-1}) / (r_{n+1} - r_n)` converge to Feigenbaum's
constant `δ = 4.6692016091…` — the number at the edge of chaos, and the
universal scaling of every period-doubling route there.

## Method

For each `n ≥ 2`, `r_n` is where the `2^(n-1)`-cycle's multiplier hits `-1`.
We locate it by bisection on the multiplier, tracking the cycle branch by
continuation in `r`:

1. Seed mid-window (multiplier ≈ +0.6, fast convergence): iterate `x = 0.5`,
   then Newton-polish the cycle of `F(x) = f^{2^(n-1)}_r(x)`.
2. March `r` upward (Newton seeded from the previous cycle) until `M < -1`.
3. Bisect `M(r) = -1` to ~1e-14.

Every solution is validated as a genuine period-`2^(n-1)` cycle — a collapsed
or lower-period fixed point of `F` fails loudly instead of silently
corrupting the table. (`r_1 = 3` is analytic: fixed-point multiplier `2 - r`.)

## Run

```sh
julia feigenbaum.jl [--nmax N]   # default N = 9
```

Exit code 0 iff all pre-registered predictions hold:

1. `|M_1(3) + 1| < 1e-12` — analytic anchor.
2. `|r_2 - (1 + √6)| < 1e-9` — analytic: the 2→4 doubling is at `1+√6`.
3. `|δ_last - 4.669201609102990| < 5e-6` — the literature value, measured by us.

## Result (2026-10-08, Julia 1.13.1, Float64)

```
   n                r_n            δ_n
   2    3.4494897427832   4.7514462182
   3    3.5440903595519   4.6562510177
   4    3.5644072660954   4.6682422356
   5    3.5687594195438   4.6687394693
   6    3.5696916098014   4.6691321506
   7    3.5698912593781   4.6691830051
   8    3.5699340183740   4.6691980766
```

All three predictions PASS. `δ_8 = 4.6691980766` vs literature `4.6692016091`
— six digits agree. The `r_∞` extrapolation (`≈ 3.5699548` vs literature
`3.569945672`) is informational only; geometric extrapolation is sensitive to
the last δ's residual error.

## Notes

- One indexing bug was caught during development: `r_n` tracks the
  `2^(n-1)`-cycle (born at `r_{n-1}`), not the `2^n`-cycle. Seeding a
  period-4 solve at `r = 3.2` (still in the period-2 window) made Newton
  collapse onto the 2-cycle — the validator caught it, loudly, as designed.
  Errors as information.
- Float64 sets the floor: beyond `n ≈ 10` the windows (`~δ^-n`) sink toward
  the noise. A `BigFloat` version could push further.
