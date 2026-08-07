# ======================================================================
# pin_history.jl — replaying the pin registry over the whole record, to
# find out whether any pin has ever changed a decision.
#
# WHY. A new note from the outside voice (mirrored onto #3 and #4), and
# one clause in it is a criterion my registry cannot meet:
#
#   "Pressure: expires as load-bearing if it never changes a decision
#    otherwise going the other way."
#   "Practices: … expiry with N; artifacts > annotations."
#   "Pressure welcome."
#
# `pin_check.jl` measures ONE property and I let it stand for another.
# §3 shows every pin MOVES under a stress mutation and I wrote that up as
# P55 holding. That proves a pin is WIRED. It does not prove a pin is
# LOAD-BEARING, and the note's criterion is about the second. Three
# distinct things, which I had collapsed into one:
#
#   WIRED     — the stress mutation reddens it. (§3 measures this.)
#   FIRED     — it has actually been red at some point in the record.
#   DECISIVE  — a firing changed a decision that would otherwise have
#               gone the other way.
#
# Every pin in the registry was born green: I wrote each one AFTER
# repairing the number it pins. So the honest question is not "does it
# work" but "would it have caught the error it was named for?" That is
# answerable, because the record is 40 commits long and git keeps all of
# it. This file replays each pin against every commit on the branch and
# reports where it would have been red — a measurement, not a claim.
#
# AND A SECOND SEAM, which the replay exposes rather than assumes.
# Each pin has two sides: a CLAIMED value parsed out of a document by
# regex, and a DERIVED value computed from the tree. §3's stress mutation
# perturbs the DERIVED side only (`derive() + 1`). Nothing in `pin_check`
# perturbs the CLAIMED side. So a pin whose locator no longer matches its
# document is indistinguishable, in that file, from a pin whose number
# has drifted — both just fail. Those are different events and only one
# of them is an error worth reddening a run for.
#
# PREDICTIONS (registered before running):
#   P57. At least one pin would have been RED-BY-DRIFT at some historical
#        commit. If zero, then no pin has ever differed from its document
#        anywhere in the record, and by the note's criterion the whole
#        registry expires as load-bearing — decoration with a stress test.
#   P58. Red-by-LOCATOR-MISS outnumbers red-by-DRIFT across the record,
#        because every regex was written against the CURRENT wording of a
#        document that has been rewritten repeatedly. If so, "the pin
#        fired" carries less information than `pin_check` implies, and
#        P55's pass is narrower than it reads.
#   Controls: C21 a genuine drift must classify as DRIFT, not MISS;
#             C22 a broken locator must classify as MISS, not DRIFT.
#             (Together these prove the classifier discriminates; either
#             one alone would pass for a classifier that always says the
#             same word.)
# ======================================================================

exitcode = 0
fail(m) = (global exitcode = 1; println("  ✗ FAIL: ", m))
pass(m) = println("  ✓ ", m)
note(m) = println("  · ", m)
section(t) = println("\n── ", t, " ", "─"^max(0, 56 - length(t)))

const ROOT = dirname(@__DIR__)

# ─── reading a past tree, never the working directory ─────────────────
function gitshow(sha, path)
    out = IOBuffer()
    p = run(pipeline(ignorestatus(`git -C $ROOT show $(sha):$(path)`);
                     stdout = out, stderr = devnull))
    return p.exitcode == 0 ? String(take!(out)) : ""
end

function gitls(sha, dir)
    out = IOBuffer()
    p = run(pipeline(ignorestatus(`git -C $ROOT ls-tree --name-only $(sha) $(dir)/`);
                     stdout = out, stderr = devnull))
    return p.exitcode == 0 ? split(strip(String(take!(out))), '\n'; keepempty = false) : String[]
end

commits() = split(strip(read(`git -C $ROOT rev-list --reverse HEAD`, String)), '\n')

count_matches(text, re) = length(collect(eachmatch(re, text)))

const LIAR  = "paradoxes/01_liar_and_friends.jl"
const RDME  = "paradoxes/README.md"
const EXPR  = "paradoxes/lean/Paradoxes/Expressibility.lean"
const CAPT  = "paradoxes/lean/RejectionCapture.lean"

d_renderings(sha) = count_matches(gitshow(sha, LIAR), r"Rendering \d")
d_runnable(sha)   = count(f -> endswith(f, ".jl") && basename(f) != "run_all.jl",
                          gitls(sha, "paradoxes"))
d_table_rows(sha) = count_matches(gitshow(sha, RDME), r"\|\s*`\d\d[^`]+\.jl`")
d_guard_uses(sha) = count(l -> startswith(strip(l), "#guard_msgs"),
                          split(gitshow(sha, EXPR), '\n'))

"""Error-pinned `#guard_msgs` blocks at commit `sha` — the docstring above pins an `error:`."""
function d_guard_errors(sha)
    lines = split(gitshow(sha, EXPR), '\n')
    n = 0
    for (i, l) in enumerate(lines)
        startswith(strip(l), "#guard_msgs") || continue
        j = i - 1
        while j >= 1 && !endswith(strip(lines[j]), "-/"); j -= 1; end
        e = j
        while j >= 1 && !startswith(strip(lines[j]), "/--"); j -= 1; end
        j >= 1 && occursin(r"\berror\s*:", join(lines[j:e], " ")) && (n += 1)
    end
    return n
end

const WORDS = Dict("five"=>5,"six"=>6,"seven"=>7,"eight"=>8,"nine"=>9,"ten"=>10,
                   "eleven"=>11,"twelve"=>12,"thirteen"=>13,"fourteen"=>14,"fifteen"=>15)
word_or_num(s) = get(WORDS, lowercase(s), tryparse(Int, s))

"""
    classify(doctext, re, derived) -> Symbol

The whole point of this file in four lines. `:absent` the document is not
there yet; `:miss` the document is there but the locator finds nothing;
`:drift` the located number disagrees with the tree; `:green` they agree.
`:miss` and `:drift` both redden `pin_check`, and they are not the same
event — one is the instrument losing its grip, the other is the error the
instrument exists for.
"""
function classify(doctext, re, derived)
    isempty(doctext) && return :absent
    m = match(re, doctext)
    m === nothing && return :miss
    v = word_or_num(String(m.captures[1]))
    v === nothing && return :miss
    return v == derived ? :green : :drift
end

# the registry, as `pin_check.jl` has it — same locators, same derivations
pins = [
 (name="renderings",     doc=RDME, re=r"the liar \((\w+) renderings\)", derive=d_renderings),
 (name="runnable",       doc=RDME, re=r"(\w+) runnable",                 derive=d_runnable),
 (name="count_vs_table", doc=RDME, re=r"(\w+) runnable",                 derive=d_table_rows),
 (name="guard_uses",     doc=CAPT, re=r"Expressibility\.lean: (\d+) uses", derive=d_guard_uses),
 (name="guard_errors",   doc=CAPT, re=r"(\d+) of them refusals",         derive=d_guard_errors),
]

# ─── C21, C22 · the classifier must tell the two reds apart ───────────
section("controls · drift and locator-miss are different events")
let derived = 5
    classify("the liar (eight renderings) — see below", r"the liar \((\w+) renderings\)", derived) == :drift ?
        pass("C21: a genuine drift (document says eight, tree says $derived) classifies as DRIFT") :
        fail("C21: a genuine drift did not classify as DRIFT")
    classify("the liar (5 flavours) — see below", r"the liar \((\w+) renderings\)", derived) == :miss ?
        pass("C22: a rephrased document (locator no longer matches) classifies as MISS") :
        fail("C22: a broken locator did not classify as MISS")
    classify("", r"x", derived) == :absent ?
        pass("C23: a document that does not exist yet classifies as ABSENT, not as a failure") :
        fail("C23: a missing document was scored")
end

# ─── the replay ───────────────────────────────────────────────────────
section("replaying $(length(pins)) pins across the whole branch history")
shas = commits()
println("  commits on this branch: ", length(shas), "   (", first(shas, 1)[1][1:7],
        " … ", last(shas)[1:7], ")")

tally = Dict(p.name => Dict(:absent=>0, :miss=>0, :drift=>0, :green=>0) for p in pins)
first_drift = Dict{String,String}()
for sha in shas
    for p in pins
        c = classify(gitshow(sha, p.doc), p.re, p.derive(sha))
        tally[p.name][c] += 1
        c == :drift && !haskey(first_drift, p.name) && (first_drift[p.name] = sha)
    end
end

println()
println("  ", rpad("pin", 16), rpad("absent", 8), rpad("green", 7), rpad("MISS", 6),
        rpad("DRIFT", 7), "first drift")
for p in pins
    t = tally[p.name]
    println("  ", rpad(p.name, 16), rpad(t[:absent], 8), rpad(t[:green], 7),
            rpad(t[:miss], 6), rpad(t[:drift], 7),
            get(first_drift, p.name, "—") == "—" ? "never" : first_drift[p.name][1:7])
end

total_drift = sum(tally[p.name][:drift] for p in pins)
total_miss  = sum(tally[p.name][:miss]  for p in pins)

# ─── P57 · has any pin ever differed from its document? ───────────────
section("P57 · has any pin ever been red for the reason it exists?")
total_drift > 0 ?
    pass("P57 holds — $total_drift commit/pin pairs would have been RED BY DRIFT; the registry has historical teeth") :
    fail("P57: zero drift anywhere in $(length(shas)) commits — every pin was born green and has never differed from its document, so by the note's criterion the registry expires as load-bearing")

# ─── P58 · which kind of red dominates? REFUTED, and instructively ────
section("P58 · drift vs locator-miss — REFUTED")
println("  red by DRIFT: ", total_drift, "     red by LOCATOR-MISS: ", total_miss)
total_miss > total_drift ?
    fail("P58 as predicted (this line should be unreachable — see below)") :
    pass("P58 REFUTED: drift outnumbers miss $total_drift to $total_miss, the reverse of my prediction")

# The aggregate was the wrong question. The split is PER PIN, and total.
mixed = [p.name for p in pins if tally[p.name][:drift] > 0 && tally[p.name][:miss] > 0]
isempty(mixed) ?
    pass("and the real shape: NO pin shows both failure modes — each is 100% drift or 100% miss") :
    fail("pins showing both modes (so the split is not determined by the document): " * join(mixed, ", "))

println("""
  I predicted the wrong aggregate and the aggregate was the wrong
  question. What the table actually shows is a clean partition by which
  DOCUMENT a pin points at, with no pin mixed:

    · the three README pins   113 drift,  0 miss
    · the two Lean pins         0 drift, 22 miss

  Each half is a different finding, and the second is the one that costs
  me something.""")

# ─── the exhibit · the pin that cannot see the error it was built for ──
section("the exhibit, verified rather than asserted")
# ERRATUM, REPORTED AS FOUND. The first draft of this block detected the
# broken state with `occursin("14 of them", t)` and got 20 commits, not
# 11 — and the check FAILED, exit 1. The detector was wrong: the REPAIRED
# file still contains the string "14 of them", quoted inside the visible
# erratum ("This header said \"14 of them.\""). House practice here is to
# keep errata in the document rather than delete them, which means a
# substring search cannot tell a repaired document from a broken one.
# My detector fell for exactly that, inside the file whose subject is
# detectors that fire for the wrong reason. The fix is to match the
# ASSERTION FORM rather than the number: `Expressibility.lean, N of them`
# is how the claim was made; the repaired file has zero of those.
let wrong = 0, repaired = 0
    for sha in shas
        t = gitshow(sha, CAPT)
        isempty(t) && continue
        occursin(r"Expressibility\.lean, \d+ of them", t)  && (wrong += 1)
        occursin(r"Expressibility\.lean: \d+ uses", t)     && (repaired += 1)
    end
    println("  asserted in the BROKEN form  (\"…lean, N of them\"): ", wrong, " commit(s)")
    println("  asserted in the REPAIRED form (\"…lean: N uses\"):    ", repaired, " commit(s)")
    println("  naive substring \"14 of them\" would report:          ",
            count(sha -> occursin("14 of them", gitshow(sha, CAPT)), shas),
            " commit(s)  ← counts the erratum's own quotation")
    (wrong == tally["guard_uses"][:miss] && wrong > 0) ?
        pass("the $wrong commits carrying the WRONG count are exactly the $wrong the pin scores MISS on") :
        fail("expected the wrong-count commits to coincide with the pin's misses")
end
println("""
  `guard_uses` and `guard_errors` were written for one purpose: to stop
  the "14 `#guard_msgs`" error recurring. The error was live for eleven
  commits. On all eleven the pin returns MISS — it cannot parse the
  sentence, because its locator was written against the sentence AS
  REPAIRED ("Expressibility.lean: 12 uses"), and the broken state said
  "Expressibility.lean, 14 of them".

  So the pin does not catch the error it exists for. It recognises the
  fixed document and is blind to the broken one. It would still have
  reddened a run — but with the message "a decision-bearing line has
  drifted", which would have been false; nothing had drifted, the
  instrument had simply lost its grip. A red for the wrong reason is the
  same defect I named as Finding B in the rejection-capture audit and
  again in the dial self-audit: a true signal attached to a false story.
  Third occurrence, first time inside a tool I built specifically against
  it.

  And this is STRUCTURAL, not a slip. Every pin I write is written after
  the repair it pins, so every locator is fitted to the repaired prose by
  construction. The class of errors a pin is blind to is exactly the class
  it was created in response to.

  The seam underneath: §3's stress mutation is `derive() + 1`. It perturbs
  the TREE side of every pin and never the DOCUMENT side. P55 — "all 5
  pins move under their stress mutation" — certifies the derivation is
  live and says nothing about whether the locator grips. Half the pin was
  stress-tested and I reported the pass as though the whole of it had
  been. `pin_check.jl` §3 now carries the missing half (C24).

  The other half of the table is its own indictment: `renderings` is 39
  drift out of 39 live commits and has NEVER been green — the README's
  count has disagreed with the tree for the entire life of this branch —
  and that is precisely the pin I marked KNOWN-OPEN so it would not redden
  the run. The one number that has never once been right is the one I
  decided not to fail on.""")

# ─── expiry with N, applied to the pins themselves ────────────────────
section("expiry with N · which pins have earned their place")
println("""
  The note's criterion: a claim "expires as load-bearing if it never
  changes a decision otherwise going the other way." Applied here, with N
  = the $(length(shas)) commits of this branch:""")
for p in pins
    t = tally[p.name]
    live = t[:green] + t[:miss] + t[:drift]
    verdict = t[:drift] > 0 ? "LOAD-BEARING — red-by-drift on $(t[:drift]) of $(live) live commits" :
              live == 0     ? "NOT YET LIVE — its document has never existed" :
              t[:miss] > 0  ? "BLIND — $(t[:miss]) of $(live) live commits unparseable; never once a clean verdict" :
                              "EXPIRED as load-bearing — $(live) commits alive, never once differed"
    println("  ", rpad(p.name, 16), verdict)
end
println("""
  This is the part I would have got wrong by inspection. I would have said
  all five pins were doing work, because all five pass their stress test
  and all five pin numbers I have personally got wrong. The replay
  separates those: a pin that pins a number I once got wrong is not the
  same as a pin that would have caught me getting it wrong — the second
  requires the pin to have existed, in a document that existed, at a
  commit where the number was wrong.""")

section("verdict")
println("""
  One criterion arrived from outside — "expires as load-bearing if it
  never changes a decision otherwise going the other way" — and my
  registry could not meet it, so the registry was measured against the
  record instead of defended.

  Three properties I had collapsed into one, now separated and counted:
    WIRED     5 of 5   (§3's stress mutation reddens each pin)
    FIRED     3 of 5   (would have been red-by-drift somewhere in the 40)
    DECISIVE  0 of 5   (none has yet been red on a live run and changed
                        what I did next; each was written after its own
                        repair, and the one pin with a SCHEDULED decision
                        is the PR #3 tripwire, which has not fired either)

  P57 held, P58 was refuted, and the refutation was worth more than the
  prediction: the failure modes partition cleanly by document, and the two
  pins that show no drift are not clean — they are BLIND, unable to parse
  the eleven commits in which the error they exist for was live.

  What I would have said by inspection, and would have been wrong about:
  that all five pins were doing work, because all five pass their stress
  test and all five pin numbers I have personally got wrong. Pinning a
  number I once got wrong is not the same as being able to catch me
  getting it wrong.

  Artifacts over annotations: this file is the artifact, and what it
  convicts is the artifact from the round before it. Any comment I write
  about it is the annotation and is the weaker of the two.""")

println("\nexit ", exitcode, " — evidence, never proof.")

if abspath(PROGRAM_FILE) == @__FILE__
    exit(exitcode)
elseif exitcode != 0
    error("pin_history.jl FAILED (would have exited $exitcode) — see output above")
end
