# Redo #5 (diagnostic, not pre-registered): replicate the breaker's
# Miller-Madow probe. For fresh rules at λ=0.75 (tail) and λ=0.25 (peak),
# compute E with and without the MM correction side by side.
# Breaker reported Δ ≈ -0.37 bits in the tail, ~0 at the peak.

using Random, Statistics, Printf

const KK     = 4
const RADIUS = 2
const NNB    = 2 * RADIUS + 1
const TABLE  = KK^NNB
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

function block_entropy(counts::Vector{Int}, total::Int, mm::Bool)
    h = 0.0
    m = 0
    for c in counts
        if c > 0
            m += 1
            p = c / total
            h -= p * log2(p)
        end
    end
    return mm ? h + (m - 1) / (2 * total * log(2)) : h
end

function e_both(state0::Vector{UInt8}, rule::Vector{UInt8})
    state = copy(state0); newstate = similar(state)
    for _ in 1:BURN
        step!(newstate, state, rule); state, newstate = newstate, state
    end
    w = zeros(UInt32, L)
    c7 = zeros(Int, KK^7); c8 = zeros(Int, KK^8)
    for _ in 1:WARM
        step!(newstate, state, rule); state, newstate = newstate, state
        @inbounds for i in 1:L; w[i] = ((w[i] << 2) | state[i]) & 0xFFFF; end
    end
    for _ in 1:T_REC
        step!(newstate, state, rule); state, newstate = newstate, state
        @inbounds for i in 1:L
            w[i] = ((w[i] << 2) | state[i]) & 0xFFFF
            wi = w[i]; c8[wi+1] += 1; c7[(wi >> 2)+1] += 1
        end
    end
    total = T_REC * L
    out = Float64[]
    for mm in (false, true)
        h7 = block_entropy(c7, total, mm); h8 = block_entropy(c8, total, mm)
        h = max(h8 - h7, 0.0)
        push!(out, max(h8 - 8h, 0.0))
    end
    return out[1], out[2]  # (raw, mm-corrected)
end

function main()
    rng = MersenneTwister(777)
    for (m, label) in ((768, "λ=0.75 tail"), (256, "λ=0.25 peak"))
        println("--- $label (m=$m) ---")
        for r in 1:3
            rule = sample_rule(m, rng)
            state0 = rand(rng, UInt8(0):UInt8(KK-1), L)
            raw, mm = e_both(state0, rule)
            @printf("  rule %d: E_raw=%.4f  E_mm=%.4f  Δ=%+.4f\n", r, raw, mm, mm - raw)
        end
    end
end

main()
