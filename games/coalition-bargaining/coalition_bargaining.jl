#!/usr/bin/env julia
#
# coalition_bargaining.jl — 3-player repeated coalition bargaining.
#
# The "purest" coopetition game. Each round a pot of value V is available.
# Any 2 of the 3 players may form a coalition and claim it, but they must
# agree on the split. Cooperate *within* the coalition; compete *over*
# membership and splits.
#
# Protocol (per round):
#   1. proposer rotates 1 -> 2 -> 3 -> 1 ...
#   2. proposer chooses a partner and offers (keep, give), keep + give = pot
#   3. partner accepts or rejects
#   4. accept -> payoffs (keep, give); excluded player gets 0
#      reject -> everyone gets 0
#
# Reproducibility: all randomness flows through a seeded MersenneTwister
# (house style: frozen randomness, auditable runs). Pre-registered predictions
# are checked at the end; exit code 0 iff all hold.
#
# Usage:
#   julia coalition_bargaining.jl [--rounds N] [--pot V] [--seed S] [--verbose]

using Random
using Printf
using Statistics

# ---------------------------------------------------------------- strategies

abstract type Strategy end

"""Offers a random split to a random partner; accepts almost anything."""
struct RandomAgent <: Strategy end

"""Offers 50/50 to the least-included partner; accepts >= 40%."""
struct FairAgent <: Strategy end

"""Offers 80/20 to a random partner; accepts >= 60%."""
struct GreedyAgent <: Strategy end

"""Like Fair, but holds grudges against excluders for `memory` rounds."""
mutable struct Grudger <: Strategy
    memory::Int
    grudges::Dict{Int,Int}  # player => rounds of grudge remaining
    Grudger(memory::Int=5) = new(memory, Dict{Int,Int}())
end

# propose(rng, strat, me, others, pot, hist) -> (partner, keep, give)
function propose(rng::AbstractRNG, ::RandomAgent, me::Int, others::Vector{Int},
                 pot::Int, hist::Vector)
    partner = rand(rng, others)
    keep = rand(rng, 0:pot)
    return (partner, keep, pot - keep)
end

function inclusion_counts(hist::Vector)
    counts = Dict(1 => 0, 2 => 0, 3 => 0)
    for r in hist
        if r.accepted
            counts[r.proposer] += 1
            counts[r.partner] += 1
        end
    end
    return counts
end

function propose(rng::AbstractRNG, ::FairAgent, me::Int, others::Vector{Int},
                 pot::Int, hist::Vector)
    counts = inclusion_counts(hist)
    scored = [(counts[o], rand(rng), o) for o in others]  # least-included wins
    partner = sort(scored)[1][3]
    half = pot ÷ 2
    return (partner, half, pot - half)
end

function propose(rng::AbstractRNG, ::GreedyAgent, me::Int, others::Vector{Int},
                 pot::Int, hist::Vector)
    partner = rand(rng, others)
    keep = round(Int, 0.8pot)
    return (partner, keep, pot - keep)
end

function propose(rng::AbstractRNG, g::Grudger, me::Int, others::Vector{Int},
                 pot::Int, hist::Vector)
    clean = [o for o in others if get(g.grudges, o, 0) == 0]
    pool = isempty(clean) ? others : clean
    counts = inclusion_counts(hist)
    scored = [(counts[o], rand(rng), o) for o in pool]
    partner = sort(scored)[1][3]
    half = pot ÷ 2
    return (partner, half, pot - half)
end

# respond(rng, strat, me, proposer, give, pot, hist) -> accept::Bool
respond(rng::AbstractRNG, ::RandomAgent, me::Int, proposer::Int, give::Int,
        pot::Int, hist::Vector) = give >= round(Int, 0.1pot)

respond(rng::AbstractRNG, ::FairAgent, me::Int, proposer::Int, give::Int,
        pot::Int, hist::Vector) = give >= round(Int, 0.4pot)

respond(rng::AbstractRNG, ::GreedyAgent, me::Int, proposer::Int, give::Int,
        pot::Int, hist::Vector) = give >= round(Int, 0.6pot)

function respond(rng::AbstractRNG, g::Grudger, me::Int, proposer::Int, give::Int,
                 pot::Int, hist::Vector)
    if get(g.grudges, proposer, 0) > 0
        return give >= round(Int, 0.7pot)  # grudged: only a great deal tempts
    end
    return give >= round(Int, 0.4pot)
end

# observe!(strat, me, record) — agents update internal state after each round
observe!(::Strategy, me::Int, record) = nothing

function observe!(g::Grudger, me::Int, record)
    for (p, t) in collect(g.grudges)  # tick down old grudges
        g.grudges[p] = t - 1
        t - 1 <= 0 && delete!(g.grudges, p)
    end
    if record.accepted  # excluded from a formed coalition -> grudge the members
        members = Set([record.proposer, record.partner])
        if !(me in members)
            for m in members
                g.grudges[m] = g.memory
            end
        end
    end
end

# ------------------------------------------------------------------- game

struct Config
    rounds::Int
    pot::Int
    seed::Int
    verbose::Bool
end

function play_matchup(rng::AbstractRNG, config::Config, agents::Vector{<:Strategy})
    hist = []
    totals = zeros(Int, 3)
    for round in 1:config.rounds
        proposer = ((round - 1) % 3) + 1
        others = [i for i in 1:3 if i != proposer]
        partner, keep, give = propose(rng, agents[proposer], proposer, others,
                                     config.pot, hist)
        @assert keep + give == config.pot
        @assert partner in others
        accept = respond(rng, agents[partner], partner, proposer, give,
                         config.pot, hist)
        payoffs = (0, 0, 0)
        if accept
            payoffs = ntuple(i -> i == proposer ? keep :
                                  (i == partner ? give : 0), 3)
        end
        record = (round=round, proposer=proposer,
                  partner=accept ? partner : 0, keep=keep, give=give,
                  accepted=accept, payoffs=payoffs)
        push!(hist, record)
        totals[1] += payoffs[1]; totals[2] += payoffs[2]; totals[3] += payoffs[3]
        for (i, a) in enumerate(agents)
            observe!(a, i, record)
        end
        if config.verbose
            @printf("r%3d P%d -> P%d offer (%d,%d) %s payoffs %s\n",
                    round, proposer, partner, keep, give,
                    accept ? "ACCEPT" : "reject", payoffs)
        end
    end
    return hist, totals
end

function summarize(hist::Vector, totals::Vector{Int}, rounds::Int)
    n_accept = count(r -> r.accepted, hist)
    counts = inclusion_counts(hist)
    return (totals=Tuple(totals), accept_rate=n_accept / rounds,
            inclusion=(counts[1] / rounds, counts[2] / rounds, counts[3] / rounds))
end

function fresh(sym::Symbol)
    sym == :Random  && return RandomAgent()
    sym == :Fair    && return FairAgent()
    sym == :Greedy  && return GreedyAgent()
    sym == :Grudger && return Grudger(5)
    error("unknown strategy $sym")
end

# ------------------------------------------------------- pre-registered checks

function check_predictions(lookup::Dict, config::Config)
    allok = true
    function check(name, cond)
        println((cond ? "PASS " : "FAIL ") * name)
        allok &= cond
    end
    # 1. all-Fair: symmetry -> near-equal payoffs (offers always 50/50, always accepted)
    t = lookup[(:Fair, :Fair, :Fair)].totals
    check("all-Fair payoff spread <= 5% of distributed",
          maximum(t) - minimum(t) <= 0.05 * sum(t))
    # 2. all-Greedy: every offer is 80/20, acceptance needs >= 60 -> all rejected
    t = lookup[(:Greedy, :Greedy, :Greedy)].totals
    check("all-Greedy total payoff == 0", sum(t) == 0)
    # 3. Fair/Fair/Greedy: greedy rejects 50s and its 80/20s are rejected -> frozen out
    t = lookup[(:Fair, :Fair, :Greedy)].totals
    check("Fair/Fair/Greedy: greedy payoff == 0", t[3] == 0)
    # 4. all-Random: E[payoff/player/round] = 30 (derivation in README)
    t = lookup[(:Random, :Random, :Random)].totals
    means = [x / config.rounds for x in t]
    check("all-Random mean payoff in [25,35]: $(round.(means, digits=2))",
          all(25 .<= means .<= 35))
    return allok
end

# ------------------------------------------------------------------- driver

function parse_args()
    rounds, pot, seed, verbose = 300, 100, 20261008, false
    i = 1
    while i <= length(ARGS)
        a = ARGS[i]
        if a == "--rounds" && i < length(ARGS)
            rounds = parse(Int, ARGS[i+1]); i += 2
        elseif a == "--pot" && i < length(ARGS)
            pot = parse(Int, ARGS[i+1]); i += 2
        elseif a == "--seed" && i < length(ARGS)
            seed = parse(Int, ARGS[i+1]); i += 2
        elseif a == "--verbose"
            verbose = true; i += 1
        else
            @warn "unknown arg $a"; i += 1
        end
    end
    return Config(rounds, pot, seed, verbose)
end

function main()
    config = parse_args()
    kinds = [:Random, :Fair, :Greedy, :Grudger]
    rows = []
    lookup = Dict{Tuple,Any}()
    for (ia, a) in enumerate(kinds), (ib, b) in enumerate(kinds),
        (ic, c) in enumerate(kinds)
        # deterministic per-matchup seed: hash() is NOT session-stable, so index it
        idx = (ia - 1) * 16 + (ib - 1) * 4 + (ic - 1)
        rng = MersenneTwister(config.seed * 100003 + idx)
        agents = Strategy[fresh(a), fresh(b), fresh(c)]
        hist, totals = play_matchup(rng, config, agents)
        s = summarize(hist, totals, config.rounds)
        row = (matchup="$a/$b/$c", totals=s.totals,
               accept_rate=s.accept_rate, inclusion=s.inclusion)
        push!(rows, row)
        lookup[(a, b, c)] = row
    end

    @printf("%-22s %8s %8s %8s %8s\n", "matchup", "p1", "p2", "p3", "accept%")
    for row in rows
        @printf("%-22s %8d %8d %8d %7.1f%%\n",
                row.matchup, row.totals..., 100 * row.accept_rate)
    end

    open("results.csv", "w") do io
        println(io, "matchup,p1,p2,p3,accept_rate,incl1,incl2,incl3")
        for row in rows
            println(io, row.matchup, ",",
                    join(row.totals, ","), ",",
                    round(row.accept_rate, digits=4), ",",
                    join(round.(row.inclusion, digits=4), ","))
        end
    end
    println("wrote results.csv")

    println("\n--- pre-registered predictions ---")
    ok = check_predictions(lookup, config)
    exit(ok ? 0 : 1)
end

main()
