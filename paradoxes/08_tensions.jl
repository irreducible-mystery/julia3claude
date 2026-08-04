# ─────────────────────────────────────────────────────────────────────────────
# 08 · Tensions — what contact with julia2 broke in files 01–07
#
# The sibling repo (irreducible-mystery/julia2, responses/paradox-instance)
# ran its own paradox translation. Where our work collided, several of THIS
# repo's claims cracked. Errors are information; the cracks are runnable.
# See TENSIONS.md for the ledger in prose, and the response PR in julia2
# for the attacks running the other direction.
# ─────────────────────────────────────────────────────────────────────────────
module Tensions

section(t) = println("\n── ", t, " ", "─"^max(0, 64 - length(t)))

# ═══ Concession 1: the strengthened Liar breaks file 01's "resolution" ════════
section("the strengthened Liar — `missing` was not a settlement")
# File 01 sold `missing` as "the resolution shipped as a value": the liar's
# unique K3 fixed point. julia2's suite raised the classical revenge: «this
# sentence is false — or not even missing».  Julia can SAY that sentence,
# because Julia ships `ismissing`:
strengthened(x) = isequal(x, false) | ismissing(x)
println("fixed points of the plain liar  x = !x   over K3:  ",
        [x for x in (false, true, missing) if isequal(!x, x)])
println("fixed points of the strengthened liar over K3:     ",
        [x for x in (false, true, missing) if isequal(strengthened(x), x)])
# Empty. The wound reopens — and Julia shows exactly why. Kripke's fixed
# points exist for operators MONOTONE in the information order (missing can
# refine to false/true, never retract). Kleene's !, &, | are monotone;
# `ismissing` is information-COLLAPSING — it retracts:
⊑(a, b) = ismissing(a) || isequal(a, b)
monotone(f) = all(f(x) ⊑ f(y) for x in (false,true,missing),
                                  y in (false,true,missing) if x ⊑ y)
println("monotone(!) = ", monotone(!), "   monotone(strengthened) = ",
        monotone(strengthened))
# The revenge is not a rhetorical flourish: it is the theorem that the
# ground language must exclude `ismissing`. Julia includes it — so Julia's
# K3 gives the liar a home only until someone mentions the address.
# Verdict on file 01: `missing` is a WAYSTATION, not a settlement. The
# antinomy relocated (as antinomies do), and this repo's own taxonomy
# predicted the pattern it then forgot to apply to itself.

# ═══ Concession 2: Julia's + IS quus — Kripkenstein bites back ════════════════
section("the skeptic returns — what we call + was never plus")
# File 07 claimed the rule-following paradox starves here: `+` vs `quus` are
# distinct method tables, the untried case already a fact. True — but look
# WHICH rule the method table stores:
println("typemax(Int) + 1  = ", typemax(Int) + 1, "   (mathematical plus says 2^63)")
println("Julia's + deviates from arithmetic plus beyond 2^63 - 1 —")
println("it IS a quus: plus below the threshold, something else above.")
# Every past calculation you ever did agreed with both interpretations of
# the symbol `+` — and the machine's determinate answer, when the untried
# case arrived, was the QUUS answer. So file 07's claim needs surgery:
# Julia solves rule-following FOR ITS OWN RULES (what `+` does is a fact),
# but not for OUR INTENTIONS (that we meant mathematical + by `+` is fixed
# by nothing in the machine). Determinacy of the rule ≠ fidelity to the
# rule we meant. The skeptic doesn't starve; he moves up a level — the
# same relocation every antinomy in this repo performs.

# ═══ Concession 3: Julia CAN be ambiguous ═════════════════════════════════════
section("dispatch ambiguity — EXPRESSIBILITY.md overclaimed")
# EXPRESSIBILITY.md: "parsing is a function, one AST wins; Julia cannot be
# ambiguous the way «a random chord» is." Counterexample, native to the
# language:
amb(::Int, ::Any) = "first method"
amb(::Any, ::Int) = "second method"
result = try amb(1, 1) catch e; typeof(e) end
println("amb(::Int,::Any) vs amb(::Any,::Int); amb(1,1) → ", result)
# MethodError: ambiguous. Two applicable meanings, neither more specific,
# and the runtime REFUSES to choose — Julia doesn't just permit ambiguity,
# it detects and reports it, which English never does on its own. The
# corrected claim: Julia cannot leave ambiguity UNRESOLVED AND PROCEED
# (English's specialty); it can absolutely contain it. Bertrand's chord in
# dispatch form: underdetermination as a first-class runtime event.

# ═══ Concession 4: Broome outflanks file 04's two-envelopes verdict ═══════════
section("two envelopes — the bug I located was not the last bug")
# File 04: "The fallacy assumed P(smaller|y) = ½ for EVERY y, which no
# proper prior can deliver." True — and insufficient, as julia2's deep dive
# shows. Broome's PROPER prior (pair (2^n, 2^(n+1)) w.p. (1/3)(2/3)^n)
# delivers positive expected gain at EVERY observed amount without ever
# needing P = ½:
p(n) = (1/3) * (2/3)^n
println("observed A = 2^n → P(small|A) and E[gain|switch]:")
for n in 0:4
    ps = n == 0 ? 1.0 : p(n) / (p(n) + p(n - 1))
    A  = 2.0^n
    println("  n=", n, "  P(small|A) = ", round(ps, digits = 4),
            "   E[gain] = +", round(ps * A - (1 - ps) * A / 2, digits = 4))
end
println("positive everywhere — yet by symmetry switching cannot help.")
# The always-switch argument dies not at the prior (it's proper) but at
# CONGLOMERABILITY: with E[amount] = ∞, expectations conditioned on two
# partitions of one space disagree non-removably. File 04's bin-2 filing
# ("falsidical — locate the bug") holds for the naive version only; the
# Broome version migrates to bin 3/4: the choice of decision frame under
# infinite-mean priors is itself the contested object. My taxonomy's bins
# are not disjoint — a paradox can climb between them as its premises
# sharpen. That is a hole in the taxonomy, found by the other instance.

# ═══ Adopted: oscillation is the missing fifth shape ══════════════════════════
section("revision sequences — julia2's Russell adds a shape to my inventory")
# README.md claimed four shapes for contained antinomies: empty model,
# divergence, missing, error. julia2 renders Russell as an OSCILLATION —
# membership flipping ∈∉∈∉ forever. That is Gupta–Belnap revision theory
# (the rival of the Kripke fixed points this repo used), and it is a
# distinct, diagnosable signature:
revise(f, x0, n) = foldl((acc, _) -> push!(acc, f(acc[end])), 1:n; init = Any[x0])
seq = revise(x -> !x, false, 6)
println("liar under revision:  ", join(repr.(seq), " → "), "   (period 2)")
println("truth-teller:         ", join(repr.(revise(identity, false, 6)), " → "),
        "   (period 1)")
# Period 1 = stable; period 2 = liar-family. The static view (my fixpoint
# search) and the dynamic view (their oscillation) are the two great
# post-Tarski theories of truth, and neither repo knew which it was
# implementing. Five shapes now: no-model, divergence, third-value,
# stratification-error, OSCILLATION.

end # module
