# Redo #2 from the breaker report: burn-in sensitivity sweep.
#
# The breaker found per-rule E at the K=4 peak swings 2-4x between
# burn=200 and burn=2000 — the stationarity assumption is violated at the
# edge, and the peak's height/sharpness may be untrustworthy. This sweep
# quantifies it with a PAIRED design: the same rules and initial conditions
# are measured at burn = 200, 1000, 2000, so differences are pure burn-in
# effects, not sampling noise.
#
# Bins: the K=4 E-peak neighborhood — m = 205, 256, 358, 461
# (λ ≈ 0.20, 0.25, 0.35, 0.45). 20 rules/bin, 2 ICs each.
# T_REC=2500, WARM=8, same Miller-Madow E estimator as before.
#
# Pre-registered (exit 0 iff B1,B2 hold; B3 is diagnostic):
#   B1. The argmax bin of mean E is IDENTICAL across the three burn-ins
#       (peak location is robust to burn-in).
#   B2. Pearson correlation of per-rule E in the peak bin between
#       burn=200 and burn=2000 exceeds 0.5 (rankings preserved; per-rule
#       E is a stable property, not transient-phase luck).
#   B3. (diagnostic) mean |ΔE| per rule between burn=200 and burn=2000.

using Random, Statistics, Printf

const KK     = 4
const RADIUS = 2
const NNB    = 2 * RADIUS + 1
const TABLE  = KK^NNB
const L      = 256
const WARM   = 8
const T_REC  = 2500
const BURNS  = [200, 1000, 2000]

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

# --- implementation (base-4 shift register) ---
function e_at_burn(state0::Vector{UInt8}, rule::Vector{UInt8}, burn::Int)
    state = copy(state0)
    newstate = similar(state)
    for _ in 1:burn
        step!(newstate, state, rule)
        state, newstate = newstate, state
    end
    w = zeros(UInt32, L)
    c7 = zeros(Int, KK^7)
    c8 = zeros(Int, KK^8)
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
    rng = MersenneTwister(20261012)
    ms = [205, 256, 358, 461]
    rules_per_bin = 20
    ics_per_rule = 2

    # paired design: fix rules and ICs once, measure at every burn-in
    cases = []  # (m, rule_idx, ic_idx, rule, state0)
    for m in ms
        for r in 1:rules_per_bin
            rule = sample_rule(m, rng)
            for ic in 1:ics_per_rule
                state0 = rand(rng, UInt8(0):UInt8(KK-1), L)
                push!(cases, (m, r, ic, rule, state0))
            end
        end
    end

    # E[burn][case]
    results = Dict{Int,Vector{Float64}}()
    open("burnin_per_rule.csv", "w") do io
        println(io, "m,lambda,rule_idx,ic_idx,burn,E,h")
        for burn in BURNS
            es = Float64[]
            for (m, r, ic, rule, state0) in cases
                E, h = e_at_burn(state0, rule, burn)
                push!(es, E)
                @printf(io, "%d,%.4f,%d,%d,%d,%.5f,%.5f\n", m, m / TABLE, r, ic, burn, E, h)
            end
            results[burn] = es
        end
    end

    println("bin means per burn-in:")
    println("   m      λ      E_200    E_1000   E_2000")
    binmean = Dict{Int,Vector{Float64}}()
    for burn in BURNS
        bm = Float64[]
        for m in ms
            idx = findall(c -> c[1] == m, cases)
            push!(bm, mean(results[burn][idx]))
        end
        binmean[burn] = bm
    end
    for (i, m) in enumerate(ms)
        @printf("  %3d   %.4f   %7.4f  %7.4f  %7.4f\n",
                m, m / TABLE, binmean[200][i], binmean[1000][i], binmean[2000][i])
    end

    println("\n--- pre-registered ---")
    ok = true
    argmaxes = [argmax(binmean[b]) for b in BURNS]
    b1 = length(unique(argmaxes)) == 1
    println((b1 ? "PASS" : "FAIL"), "  B1: peak bin identical across burn-ins ",
            "(argmax bins: ", join(argmaxes, ", "), ")")
    ok &= b1

    # peak bin = the argmax at burn=200 (matches k4 run: bin index of m=256)
    pb = argmax(binmean[200])
    pm = ms[pb]
    e200 = [results[200][i] for i in findall(c -> c[1] == pm, cases)]
    e2000 = [results[2000][i] for i in findall(c -> c[1] == pm, cases)]
    r = cor(e200, e2000)
    b2 = r > 0.5
    @printf("%s  B2: per-rule ranking preserved at peak bin (m=%d): Pearson r=%.3f > 0.5\n",
            b2 ? "PASS" : "FAIL", pm, r)
    ok &= b2

    mad = mean(abs.(e200 .- e2000))
    @printf("  B3 (diagnostic): mean |ΔE| per rule, burn 200→2000, peak bin: %.4f\n", mad)
    return ok ? 0 : 1
end

exit(main())
