#!/usr/bin/env julia
#
# forage_share.jl — the "cooperation" corner: a 3-player common-pool
# resource game (forage-and-share).
#
# Three players share one renewable resource. Each round every player
# chooses a harvest; the stock then regrows logistically. No communication,
# no enforcement — the only question is whether self-interest sustains or
# destroys the commons.
#
# Dynamics: R <- R - H, then R <- R + r*R*(1 - R/K); R < 1 is extinction
# (absorbing). Desired harvests are rationed proportionally when they
# exceed the stock. Harvests are fully deterministic; no RNG is needed.
#
# Strategies:
#   Greedy    — takes the per-round cap (12) no matter what.
#   Fair      — takes the MSY quota: q = r*K/(4*3) = 7.5 per player.
#   Restraint — takes the quota, but only while R >= K/2; else 0.
#   Grim      — takes the quota until some round's total harvest exceeds
#               the sustainable max (H > 24); then withdraws forever.
#
# Pre-registered predictions are checked at the end; exit code 0 iff all
# hold. Nothing is tuned after seeing the numbers.
#
# Usage:
#   julia forage_share.jl
#
# Run 1 (2026-10-12): 4/7 predictions PASS. P1/P2/P7 fail — the naive
# continuous-time MSY quota is not sustainable in the discrete
# harvest-then-regrow map (see README.md and diag_quota.jl). The failure
# is the finding: fixed-quota cooperation collapses; feedback-based
# cooperation (Restraint, Grim withdrawal) sustains.

using Printf

# ------------------------------------------------------------------ config

const N_PLAYERS = 3
const K_CAP     = 300.0   # carrying capacity
const R_GROW    = 0.3     # intrinsic regrowth rate
const T_ROUNDS  = 500
const R_INIT    = K_CAP / 2
const HARVEST_CAP = 12.0  # per-player per-round ceiling
const QUOTA     = R_GROW * K_CAP / (4 * N_PLAYERS)  # MSY share = 7.5
const SUSTAIN_MAX = R_GROW * K_CAP / 4              # max regrowth = 22.5
const GRIM_TRIGGER = 24.0 # > SUSTAIN_MAX: someone over-harvested

# -------------------------------------------------------------- strategies

abstract type Strategy end
struct Greedy    <: Strategy end
struct Fair      <: Strategy end
struct Restraint <: Strategy end
mutable struct Grim <: Strategy
    triggered::Bool
end
Grim() = Grim(false)

# desired harvest given current stock R (before rationing)
desired(::Greedy,    R) = HARVEST_CAP
desired(::Fair,      R) = QUOTA
desired(::Restraint, R) = R >= K_CAP / 2 ? QUOTA : 0.0
desired(g::Grim,     R) = g.triggered ? 0.0 : QUOTA

# post-round hook: let Grim observe the round's total harvest
observe!(::Strategy, H) = nothing
observe!(g::Grim, H) = (g.triggered |= H > GRIM_TRIGGER)

# ------------------------------------------------------------------ match

struct MatchResult
    name::String
    strats::Vector{String}
    totals::Vector{Float64}   # per-player total harvest
    welfare::Float64          # sum of totals
    collapse_round::Int       # 0 = never collapsed
    min_R::Float64
    trajectory::Vector{Float64}# stock after each round (for the plot)
end

function play_match(strats::Vector{<:Strategy}, name::String;
                    R_init::Float64 = R_INIT, quota::Float64 = QUOTA,
                    cap::Float64 = HARVEST_CAP, T::Int = T_ROUNDS)
    # NOTE: quota/cap overrides are for diag_quota.jl only; Run 1 uses defaults.
    R = R_init
    totals = zeros(Float64, N_PLAYERS)
    collapse_round = 0
    min_R = R
    traj = Float64[]
    for t in 1:T
        if R < 1.0
            R = 0.0
            if collapse_round == 0
                collapse_round = t
            end
            push!(traj, 0.0)
            continue
        end
        want = [desired_amount(s, R, quota, cap) for s in strats]
        Hwant = sum(want)
        scale = Hwant > R ? R / Hwant : 1.0   # proportional rationing
        got = want .* scale
        H = sum(got)
        totals .+= got
        R -= H
        R += R_GROW * R * (1 - R / K_CAP)
        R = clamp(R, 0.0, K_CAP)
        min_R = min(min_R, R)
        for s in strats
            observe!(s, H)
        end
        push!(traj, R)
    end
    MatchResult(name, [string(typeof(s)) for s in strats], totals,
                sum(totals), collapse_round, min_R, traj)
end

# desired harvest with overridable quota/cap (diag use); defaults = Run 1
desired_amount(::Greedy,    R, quota, cap) = cap
desired_amount(::Fair,      R, quota, cap) = quota
desired_amount(::Restraint, R, quota, cap) = R >= K_CAP / 2 ? quota : 0.0
desired_amount(g::Grim,     R, quota, cap) = g.triggered ? 0.0 : quota

# ------------------------------------------------------- pre-registered

struct Prediction
    name::String
    claim::String
    check::Function
end

function fresh_strats(ss)
    # Grim instances are mutable; rebuild every strategy fresh per matchup.
    out = Strategy[]
    for s in ss
        if s isa Grim
            push!(out, Grim())
        elseif s isa Greedy
            push!(out, Greedy())
        elseif s isa Fair
            push!(out, Fair())
        else
            push!(out, Restraint())
        end
    end
    return out
end

function main()
    matchups = [
        ("Fair^3",               Strategy[Fair(), Fair(), Fair()]),
        ("Greedy^3",             Strategy[Greedy(), Greedy(), Greedy()]),
        ("Restraint^3",          Strategy[Restraint(), Restraint(), Restraint()]),
        ("Grim^3",               Strategy[Grim(), Grim(), Grim()]),
        ("Greedy/Fair/Fair",     Strategy[Greedy(), Fair(), Fair()]),
        ("Greedy/Greedy/Fair",   Strategy[Greedy(), Greedy(), Fair()]),
        ("Greedy/Restraint/Restraint", Strategy[Greedy(), Restraint(), Restraint()]),
        ("Greedy/Grim/Grim",     Strategy[Greedy(), Grim(), Grim()]),
        ("Fair/Fair/Restraint",  Strategy[Fair(), Fair(), Restraint()]),
    ]

    results = [play_match(fresh_strats(s), n) for (n, s) in matchups]
    byname = Dict(r.name => r for r in results)

    @printf("%-28s %10s %10s %10s %12s %10s\n",
            "matchup", "welfare", "p1", "p2/p3", "collapse@round", "min R")
    for r in results
        @printf("%-28s %10.1f %10.1f %10.1f %12d %10.1f\n",
                r.name, r.welfare, r.totals[1], r.totals[2],
                r.collapse_round, r.min_R)
    end

    open("results.csv", "w") do io
        println(io, "matchup,welfare,p1,p2,p3,collapse_round,min_R")
        for r in results
            println(io, join([r.name, @sprintf("%.3f", r.welfare),
                              [@sprintf("%.3f", x) for x in r.totals]...,
                              r.collapse_round, @sprintf("%.3f", r.min_R)], ","))
        end
    end
    println("wrote results.csv")

    open("trajectories.csv", "w") do io
        println(io, "round," * join([r.name for r in results], ","))
        for t in 1:T_ROUNDS
            println(io, join([t; [r.trajectory[t] for r in results]], ","))
        end
    end
    println("wrote trajectories.csv")

    g3    = byname["Greedy^3"]
    f3    = byname["Fair^3"]
    gff   = byname["Greedy/Fair/Fair"]
    grr   = byname["Greedy/Restraint/Restraint"]
    ggg   = byname["Greedy/Grim/Grim"]
    grim3 = byname["Grim^3"]

    preds = Prediction[
        Prediction("P1-tragedy",
            "Greedy^3 collapses within 500 rounds; Fair^3 never collapses",
            () -> 1 <= g3.collapse_round <= T_ROUNDS && f3.collapse_round == 0),
        Prediction("P2-sustainability-premium",
            "welfare(Fair^3) > 10000 and welfare(Greedy^3) < 2000",
            () -> f3.welfare > 10000 && g3.welfare < 2000),
        Prediction("P3-free-rider",
            "in Greedy/Fair/Fair the greedy player's total exceeds each fair player's",
            () -> gff.totals[1] > gff.totals[2] && gff.totals[1] > gff.totals[3]),
        Prediction("P4-one-bad-apple",
            "Greedy/Fair/Fair collapses within 500 rounds",
            () -> 1 <= gff.collapse_round <= T_ROUNDS),
        Prediction("P5-conditional-withdrawal",
            "Greedy/Grim/Grim never collapses (grim withdraws, greedy alone can't overexploit)",
            () -> ggg.collapse_round == 0),
        Prediction("P6-adaptive-restraint",
            "Greedy/Restraint/Restraint never collapses (restraint steps back below K/2)",
            () -> grr.collapse_round == 0),
        Prediction("P7-grim-among-cooperators",
            "Grim^3 never collapses and welfare >= 11000 (trigger never fires)",
            () -> grim3.collapse_round == 0 && grim3.welfare >= 11000),
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

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
