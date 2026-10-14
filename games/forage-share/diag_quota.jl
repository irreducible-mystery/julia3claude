#!/usr/bin/env julia
#
# diag_quota.jl — diagnose the Run 1 P1/P2/P7 failures.
#
# Hypothesis: the naive MSY quota (7.5/player, total 22.5) is only
# sustainable in the discrete harvest-then-regrow map from a pre-harvest
# stock R >= 172.5. The map R_{t+1} = (R_t - H) + 0.3*(R_t - H)*(1 - (R_t-H)/300)
# has its sustainable fixed point at post-harvest stock x = 150, i.e.
# pre-harvest R* = 172.5 — and x = 150 is a DOUBLE root of
# 0.3*x*(1 - x/300) = 22.5, i.e. a knife-edge: any R < 172.5 drifts down.
#
# Checks:
#   D1: Fair^3 from R_init = 200 (> 172.5) sustains (no collapse).
#   D2: Fair^3 with quota 6.5 (total 19.5 < 22.5) from R_init = 150 sustains.
#   D3: Fair^3 with quota 7.5 from R_init = 150 collapses (reproduces Run 1).
#
# Usage:
#   julia diag_quota.jl

include("forage_share.jl")

using Printf

function check(label, R_init, quota)
    r = play_match(fresh_strats(Strategy[Fair(), Fair(), Fair()]), label;
                   R_init = R_init, quota = quota)
    @printf("%-42s collapse@%4d  welfare %9.1f  minR %7.1f\n",
            label, r.collapse_round, r.welfare, r.min_R)
    return r
end

println("D3 (reproduce Run 1): Fair^3, R_init=150, quota=7.5")
d3 = check("D3", 150.0, 7.5)
println("D1 (above fixed point): Fair^3, R_init=200, quota=7.5")
d1 = check("D1", 200.0, 7.5)
println("D2 (safer quota): Fair^3, R_init=150, quota=6.5")
d2 = check("D2", 150.0, 6.5)

ok = (d3.collapse_round > 0) && (d1.collapse_round == 0) && (d2.collapse_round == 0)
println()
println(ok ? "Diagnosis CONFIRMED: collapse is the quota/stock knife-edge, not a code bug. Exit 0."
           : "Diagnosis NOT confirmed. Exit 1.")
exit(ok ? 0 : 1)
