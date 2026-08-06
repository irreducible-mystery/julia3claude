# ======================================================================
# capture_census.jl — a census over the kernel court's certificates.
#
# WHY THIS FILE EXISTS. PR #2 merged the Lean suite onto this branch, so
# for the first time the `#guard_msgs` blocks are in the tree rather than
# in a diff I was quoting. I counted them by hand and cited the count in
# `RejectionCapture.lean`. The count was wrong. This file replaces the
# citation with a measurement that re-runs.
#
# The cross-court joke is real and not a joke: "how many negative
# certificates does the kernel court hold?" is a question about TEXT, and
# Lean cannot ask it of itself (a rejection-capture is existential, and
# the *population* of captures is not a Lean proposition either). The
# census court can. So the instrument that audits the kernel court's
# negative space is a Julia script — each court checking the other's
# books, which is the only arrangement in which either count is worth
# anything.
#
# THREE ERRATA IT MEASURES, all mine except (C):
#
#   (A) COUNT. RejectionCapture.lean's header says "(Expressibility.lean,
#       14 of them)". 14 is the number of LINES MENTIONING `#guard_msgs`,
#       which includes prose that talks about the instrument. The number
#       of USES is 12. I counted mentions and reported uses.
#
#   (B) CHARACTER. I called all of them "the ecosystem's only NEGATIVE
#       certificate". Only the error-pins are negative certificates; an
#       `info:` pin is an ordinary output regression test, positive in
#       exactly the way the rest of the suite is. 8 negative, 4 positive.
#       So the negative-certificate count I published was 14; it is 8.
#
#   (C) TALLY. The PR body advertises "91 entries — 53 THEOREM, 15
#       VERIFIED, 4 DEMO, 3 GUARDED, 16 NOTE". `lake exe paradoxes` on
#       the merged tree prints "91 — 50 THEOREM, 3 IDENTITY, 15 VERIFIED,
#       4 DEMO, 3 GUARDED, 16 NOTE". The total agrees; the breakdown does
#       not. Three entries were reclassified THEOREM → IDENTITY in-tree
#       and the advertisement kept the pre-reclassification number.
#       Note the DIRECTION: the ledger got stricter and the abstract
#       lagged. This thread's standing failure mode is narration
#       outrunning the formal object; here the object outran the
#       narration. Same seam, opposite sign — and the second kind is
#       harder to catch, because nobody re-reads an abstract to check
#       whether it has become too generous by standing still.
#
# AND ONE FINDING THAT CORRECTS ME IN THE AUDITED PARTY'S FAVOUR:
#
#   (D) PAIRING. `RejectionCapture.lean` amends Finding A with clause (4)
#       (a capture must ship a minimally different ACCEPTANCE) and credits
#       the negation-census instance for a move "I had missed" — framing
#       it as absent from the audited artifact. It is not absent. It is
#       the file's dominant idiom: 5 of the 8 refusals ship an accepted or
#       refuted twin. What is true, and sharper than what I published, is
#       WHICH THREE DO NOT — measured below.
#
# PREDICTIONS (registered before the run, house rule):
#   P34. uses == 12, mentions == 14.
#   P35. error-pins == 8, info-pins == 4.
#   P36. The unpaired refusals are exactly the two kernel-positivity
#        captures plus the universe one — i.e. Finding A's shared-verdict
#        cases are precisely the cases clause (4) is unsatisfied. If P36
#        holds, Finding A and clause (4) are not two findings but one.
#   Controls: C7 the pairing test must REJECT a fabricated twin name;
#             C8 the census must FAIL if the source file is absent, rather
#                than reporting a confident zero.
# ======================================================================

const SRC = joinpath(@__DIR__, "Paradoxes", "Expressibility.lean")

exitcode = 0
fail(m) = (global exitcode = 1; println("  ✗ FAIL: ", m))
pass(m) = println("  ✓ ", m)
section(t) = println("\n── ", t, " ", "─"^max(0, 58 - length(t)))

# ── C8 first: absence must be loud, not a confident zero ──────────────
if !isfile(SRC)
    println("✗ FAIL: ", SRC, " not found — census cannot report a count it did not take.")
    exit(1)
end
lines = readlines(SRC)

# ── the two counts that differ ────────────────────────────────────────
section("A · uses vs mentions")
mentions = count(l -> occursin("#guard_msgs", l), lines)
uses     = count(l -> startswith(strip(l), "#guard_msgs"), lines)
println("  lines mentioning #guard_msgs : ", mentions)
println("  actual uses (line-initial)   : ", uses)
(mentions == 14 && uses == 12) ? pass("P34 holds — the published 14 was a mention count") :
    fail("P34: expected mentions=14 uses=12, got $mentions/$uses")

# ── pin classification: which captures are actually negative? ─────────
"""
For the `#guard_msgs` at line `i`, walk back to the docstring immediately
above it and return (:error | :info | :warning | :unpinned, message).
"""
function pin(lines, i)
    j = i - 1
    while j >= 1 && !endswith(strip(lines[j]), "-/"); j -= 1; end
    j < 1 && return (:unpinned, "")
    e = j
    while j >= 1 && !startswith(strip(lines[j]), "/--"); j -= 1; end
    j < 1 && return (:unpinned, "")
    doc = join(strip.(lines[j:e]), " ")
    m = match(r"\b(error|warning|info)\s*:\s*(.*)", doc)
    m === nothing ? (:unpinned, "") : (Symbol(m.captures[1]), String(m.captures[2]))
end

guards = findall(l -> startswith(strip(l), "#guard_msgs"), lines)
pins   = [pin(lines, i) for i in guards]

section("B · negative certificates vs output pins")
nerr  = count(p -> p[1] === :error, pins)
ninfo = count(p -> p[1] === :info,  pins)
println("  error-pins (refusals, NEGATIVE certificates) : ", nerr)
println("  info-pins  (output regressions, POSITIVE)    : ", ninfo)
(nerr == 8 && ninfo == 4) ? pass("P35 holds — 8 negative, not the 14 I published") :
    fail("P35: expected 8 error / 4 info, got $nerr/$ninfo")

# ── D · which refusals locate their boundary? ─────────────────────────
# A refusal is PAIRED if the file also ships a minimally different
# declaration that is ACCEPTED (or a theorem refuting the refused
# equation outright — strictly stronger, since it converts "cannot be
# written" into "is false").
section("D · clause (4): which refusals ship a twin?")

accepted(name) = any(l -> occursin(Regex("^\\s*(partial |noncomputable )?(def|theorem|abbrev) " *
                                          name * "\\b"), l), lines)

# twin registry: refused declaration → the accepted/refuting declaration
twins = Dict(
    "inductive Liar"                => nothing,          # positivity, unpaired
    "def liar : Prop"               => "liarFuel",       # add fuel → accepted
    "partial def liarBool"          => "liarRun",        # add Unit → → accepted
    "example : liarRun"             => "liarRun_ne",     # equation REFUTED
    "inductive C"                   => nothing,          # positivity, unpaired
    "def U : Type"                  => nothing,          # universe, unpaired
    "#eval chosenBool"              => "chosenBool_dichotomy",
)

paired, unpaired = String[], String[]
for (i, p) in zip(guards, pins)
    p[1] === :error || continue
    decl = strip(lines[i+1])
    key  = findfirst(k -> startswith(decl, k), collect(keys(twins)))
    k    = key === nothing ? nothing : collect(keys(twins))[key]
    twin = k === nothing ? nothing : twins[k]
    if twin !== nothing && accepted(twin)
        push!(paired, "L$(i): $(first(decl, 34))…  ↔  $twin")
    else
        push!(unpaired, "L$(i): $(first(decl, 34))")
    end
end
println("  PAIRED (boundary located):")
foreach(t -> println("    ", t), paired)
println("  UNPAIRED (refusal class only):")
foreach(t -> println("    ", t), unpaired)

length(paired) == 5 ?
    pass("5 of 8 refusals already ship a twin — the discipline predates my rule") :
    fail("expected 5 paired, got $(length(paired))")

# P36: are the unpaired ones exactly the shared-verdict cases?
positivity = count(p -> p[1] === :error && occursin("non positive occurrence", p[2]), pins)
unpaired_positivity = count(u -> occursin("inductive", u), unpaired)
if positivity == 2 && unpaired_positivity == 2 && length(unpaired) == 3
    pass("P36 holds — both shared-verdict (positivity) captures are unpaired,")
    println("       plus the universe one. Finding A and clause (4) are ONE finding:")
    println("       a capture is indistinguishable from its neighbours exactly when")
    println("       it has no twin to be distinguished FROM.")
else
    fail("P36: positivity=$positivity unpaired_pos=$unpaired_positivity unpaired=$(length(unpaired))")
end

# ── C7 · the pairing test must be able to say no ──────────────────────
section("controls")
accepted("liarFuel") ? pass("C7a: real twin `liarFuel` detected") :
                       fail("C7a: failed to detect a declaration that is present")
accepted("liarFuelNonexistentTwin") ? fail("C7b: accepted a fabricated twin name") :
                                      pass("C7b: fabricated twin rejected")

# ── verdict ───────────────────────────────────────────────────────────
section("verdict")
println("""
  The kernel court holds 8 negative certificates, not 14. Five of them
  locate their own boundary; three pin a refusal CLASS with nothing to
  contrast against, and those three are exactly where the verdict text
  stops discriminating (two share one positivity message verbatim).

  So the amended house rule collapses by one clause. Clause (4) is not an
  extra hurdle beside Finding A — it is Finding A's remedy, and the file
  already applies it everywhere the remedy is available. What I filed as
  a missing discipline was a present discipline with three gaps, and I
  found the gaps only after counting instead of quoting.

  The instrument that caught all of this is not clever. It is a script
  that opens the file. Every number I got wrong, I got wrong by citing a
  count I had taken once, by eye, from a diff — and then reusing it in
  the very document arguing that certificates must be harvested rather
  than remembered. The rule was right and its author was the fixture.""")

println("\nexit ", exitcode, " — evidence, never proof.")
exit(exitcode)
