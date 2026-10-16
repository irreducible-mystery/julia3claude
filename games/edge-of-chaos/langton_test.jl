# Testing Langton's contested claim: does complexity peak at the edge of chaos?
#
# (Chris Langton — "computation at the edge of chaos", Physica D 42, 1990.)
#
# Design: 1-D binary CA, radius 2 (neighborhood N=5, 32-entry rule table),
# periodic lattice of L cells. Langton's λ = m/32 where m = number of
# rule-table entries mapping to the non-quiescent state (entry for the
# all-zero neighborhood is pinned to 0 — Langton's quiescent condition).
# For each λ-bin we sample random rules, run random initial conditions, and
# measure three proxies for "interesting behavior":
#   1. transient length  — time to fall into an attractor (capped)
#   2. mean single-site temporal entropy after burn-in
#   3. damage spreading  — flip one cell, normalized Hamming distance later
#
# Langton's statistical claim predicts: transients peak at an INTERIOR λ
# (the phase transition), damage rises from ~0 (ordered) to large (chaotic)
# with its steepest rise AT that same transition.
#
# Pre-registered predictions (exit 0 iff all hold):
#   P1. argmax(mean transient) is an interior bin (not first/last).
#   P2. damage[end] >= 0.25 and damage[1] <= 0.05 (ordered vs chaotic).
#   P3. |bin(argmax transient) - bin(steepest damage rise)| <= 2.
#
# Caveat (Mitchell–Hraber–Crutchfield 1993): the λ↔behavior mapping is
# rule-encoding-dependent, and evolved high-performance rules need not sit
# at λ_c. This tests Langton's ORIGINAL statistical claim on random tables
# under one fixed encoding — not the stronger "evolution drives systems to
# the edge" version (Packard 1988).

using Random, Statistics, Printf

const RADIUS = 2
const NNB    = 2 * RADIUS + 1   # 5
const TABLE  = 2^NNB            # 32
const L      = 256              # lattice cells, periodic
const T_CAP  = 500              # transient-detection cap
const BURN   = 200              # burn-in before measurement
const T_ENT  = 200              # entropy window
const T_DMG  = 400              # damage-spreading horizon

# one CA step; neighborhood bits -> table index, leftmost neighbor = MSB
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

# random rule with exactly m non-quiescent entries; all-zero neighborhood -> 0
function sample_rule(m::Int, rng::AbstractRNG)
    rule = zeros(UInt8, TABLE)
    cand = collect(2:TABLE)
    shuffle!(rng, cand)
    for e in cand[1:m]
        rule[e] = 0x01
    end
    return rule
end

# steps until the trajectory first repeats a state (hash), capped at T_CAP
function transient_length(state0::Vector{UInt8}, rule::Vector{UInt8})
    state = copy(state0)
    newstate = similar(state)
    seen = Dict{UInt,Int}()
    for t in 0:T_CAP
        h = hash(state)
        if haskey(seen, h)
            return t
        end
        seen[h] = t
        step!(newstate, state, rule)
        state, newstate = newstate, state
    end
    return T_CAP
end

# run BURN steps, then measure mean single-site binary entropy over T_ENT steps;
# also returns the state at end of burn-in for the damage branch
function entropy_and_branch(state0::Vector{UInt8}, rule::Vector{UInt8})
    state = copy(state0)
    newstate = similar(state)
    for _ in 1:BURN
        step!(newstate, state, rule)
        state, newstate = newstate, state
    end
    branch = copy(state)
    counts = zeros(Int, L)
    for _ in 1:T_ENT
        step!(newstate, state, rule)
        state, newstate = newstate, state
        @inbounds for i in 1:L
            counts[i] += state[i]
        end
    end
    s = 0.0
    for i in 1:L
        p = counts[i] / T_ENT
        if 0.0 < p < 1.0
            s += -(p * log2(p) + (1 - p) * log2(1 - p))
        end
    end
    return s / L, branch, state
end

# from the branch state: flip cell f, run T_DMG steps on both copies,
# normalized Hamming distance between the futures
function damage(branch::Vector{UInt8}, unperturbed_final::Vector{UInt8},
                rule::Vector{UInt8}, f::Int)
    pert = copy(branch)
    pert[f] = 1 - pert[f]
    newp = similar(pert)
    # advance the unperturbed copy from branch state to match horizon
    unp = copy(branch)
    newu = similar(unp)
    for _ in 1:T_DMG
        step!(newp, pert, rule); pert, newp = newp, pert
        step!(newu, unp, rule);  unp, newu = newu, unp
    end
    # unperturbed_final was measured after BURN+T_ENT; advance unp the extra T_ENT
    # (simpler: compare against the trajectory we already have is messy, so
    #  just compare pert vs unp here — both ran T_DMG from the same branch)
    d = 0
    @inbounds for i in 1:L
        d += (pert[i] != unp[i])
    end
    return d / L
end

function run_case(rule::Vector{UInt8}, rng::AbstractRNG)
    state0 = UInt8.(rand(rng, Bool, L))
    tr = transient_length(state0, rule)
    ent, branch, _ = entropy_and_branch(state0, rule)
    dmg = mean(damage(branch, branch, rule, f) for f in (L÷4, L÷2, 3L÷4))
    return tr, ent, dmg
end

function main()
    rng = MersenneTwister(20261008)
    ms = [1, 3, 5, 7, 9, 11, 13, 15]   # λ = m/32
    rules_per_bin = 50
    ics_per_rule = 3

    println("λ-bin results (means over rules × ICs):")
    println("   m      λ      transient    entropy     damage")
    tr_mean = Float64[]; en_mean = Float64[]; dg_mean = Float64[]
    for m in ms
        trs = Float64[]; ens = Float64[]; dgs = Float64[]
        for _ in 1:rules_per_bin
            rule = sample_rule(m, rng)
            for _ in 1:ics_per_rule
                tr, en, dg = run_case(rule, rng)
                push!(trs, tr); push!(ens, en); push!(dgs, dg)
            end
        end
        λ = m / TABLE
        push!(tr_mean, mean(trs)); push!(en_mean, mean(ens)); push!(dg_mean, mean(dgs))
        @printf("  %2d   %.4f   %9.1f   %8.4f   %8.4f\n", m, λ, mean(trs), mean(ens), mean(dgs))
    end

    # --- pre-registered predictions ---
    println("\n--- pre-registered predictions ---")
    ok = true
    b_tr = argmax(tr_mean)
    p1 = !(b_tr in (1, length(ms)))
    println((p1 ? "PASS" : "FAIL"), "  P1: argmax transient is interior ",
            "(bin $b_tr of $(length(ms)), λ=$(ms[b_tr]/TABLE))")
    ok &= p1

    p2 = dg_mean[end] >= 0.25 && dg_mean[1] <= 0.05
    @printf("%s  P2: damage contrast  [first=%.4f ≤0.05, last=%.4f ≥0.25]\n",
            p2 ? "PASS" : "FAIL", dg_mean[1], dg_mean[end])
    ok &= p2

    slopes = [dg_mean[i+1] - dg_mean[i] for i in 1:length(ms)-1]
    b_dg = argmax(slopes)  # steepest rise between bin b_dg and b_dg+1
    p3 = abs(b_tr - b_dg) <= 2
    println((p3 ? "PASS" : "FAIL"), "  P3: transition alignment ",
            "(peak-transient bin $b_tr, steepest-damage bin $b_dg, |Δ|=$(abs(b_tr-b_dg)) ≤ 2)")
    ok &= p3

    # CSV for the record
    open("langton_results.csv", "w") do io
        println(io, "m,lambda,mean_transient,mean_entropy,mean_damage")
        for (i, m) in enumerate(ms)
            @printf(io, "%d,%.4f,%.2f,%.5f,%.5f\n", m, m/TABLE, tr_mean[i], en_mean[i], dg_mean[i])
        end
    end
    return ok ? 0 : 1
end

exit(main())
