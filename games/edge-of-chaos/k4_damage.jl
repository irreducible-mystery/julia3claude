# Redo #1 from the breaker report: independent edge measurement for K=4.
#
# K=2 earned the damage/E-peak identification (both methods agree); K=4
# merely assumed it. This measures damage spreading for K=4 across the same
# 10 λ-bins, so the "E peaks at the edge" claim has an independent edge to
# point at.
#
# Setup: K=4, radius 2, L=256 periodic, quiescent pinning, same bins as
# k4_excess_entropy.jl. NOTE on bins (breaker redo #4): spacing is 0.05
# below λ=0.25 and 0.10 above — disclosed here, not uniform.
# BURN=500 (breaker noted burn-in 200 < transient near the edge; damage is
# less sensitive, but 500 is safer), T_DMG=400. Flip = change one cell to a
# different random state (uniform among the other K-1). 25 rules/bin, 2 ICs,
# 3 flip positions. Per-rule values saved (breaker redo #3).
#
# Pre-registered predictions (exit 0 iff all hold):
#   S1. damage at λ=0.75 >= 0.40 (deep chaos: uncorrelated futures -> ~0.75).
#   S2. damage at λ≈0.05 <= 0.05 (ordered: perturbations die out).
#   S3. steepest damage rise between bins b,b+1 with |b - 5| <= 2
#       (E peaked at bin 5 for K=4; the damage edge should coincide).

using Random, Statistics, Printf

const KK     = 4
const RADIUS = 2
const NNB    = 2 * RADIUS + 1
const TABLE  = KK^NNB
const L      = 256
const BURN   = 500
const T_DMG  = 400

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

# flip cell f to a different random state; run both copies T_DMG steps;
# normalized Hamming distance between the futures
function damage(branch::Vector{UInt8}, rule::Vector{UInt8}, rng::AbstractRNG, f::Int)
    pert = copy(branch)
    old = pert[f]
    pert[f] = UInt8(mod(old + 1 + rand(rng, 0:KK-2), KK))
    unp = copy(branch)
    newp = similar(pert); newu = similar(unp)
    for _ in 1:T_DMG
        step!(newp, pert, rule); pert, newp = newp, pert
        step!(newu, unp, rule);  unp, newu = newu, unp
    end
    d = 0
    @inbounds for i in 1:L
        d += (pert[i] != unp[i])
    end
    return d / L
end

function run_rule(rule::Vector{UInt8}, rng::AbstractRNG)
    dg = Float64[]
    for _ in 1:2  # ICs
        state = rand(rng, UInt8(0):UInt8(KK-1), L)
        newstate = similar(state)
        for _ in 1:BURN
            step!(newstate, state, rule)
            state, newstate = newstate, state
        end
        for f in (L÷4, L÷2, 3L÷4)
            push!(dg, damage(state, rule, rng, f))
        end
    end
    return mean(dg)
end

function main()
    rng = MersenneTwister(20261011)
    ms = [51, 102, 154, 205, 256, 358, 461, 563, 666, 768]
    rules_per_bin = 25

    println("K=4 damage spreading (means over rules; stderr in parens):")
    println("   m      λ      damage")
    dg_mean = Float64[]; dg_se = Float64[]
    lambdas = Float64[]
    open("k4_damage_per_rule.csv", "w") do io
        println(io, "m,lambda,rule_idx,mean_damage")
        for m in ms
            λ = m / TABLE
            push!(lambdas, λ)
            per_rule = Float64[]
            for r in 1:rules_per_bin
                rule = sample_rule(m, rng)
                dgr = run_rule(rule, rng)
                push!(per_rule, dgr)
                @printf(io, "%d,%.4f,%d,%.5f\n", m, λ, r, dgr)
            end
            push!(dg_mean, mean(per_rule))
            push!(dg_se, std(per_rule) / sqrt(length(per_rule)))
            @printf("  %3d   %.4f   %.4f (%.4f)\n", m, λ, mean(per_rule), dg_se[end])
        end
    end

    println("\n--- pre-registered predictions ---")
    ok = true
    nb = length(ms)
    s1 = dg_mean[end] >= 0.40
    @printf("%s  S1: deep-chaos spreading  [damage(λ=0.75)=%.4f ≥ 0.40]\n",
            s1 ? "PASS" : "FAIL", dg_mean[end])
    ok &= s1

    s2 = dg_mean[1] <= 0.05
    @printf("%s  S2: ordered calm  [damage(λ≈0.05)=%.4f ≤ 0.05]\n",
            s2 ? "PASS" : "FAIL", dg_mean[1])
    ok &= s2

    slopes = [dg_mean[i+1] - dg_mean[i] for i in 1:nb-1]
    b = argmax(slopes)
    s3 = abs(b - 5) <= 2
    println((s3 ? "PASS" : "FAIL"), "  S3: damage edge coincides with E-peak ",
            "(steepest rise bins $b→$(b+1), λ≈$(round(lambdas[b],digits=2))→$(round(lambdas[b+1],digits=2)); |Δ|=$(abs(b-5)) ≤ 2)")
    ok &= s3
    return ok ? 0 : 1
end

exit(main())
