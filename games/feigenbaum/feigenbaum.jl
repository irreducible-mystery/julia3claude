#!/usr/bin/env julia
#
# feigenbaum.jl — measure Feigenbaum's δ from scratch.
#
# Idea proposed by Tangent (side chat): "measure δ ourselves." Iterate the
# logistic map x_{n+1} = r x_n (1 - x_n) through its period-doubling cascade,
# locate each bifurcation r_n — where the 2^(n-1)-cycle's multiplier hits -1 —
# by bisection on the multiplier with continuation in r, and watch
#     δ_n = (r_n - r_{n-1}) / (r_{n+1} - r_n)  →  δ = 4.6692016091…
#
# Method, per n ≥ 2:
#   1. Seed mid-window (multiplier ≈ +0.6, fast convergence): iterate x = 0.5,
#      then Newton-polish the 2^(n-1) cycle of F(x) = f^{2^(n-1)}_r(x).
#   2. March r upward by continuation (Newton seeded from the previous cycle)
#      until the multiplier crosses -1.
#   3. Bisect M(r) = -1 to ~1e-14.
# r_1 = 3 is analytic (fixed-point multiplier 2 - r).
#
# Every solution is validated as a genuine period-2^n cycle (not a collapsed
# or lower-period fixed point of F), so a wrong branch fails loudly.
#
# Pre-registered predictions (exit 0 iff all hold):
#   1. |M_1(3) + 1| < 1e-12              (analytic anchor)
#   2. |r_2 - (1 + √6)| < 1e-9           (analytic: the 2→4 doubling)
#   3. |δ_last - 4.669201609102990| < 5e-6  (literature value)
#
# Usage: julia feigenbaum.jl [--nmax N]   (default N = 9)

using Printf

f(x, r)  = r * x * (1 - x)
fp(x, r) = r * (1 - 2x)

# Newton-polish a period-p cycle from seed; returns (points, multiplier).
function polish_cycle(seed::Float64, r::Float64, p::Int)
    x = seed
    for _ in 1:100
        y, d = x, 1.0
        for _ in 1:p
            d = fp(y, r) * d
            y = f(y, r)
        end
        g, gp = y - x, d - 1.0
        abs(gp) < 1e-300 && break
        dx = g / gp
        x -= dx
        abs(dx) < 1e-15 && break
    end
    xs = Vector{Float64}(undef, p)
    m = 1.0
    y = x
    for i in 1:p
        xs[i] = y
        m *= fp(y, r)
        y = f(y, r)
    end
    return xs, m
end

# Strict: polish + verify genuine period 2^(n-1) (not collapsed, not lower period).
function solve_branch(r::Float64, seed::Float64, n::Int)
    p = 2^(n - 1)
    xs, m = polish_cycle(seed, r, p)
    mind = minimum(abs(xs[i] - xs[j]) for i in 1:p for j in i+1:p)
    mind > 1e-7 || error("collapsed cycle at r=$r")
    y = xs[1]
    for _ in 1:2^(n-2)
        y = f(y, r)
    end
    abs(y - xs[1]) > 1e-7 || error("lower-period cycle at r=$r")
    return xs, m
end

# Non-throwing wrapper for the march.
function try_branch(r::Float64, seed::Float64, n::Int)
    try
        return solve_branch(r, seed, n)
    catch
        return nothing
    end
end

function find_rn(n::Int, r_prev::Float64, r_prevprev::Float64)
    # r_n: the 2^(n-1)-cycle (born at r_{n-1}) loses stability, M = -1.
    p = 2^(n - 1)
    West = n == 2 ? (sqrt(6) - 2) : (r_prev - r_prevprev) / 4.6692
    r_seed = n == 2 ? 3.2 : r_prev + West / 5
    x = 0.5
    for _ in 1:50000
        x = f(x, r_seed)
    end
    xs_lo, m_lo = solve_branch(r_seed, x, n)
    m_lo > -1 || error("seed not in attracting window (M=$m_lo)")
    r_lo = r_seed
    # march upward until the multiplier crosses -1
    step = West / 50
    r_hi = NaN
    xs_hi = Float64[]
    while true
        r_try = r_lo + step
        res = try_branch(r_try, xs_lo[1], n)
        if res === nothing
            step /= 2
            step < 1e-15 && error("march stalled at n=$n")
            continue
        end
        xs_try, m_try = res
        if m_try < -1
            r_hi, xs_hi = r_try, xs_try
            break
        end
        r_lo, xs_lo, m_lo = r_try, xs_try, m_try
        step = min(step * 1.5, West / 5)
        step > 1.0 && error("march escaped window at n=$n")
    end
    # bisect M(r) = -1
    for _ in 1:100
        r_mid = (r_lo + r_hi) / 2
        seed = abs(r_mid - r_lo) < abs(r_mid - r_hi) ? xs_lo[1] : xs_hi[1]
        xs_mid, m_mid = solve_branch(r_mid, seed, n)
        if m_mid > -1
            r_lo, xs_lo = r_mid, xs_mid
        else
            r_hi, xs_hi = r_mid, xs_mid
        end
        r_hi - r_lo < 2e-14 && break
    end
    return (r_lo + r_hi) / 2
end

function main()
    nmax = 9
    i = 1
    while i <= length(ARGS)
        if ARGS[i] == "--nmax" && i < length(ARGS)
            nmax = parse(Int, ARGS[i+1])
            i += 2
        else
            i += 1
        end
    end
    nmax >= 4 || error("need --nmax >= 4")

    rs = Dict{Int,Float64}(1 => 3.0)
    for n in 2:nmax
        rs[n] = find_rn(n, rs[n-1], n >= 3 ? rs[n-2] : 0.0)
    end

    println("bifurcation points:")
    for n in 1:nmax
        @printf("  r_%d = %.13f\n", n, rs[n])
    end
    println()
    @printf("%4s %18s %14s\n", "n", "r_n", "δ_n")
    deltas = Float64[]
    for n in 2:nmax-1
        d = (rs[n] - rs[n-1]) / (rs[n+1] - rs[n])
        push!(deltas, d)
        @printf("%4d %18.13f %14.10f\n", n, rs[n], d)
    end

    δ = deltas[end]
    rinf = rs[nmax] + (rs[nmax] - rs[nmax-1]) / (1 - 1 / δ)
    @printf("\nr_∞ ≈ %.12f  (literature 3.569945672…)\n", rinf)

    println("\n--- pre-registered predictions ---")
    ok = true
    m1 = fp(1 - 1 / 3, 3.0)
    c1 = abs(m1 + 1) < 1e-12
    println((c1 ? "PASS " : "FAIL ") * "M_1(3) = -1  [analytic anchor]")
    ok &= c1
    c2 = abs(rs[2] - (1 + sqrt(6))) < 1e-9
    @printf("%s r_2 = 1+√6  [got %.13f]\n", c2 ? "PASS " : "FAIL ", rs[2])
    ok &= c2
    δlit = 4.669201609102990
    c3 = abs(δ - δlit) < 5e-6
    @printf("%s δ_%d ≈ 4.6692016091  [got %.10f]\n", c3 ? "PASS " : "FAIL ",
            nmax - 1, δ)
    ok &= c3
    exit(ok ? 0 : 1)
end

main()
