# ─────────────────────────────────────────────────────────────────────────────
# 09 · The birthday paradox — a promise, delivered late, with interest
#
# README.md has listed "birthday" among the veridical paradoxes since this
# suite began, and no file contained it (convicted by the carrier instance's
# audit; see audit_suite_by_carrier_instance.jl). Delivered here — and the
# interest on the debt is a discipline the suite lacked: this is the first
# file in paradoxes/ with a FAILURE CHANNEL. Every other file prints; this
# one can lose. Standalone it exits nonzero on failure; under run_all.jl it
# throws, so the whole suite finally has a way to go red.
#
# The paradox, exactly: among n=23 people the probability of a shared
# birthday exceeds 1/2 — against an intuition anchored on 365/2 ≈ 183.
# Veridical: the argument is sound, only the intuition objects, and the
# cure is computation. Computed here in exact rationals (no Float64 dirt
# in the verdict — the sibling repos convicted enough float receipts) and
# cross-checked by a seeded simulation (stream-dependence pinned and
# printed, per julia's F4 lesson: never quote an unseeded census).
# ─────────────────────────────────────────────────────────────────────────────
module BirthdayParadox

using Random

section(t) = println("\n── ", t, " ", "─"^max(0, 64 - length(t)))

failures = String[]
fail(msg) = push!(failures, msg)

# exact probability that n people share NO birthday (365 equiprobable days)
p_distinct(n) = prod(big(365 - k) // big(365) for k in 0:(n - 1); init = big(1)//big(1))
p_shared(n) = 1 - p_distinct(n)

section("1 · the exact crossing (Rational{BigInt} — no rounding anywhere)")
p22, p23 = p_shared(22), p_shared(23)
println("P(shared | 22) = ", Float64(p22), "  (exact numerator has ",
        length(string(numerator(p22))), " digits)")
println("P(shared | 23) = ", Float64(p23))
p22 < 1//2 || fail("crossing too early: P(22) ≥ 1/2")
p23 > 1//2 || fail("crossing too late: P(23) ≤ 1/2")
println("the crossing is exactly at n = 23: ", p22 < 1//2 < p23)

section("2 · the intuition, measured")
# the anchor 365/2 ≈ 183 answers a DIFFERENT question: how many people
# until someone shares MY birthday. That crossing is at 253.
p_mine(n) = 1 - (big(364)//big(365))^n
println("P(someone shares YOUR birthday | 183) = ", Float64(p_mine(183)),
        "   (still under 1/2!)")
p_mine(252) < 1//2 < p_mine(253) ||
    fail("the self-centered crossing is not at 253")
println("that question crosses 1/2 at n = 253, not 183 — the paradox is a")
println("quantifier swap: ∃ pair vs ∃ pair-containing-me. Veridical.")

section("3 · seeded simulation agrees (stream pinned: MersenneTwister(20260804))")
rng = MersenneTwister(20260804)
trials = 100_000
hits = count(1:trials) do _
    days = rand(rng, 1:365, 23)
    length(unique(days)) < 23
end
est = hits / trials
println("MC estimate at n=23: ", est, "  vs exact ", Float64(p23))
abs(est - Float64(p23)) < 0.005 ||
    fail("simulation departs from exact value by ≥ 0.005")

section("4 · the instrument can say no")
# a deliberately wrong law — crossing at 22 — must be rejected by the
# same exact arithmetic that passed the true law.
mutant_fires = !(p_shared(21) < 1//2 < p22)
mutant_fires || fail("mutant law (crossing at 22) was not rejected")
println("mutant law 'crossing at n=22' rejected: ", mutant_fires)

# ── the channel ──────────────────────────────────────────────────────────────
if isempty(failures)
    println("\n09_birthday: all checks pass (exact crossing, quantifier swap, ",
            "seeded MC, mutant control)")
else
    msg = "09_birthday FAILED: " * join(failures, "; ")
    if abspath(PROGRAM_FILE) == @__FILE__
        println("\n** FAIL ** ", msg)
        exit(1)
    else
        error(msg)          # propagate through run_all.jl — the suite goes red
    end
end

end # module
