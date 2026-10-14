#!/usr/bin/env julia
# diag_pool.jl — does the M=2 attendance bias scatter symmetrically across
# strategy-pool realizations (finite-pool effect) or persist (bug)?
using Random, Printf, Statistics

function mean_frac(rng, M)
    N = 101; P = 1 << M; mask = P - 1
    tables = UInt8.(rand(rng, Bool, N, 2, P))
    scores = zeros(Int, N, 2)
    hist = rand(rng, 0:mask)
    tot = 0
    for t in 1:20000
        h = hist + 1; n1 = 0
        @inbounds for i in 1:N
            s1, s2 = scores[i,1], scores[i,2]
            s = s1 > s2 ? 1 : s2 > s1 ? 2 : (rand(rng, Bool) ? 1 : 2)
            n1 += tables[i, s, h]
        end
        minority = n1 * 2 < N ? UInt8(1) : UInt8(0)
        @inbounds for i in 1:N, s in 1:2
            scores[i, s] += (tables[i, s, h] == minority)
        end
        hist = ((hist << 1) & mask) | minority
        t > 10000 && (tot += n1)
    end
    return tot / 10000 / N
end

println("M=2, 12 pool realizations (strategy tables redrawn per seed):")
devs = Float64[]
for seed in (11, 22, 33, 44, 55, 66, 77, 88, 99, 110, 121, 132)
    rng = MersenneTwister(9000 + 1000*2 + seed)
    mf = mean_frac(rng, 2)
    push!(devs, mf - 0.5)
    @printf("  seed=%3d  mean(A)/N=%.4f  dev=%+.4f\n", seed, mf, mf - 0.5)
end
@printf("disorder average dev = %+.4f  (n_pos=%d, n_neg=%d)\n",
        mean(devs), count(>(0), devs), count(<(0), devs))
