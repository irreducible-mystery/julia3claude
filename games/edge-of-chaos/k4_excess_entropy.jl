# K=4 follow-up: does excess entropy collapse in DEEP chaos?
#
# The K=2 sweep (λ ≤ 0.5) showed E peaking at the edge (bin 7, λ≈0.41) but
# could not probe the chaotic tail: bin-8 entropy rate was only 0.62 bits.
# With K=4 states, λ ranges to 1-1/4 = 0.75 — deep chaos. Theory predicts
# E -> ~0 there (past stops predicting future).
#
# Setup: 1-D CA, K=4, radius 2 (N=5, 1024-entry rule table), L=256 periodic.
# λ = m/1024, m non-zero entries among the 1023 non-all-zero neighborhoods
# (all-zero neighborhood pinned to 0; values uniform in {1,2,3}).
# E estimator: pooled 7-/8-block entropies over the 4-ary alphabet,
# Miller-Madow corrected, log2 units; h = max(H8-H7,0); E = max(H8-8h,0).
# 3000 recorded steps after 200-step burn-in. Seeded.
#
# Pre-registered predictions (exit 0 iff all hold):
#   R1. argmax(mean E) is interior (not first/last bin).
#   R2. E at λ=0.75 (deep chaos) < 0.5 * E_peak — the predicted collapse.
#   R3. E-peak bin has λ <= 0.6 — the edge doesn't wander far from the
#       K=2 location (~0.41).

using Random, Statistics, Printf

const KK     = 4
const RADIUS = 2
const NNB    = 2 * RADIUS + 1
const TABLE  = KK^NNB          # 1024
const L      = 256
const BURN   = 200
const WARM   = 8
const T_REC  = 2500

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
            idx = idx * KK + state[j]
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
        rule[e] = UInt8(rand(rng, 1:KK-1))
    end
    return rule
end

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

function excess_entropy_run(state0::Vector{UInt8}, rule::Vector{UInt8})
    state = copy(state0)
    newstate = similar(state)
    for _ in 1:BURN
        step!(newstate, state, rule)
        state, newstate = newstate, state
    end
    w = zeros(UInt32, L)          # 8 base-4 digits = 16 bits
    c7 = zeros(Int, KK^7)         # 16384
    c8 = zeros(Int, KK^8)         # 65536
    for _ in 1:WARM
        step!(newstate, state, rule)
        state, newstate = newstate, state
        @inbounds for i in 1:L
            w[i] = ((w[i] << 2) | state[i]) & 0xFFFF
        end
    end
    for _ in 1:T_REC
        step!(newstate, state, rule)
        state, newstate = newstate, state
        @inbounds for i in 1:L
            w[i] = ((w[i] << 2) | state[i]) & 0xFFFF
            wi = w[i]
            c8[wi+1] += 1
            c7[(wi >> 2)+1] += 1
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
    rng = MersenneTwister(20261010)
    ms = [51, 102, 154, 205, 256, 358, 461, 563, 666, 768]
    rules_per_bin = 25
    ics_per_rule = 2

    println("K=4 λ-bin excess entropy (means over rules × ICs):")
    println("   m      λ        E         h")
    e_mean = Float64[]; h_mean = Float64[]
    lambdas = Float64[]
    for m in ms
        λ = m / TABLE
        push!(lambdas, λ)
        es = Float64[]; hs = Float64[]
        for _ in 1:rules_per_bin
            rule = sample_rule(m, rng)
            for _ in 1:ics_per_rule
                state0 = rand(rng, UInt8(0):UInt8(KK-1), L)
                E, h = excess_entropy_run(state0, rule)
                push!(es, E); push!(hs, h)
            end
        end
        push!(e_mean, mean(es)); push!(h_mean, mean(hs))
        @printf("  %3d   %.4f   %7.4f   %7.4f\n", m, λ, mean(es), mean(hs))
    end

    println("\n--- pre-registered predictions ---")
    ok = true
    nb = length(ms)
    b_e = argmax(e_mean)
    r1 = !(b_e in (1, nb))
    println((r1 ? "PASS" : "FAIL"), "  R1: argmax E is interior ",
            "(bin $b_e of $nb, λ=$(round(lambdas[b_e], digits=4)))")
    ok &= r1

    r2 = e_mean[end] < 0.5 * e_mean[b_e]
    @printf("%s  R2: deep-chaos collapse  [E(λ=0.75)=%.4f < 0.5*E_peak=%.4f]\n",
            r2 ? "PASS" : "FAIL", e_mean[end], 0.5 * e_mean[b_e])
    ok &= r2

    r3 = lambdas[b_e] <= 0.6
    println((r3 ? "PASS" : "FAIL"), "  R3: edge near K=2 location ",
            "(peak λ=$(round(lambdas[b_e], digits=4)) ≤ 0.6)")
    ok &= r3

    open("k4_excess_entropy.csv", "w") do io
        println(io, "m,lambda,mean_E,mean_h")
        for (i, m) in enumerate(ms)
            @printf(io, "%d,%.4f,%.5f,%.5f\n", m, lambdas[i], e_mean[i], h_mean[i])
        end
    end
    return ok ? 0 : 1
end

exit(main())
