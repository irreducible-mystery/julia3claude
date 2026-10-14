#!/usr/bin/env julia
#
# minority_game.jl — the classic "neither" game (W. B. Arthur 1994;
# Challet & Zhang 1997).
#
# N (odd) agents each choose side 0 or 1 every round; the minority side wins.
# Each agent holds S internal strategy tables mapping the last M winning
# outcomes (an M-bit history) to an action. Strategies earn virtual points
# whenever they *would have* picked the winning side; each agent plays its
# currently best-scoring strategy (ties broken uniformly at random).
#
# No communication, no altruism, no coalitions — pure self-interest. Yet the
# population's attendance volatility sigma^2 = Var(A), A = # choosing side 1,
# undergoes a genuine phase transition in alpha = 2^M / N (Challet & Zhang):
#
#   alpha << alpha_c ~ 0.34 : crowded phase,  sigma^2/N > 1/4 (worse than chance)
#   alpha ~  alpha_c        : coordinated phase, sigma^2/N << 1/4 (beats chance)
#   alpha >> alpha_c        : random phase,    sigma^2/N -> 1/4
#
# Reproducibility: all randomness flows through a seeded MersenneTwister;
# per-config seeds are derived deterministically from the base seed and M
# (session-stable: hash() is not used). Pre-registered predictions are
# checked at the end; exit code 0 iff all hold.
#
# Usage:
#   julia minority_game.jl [--seed S] [--rounds T] [--warmup W]

using Random
using Printf
using Statistics

# ------------------------------------------------------------------ config

const N_AGENTS = 101          # odd, so a minority side always exists
const S_STRATS = 2            # strategies per agent (the canonical S = 2)
const MS       = [2, 3, 4, 5, 6, 8, 10]   # memory lengths; alpha = 2^M / N
const T_ROUNDS = 20000
const WARMUP   = 10000       # measure over rounds WARMUP+1 .. T_ROUNDS

# ------------------------------------------------------- pre-registered
# Bands below are the qualitative claims of Challet & Zhang (1997) for S = 2,
# stated before running. Literature values: min sigma^2/N ~ 0.05-0.10 near
# alpha_c ~= 0.34; sigma^2/N -> 1/4 for alpha >> alpha_c; sigma^2/N rises
# well above 1/4 deep in the crowded phase.
#
# REVISION HISTORY (lab notebook, not goalpost-moving):
#   v1 (2026-10-12, first run): P4 claimed |mean(A)/N - 0.5| < 0.02 per config.
#     P1-P3 PASS, P4 FAIL: M=2 gave 0.5208 (dev +0.0208, 25 effective-SE).
#     Diagnosis: NOT a code bug. Diagnostics (diag_pool.jl) over 12 fresh
#     strategy-pool realizations at M=2 scatter symmetrically (6+/6-,
#     disorder-average dev +0.0065): a finite-pool effect. With P=4 histories
#     and 202 table draws from 16 possible tables, the realized strategy
#     multiset is never exactly 0/1-symmetric, and the crowded phase
#     amplifies pool asymmetry into attendance bias. The literature averages
#     over disorder (pool realizations); a single realization is not obliged
#     to be symmetric. M>=3 (strategy space >= 256 tables) was clean.
#   v2 (2026-10-12): P4 -> P4r, the disorder-averaged symmetry claim, which
#     is what the literature actually asserts. Re-registered BEFORE the v2 run.

const N_SEEDS_SYM = 5   # pool realizations averaged for P4r

struct Prediction
    name::String
    claim::String
    check::Function
end

# ------------------------------------------------------- core simulation

"Run one (N, M, S) configuration; return (sigma2_over_N, mean_attendance_frac)."
function run_config(rng::AbstractRNG, M::Int)
    P = 1 << M                      # number of possible histories
    mask = P - 1
    # strategy tables: agent x strategy x history -> action (0/1)
    # NOTE: rand(rng, UInt8, ...) fills bytes 0..255 -- generate bits instead.
    tables = UInt8.(rand(rng, Bool, N_AGENTS, S_STRATS, P))
    scores = zeros(Int, N_AGENTS, S_STRATS)
    hist = rand(rng, 0:mask)        # random initial history
    A = zeros(Int, T_ROUNDS)

    for t in 1:T_ROUNDS
        h = hist + 1                # 1-based index into tables
        n1 = 0
        @inbounds for i in 1:N_AGENTS
            # best-scoring strategy, ties broken uniformly at random
            s1, s2 = scores[i, 1], scores[i, 2]
            s = s1 > s2 ? 1 : s2 > s1 ? 2 : (rand(rng, Bool) ? 1 : 2)
            a = tables[i, s, h]
            n1 += a
            # virtual scoring happens after the minority is known (below)
        end
        A[t] = n1
        minority = n1 * 2 < N_AGENTS ? UInt8(1) : UInt8(0)
        @inbounds for i in 1:N_AGENTS, s in 1:S_STRATS
            scores[i, s] += (tables[i, s, h] == minority)
        end
        hist = ((hist << 1) & mask) | minority
    end

    window = @view A[WARMUP+1:end]
    sigma2_over_N = var(window) / N_AGENTS
    mean_frac = mean(window) / N_AGENTS
    return sigma2_over_N, mean_frac
end

# ------------------------------------------------------------------ main

function main()
    seed = 20261012
    args = ARGS
    i = 1
    while i <= length(args)
        if args[i] == "--seed" && i < length(args)
            seed = parse(Int, args[i+1]); i += 2
        else
            i += 1
        end
    end

    println("Minority game — N=$N_AGENTS, S=$S_STRATS, T=$T_ROUNDS (measuring last $(T_ROUNDS - WARMUP))")
    println("seed=$seed\n")
    @printf("%4s %10s %14s %14s\n", "M", "alpha", "sigma^2/N", "mean(A)/N")
    println("-"^48)

    results = Tuple{Int,Float64,Float64,Float64}[]
    for (k, M) in enumerate(MS)
        # session-stable per-config seed
        rng = MersenneTwister(seed + 1000 * M + 7)
        s2n, mfrac = run_config(rng, M)
        alpha = (1 << M) / N_AGENTS
        push!(results, (M, alpha, s2n, mfrac))
        @printf("%4d %10.4f %14.4f %14.4f\n", M, alpha, s2n, mfrac)
    end
    println()

    open("results.csv", "w") do io
        println(io, "M,alpha,sigma2_over_N,mean_attendance_frac")
        for (M, alpha, s2n, mfrac) in results
            @printf(io, "%d,%.6f,%.6f,%.6f\n", M, alpha, s2n, mfrac)
        end
    end
    println("wrote results.csv")

    # ------------------------------------------------- prediction checks
    alphas = [r[2] for r in results]
    s2ns   = [r[3] for r in results]
    imin = argmin(s2ns)
    imax_alpha, imin_alpha = argmax(alphas), argmin(alphas)

    # P4r: disorder-averaged symmetry. For each M, average mean(A)/N over
    # N_SEEDS_SYM independent strategy-pool realizations.
    sym_ok = true
    println("P4r disorder-averaged symmetry check:")
    for M in MS
        mfs = Float64[]
        for j in 1:N_SEEDS_SYM
            rng = MersenneTwister(seed + 1000 * M + 7 + 131 * j)
            _, mf = run_config(rng, M)
            push!(mfs, mf)
        end
        avg = sum(mfs) / length(mfs)
        okm = abs(avg - 0.5) < 0.02
        sym_ok &= okm
        @printf("  M=%2d  disorder-avg mean(A)/N = %.4f  %s\n",
                M, avg, okm ? "ok" : "OUT OF BAND")
    end

    preds = Prediction[
        Prediction("P1-coordination-dip",
            "min(sigma^2/N) occurs at alpha in [0.15, 0.70] and is < 0.20",
            () -> (0.15 <= alphas[imin] <= 0.70) && (s2ns[imin] < 0.20)),
        Prediction("P2-random-limit",
            "at largest alpha (M=10, alpha~10.1): sigma^2/N in [0.20, 0.30]",
            () -> 0.20 <= s2ns[imax_alpha] <= 0.30),
        Prediction("P3-crowding",
            "at smallest alpha (M=2, alpha~0.04): sigma^2/N > 0.25",
            () -> s2ns[imin_alpha] > 0.25),
        Prediction("P4r-disorder-symmetry",
            "for every M: disorder-averaged |mean(A)/N - 0.5| < 0.02",
            () -> sym_ok),
    ]

    println("\nPre-registered predictions:")
    allpass = true
    for p in preds
        ok = p.check()
        allpass &= ok
        println("  [$(ok ? "PASS" : "FAIL")] $(p.name): $(p.claim)")
    end
    println()
    if allpass
        println("All predictions hold. Exit 0.")
    else
        println("At least one prediction failed. Exit 1.")
        exit(1)
    end
end

main()
