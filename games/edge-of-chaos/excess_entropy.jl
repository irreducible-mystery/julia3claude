# Follow-up: excess entropy at the edge of chaos
#
# The transient-peak test failed (P1), confounded by the 500-step cap on a
# 2^256 state space. Raw Lempel-Ziv was considered and REJECTED: normalized
# LZ -> 1 for random-looking strings, and chaotic CA spacetime looks random,
# so LZ would saturate monotonically just like entropy did — same confound.
#
# The theoretically correct "interestingness" measure is EXCESS ENTROPY
# (Crutchfield, Feldman, Shalizi): E = I(past ; future), the predictable
# structure in a process. Frozen order -> E ~ 0 (nothing to predict beyond
# the period). Chaos -> E ~ 0 (past tells you nothing). The edge ->
# E large (long-range correlations).
#
# Estimator: per-site block entropies H(7), H(8) from the binary time series
# (3000 steps after 200-step burn-in, 256 sites pooled), Miller-Madow
# bias-corrected; entropy rate h = max(H(8)-H(7), 0); E = max(H(8)-8h, 0).
#
# Same CA setup and λ-bins as langton_test.jl (K=2, radius 2, L=256,
# periodic, quiescent condition). 40 rules/bin, 2 ICs each, seeded.
#
# Pre-registered predictions (exit 0 iff all hold):
#   Q1. argmax(mean E) is an interior bin.
#   Q2. E_peak >= 2 * max(E_first, E_last) — the peak is pronounced.
#   Q3. |bin(E peak) - 6| <= 2 — same edge as the damage transition
#       located in run 1 (steepest damage rise between bins 6->7,
#       λ ≈ 0.34 -> 0.41).

using Random, Statistics, Printf

const RADIUS = 2
const NNB    = 2 * RADIUS + 1
const TABLE  = 2^NNB
const L      = 256
const BURN   = 200
const WARM   = 8
const T_REC  = 3000

function step!(newstate::Vector{UInt8}, state::Vector{UInt8}, rule::Vector{UInt8})
    @inbounds for i in 1:L
        idx = 0
        for d in -RADIUS:RADIUS
            j = i + d
            if j < 1
                j += L
            elseif j > L
                j -= L
            end
            idx = (idx << 1) | state[j]
        end
        newstate[i] = rule[idx+1]
    end
    return newstate
end

function sample_rule(m::Int, rng::AbstractRNG)
    rule = zeros(UInt8, TABLE)
    cand = collect(2:TABLE)
    shuffle!(rng, cand)
    for e in cand[1:m]
        rule[e] = 0x01
    end
    return rule
end

# Miller-Madow bias-corrected block entropy (bits)
function block_entropy(counts::Vector{Int}, total::Int)
    h = 0.0
    m = 0
    for c in counts
        if c > 0
            m += 1
            p = c / total
            h -= p * log2(p)
        end
    end
    return h + (m - 1) / (2 * total * log(2))
end

# one run: burn in, then accumulate 7- and 8-block counts over T_REC steps
# (sites pooled), return (E, h)
function excess_entropy_run(state0::Vector{UInt8}, rule::Vector{UInt8})
    state = copy(state0)
    newstate = similar(state)
    for _ in 1:BURN
        step!(newstate, state, rule)
        state, newstate = newstate, state
    end
    w = zeros(UInt16, L)
    c7 = zeros(Int, 128)
    c8 = zeros(Int, 256)
    for _ in 1:WARM
        step!(newstate, state, rule)
        state, newstate = newstate, state
        @inbounds for i in 1:L
            w[i] = ((w[i] << 1) | state[i]) & 0xFF
        end
    end
    for _ in 1:T_REC
        step!(newstate, state, rule)
        state, newstate = newstate, state
        @inbounds for i in 1:L
            w[i] = ((w[i] << 1) | state[i]) & 0xFF
            wi = w[i]
            c8[wi+1] += 1
            c7[(wi >> 1)+1] += 1
        end
    end
    total = T_REC * L
    h7 = block_entropy(c7, total)
    h8 = block_entropy(c8, total)
    h = max(h8 - h7, 0.0)
    E = max(h8 - 8 * h, 0.0)
    return E, h
end

function main()
    rng = MersenneTwister(20261009)
    ms = [1, 3, 5, 7, 9, 11, 13, 15]
    rules_per_bin = 40
    ics_per_rule = 2

    println("λ-bin excess entropy (means over rules × ICs):")
    println("   m      λ        E         h")
    e_mean = Float64[]; h_mean = Float64[]
    for m in ms
        es = Float64[]; hs = Float64[]
        for _ in 1:rules_per_bin
            rule = sample_rule(m, rng)
            for _ in 1:ics_per_rule
                state0 = UInt8.(rand(rng, Bool, L))
                E, h = excess_entropy_run(state0, rule)
                push!(es, E); push!(hs, h)
            end
        end
        push!(e_mean, mean(es)); push!(h_mean, mean(hs))
        @printf("  %2d   %.4f   %7.4f   %7.4f\n", m, m / TABLE, mean(es), mean(hs))
    end

    println("\n--- pre-registered predictions ---")
    ok = true
    b_e = argmax(e_mean)
    q1 = !(b_e in (1, length(ms)))
    println((q1 ? "PASS" : "FAIL"), "  Q1: argmax E is interior ",
            "(bin $b_e of $(length(ms)), λ=$(ms[b_e]/TABLE))")
    ok &= q1

    q2 = e_mean[b_e] >= 2 * max(e_mean[1], e_mean[end])
    @printf("%s  Q2: peak pronounced  [E_peak=%.4f, 2*max(ends)=%.4f]\n",
            q2 ? "PASS" : "FAIL", e_mean[b_e], 2 * max(e_mean[1], e_mean[end]))
    ok &= q2

    q3 = abs(b_e - 6) <= 2
    println((q3 ? "PASS" : "FAIL"), "  Q3: same edge as damage transition ",
            "(E-peak bin $b_e vs damage-transition bin 6, |Δ|=$(abs(b_e-6)) ≤ 2)")
    ok &= q3

    open("excess_entropy.csv", "w") do io
        println(io, "m,lambda,mean_E,mean_h")
        for (i, m) in enumerate(ms)
            @printf(io, "%d,%.4f,%.5f,%.5f\n", m, m / TABLE, e_mean[i], h_mean[i])
        end
    end
    return ok ? 0 : 1
end

exit(main())
