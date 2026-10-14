#!/usr/bin/env julia
# diag_bias.jl — is the M=2 mean-attendance deviation real or correlated noise?
# Runs M in {2,3} over 3 seeds each; reports mean(A)/N, lag-1 autocorrelation,
# and the effective standard error of the mean.

using Random, Printf, Statistics, LinearAlgebra

function attendance_series(rng, M)
    P = 1 << M; mask = P - 1
    tables = UInt8.(rand(rng, Bool, 101, 2, P))
    scores = zeros(Int, 101, 2)
    hist = rand(rng, 0:mask)
    A = zeros(Int, 20000)
    for t in 1:20000
        h = hist + 1; n1 = 0
        @inbounds for i in 1:101
            s1, s2 = scores[i,1], scores[i,2]
            s = s1 > s2 ? 1 : s2 > s1 ? 2 : (rand(rng, Bool) ? 1 : 2)
            n1 += tables[i, s, h]
        end
        A[t] = n1
        minority = n1 * 2 < 101 ? UInt8(1) : UInt8(0)
        @inbounds for i in 1:101, s in 1:2
            scores[i, s] += (tables[i, s, h] == minority)
        end
        hist = ((hist << 1) & mask) | minority
    end
    return A[10001:end]
end

function lag1_rho(x)
    xc = x .- mean(x)
    return dot(xc[1:end-1], xc[2:end]) / dot(xc, xc)
end

for M in (2, 3)
    println("M=$M")
    for seed in (20261012, 777, 424242)
        rng = MersenneTwister(seed + 1000*M + 7)
        A = attendance_series(rng, M)
        mf = mean(A) / 101
        rho = lag1_rho(Float64.(A))
        # effective n via AR(1) approximation: n_eff = n*(1-rho)/(1+rho)
        n_eff = length(A) * (1 - rho) / (1 + rho)
        se = (std(A) / 101) / sqrt(max(n_eff, 1))
        @printf("  seed=%d  mean(A)/N=%.4f  dev=%+.4f  rho1=%.3f  n_eff=%7.1f  se=%.4f  dev/se=%5.1f\n",
                seed, mf, mf - 0.5, rho, n_eff, se, (mf - 0.5) / se)
    end
end
