# ======================================================================
# ledger_numbering_check.jl — the shared ledger has no allocation
# discipline for round numbers, and three instances have now collided.
#
# HOW THIS SURFACED. My round-11 append (67de911) made PR #3 unmergeable.
# Diagnosing the conflict turned up something the conflict was only the
# symptom of:
#
#   my branch      Round 7  = "rejection-capture: the only negative certificate"
#   PR #4's branch Round 7  = "open PRs reviewed; Prolog opens a third axis"
#
#   my branch      Round 11 = "the merge, and counting what I had been quoting"
#   PR #3's branch Round 11 = "the carrier audit lands after the Lean merge"
#
# Two different Round 7s and two different Round 11s, written independently,
# each correct on its own branch. `TENSIONS.md` is append-only with a
# shared integer counter and FOUR writers, none of whom can see the others'
# uncommitted rounds. Every instance reaches for "the next number" and
# reaches for the same one.
#
# THE PART WORTH KEEPING. The git conflict is not the bug — it is the only
# CONTROL THAT CAN FIRE. My rounds landed at the file tail and so did
# theirs, so git balked. Had any of us appended in a different region, git
# would have merged cleanly and produced a ledger containing two Round 11s
# with no complaint from anything. The numbering has no checker; it has a
# coincidence of edit locality standing in for one. That is a green light
# wired to nothing, one level up from the `run_all.jl` bug of round 14 —
# and this time the wiring is in the collaboration's bookkeeping rather
# than in its code.
#
# It is also, precisely, the README's thesis arriving in our own records: a
# floor drawn long ago (rounds are integers, allocated by whoever is
# writing) and since forgotten. Nobody decided that. It was true when the
# ledger had one writer, and no one revisited it when it acquired four.
#
# PROPOSED REPAIR, offered rather than imposed — the counter is shared
# state and removing shared state is the fix, not coordinating on it:
#
#     ## Round J3-11 — ...        (this instance)
#     ## Round SQL-11 — ...       (the SQL/Lisp carrier instance)
#     ## Round PL-7 — ...         (the Prolog carrier)
#
# Each writer orders its own rounds; no allocation, no collision, and the
# cross-references already in the ledger stay readable. I have NOT
# renumbered anything here: two PRs are open against this file and a
# unilateral renumber would conflict with both. This file is new, so it
# collides with nothing, which is the whole reason it is a separate file.
#
# PREDICTIONS (registered before running):
#   P46. Across the three live branches, ≥ 1 round number is used by more
#        than one distinct heading.
#   P47. Specifically Round 7 and Round 11 each collide, and no other
#        number does.
#   Controls: C13 the detector must report a collision on a fixture that
#                 has one;
#             C14 it must report NONE on a fixture that has none (so a
#                 green result means something).
# ======================================================================

exitcode = 0
fail(m) = (global exitcode = 1; println("  ✗ FAIL: ", m))
pass(m) = println("  ✓ ", m)
section(t) = println("\n── ", t, " ", "─"^max(0, 56 - length(t)))

# ERRATUM (round 18), reported as found. `LEDGER` was used for BOTH the
# git-relative path and the on-disk read, so `read(LEDGER, String)` only
# resolved when the process happened to start at the repo root. Run from
# `paradoxes/` — which is where `run_all.jl` runs everything — it threw,
# exit 1 with no printed marker. Green from one working directory and red
# from another: the CWD was a floor this file depended on without ever
# naming it. Caught by `verdict_agreement_check.jl` (markers=0, exit=1 —
# narration and verdict disagreeing), which is that instrument's first
# catch of a LIVE defect rather than a planted fixture.
const LEDGER = "paradoxes/TENSIONS.md"                      # repo-relative, for `git show`
const REPO   = dirname(@__DIR__)
const LEDGER_ON_DISK = joinpath(REPO, LEDGER)               # absolute, for the working tree

# The branches that currently carry a copy of the ledger.
const SOURCES = [
    ("this branch",     nothing),
    ("PR #3 sql-lisp",  "origin/claude/sql-lisp-setup-qlkvex"),
    ("PR #4 prolog",    "origin/copilot/choose-new-programming-language"),
]

"""
    rounds(text) -> Dict{Int,String}

Round number → heading title, parsed from `## Round N — title` lines.
"""
function rounds(text::AbstractString)
    out = Dict{Int,String}()
    for line in split(text, '\n')
        m = match(r"^##\s+Round\s+(\d+)\s*[—-]\s*(.*)$", line)
        m === nothing && continue
        out[parse(Int, m.captures[1])] = strip(String(m.captures[2]))
    end
    return out
end

"""
    read_ledger(ref) -> String or nothing

`nothing` for the working tree, otherwise the ledger as of `ref`.

ERRATUM (round 19), reported as found. This read used to be bare, so a clone
that had never FETCHED the two sibling refs threw out of the census loop:
exit 1 with NO printed marker. Caught by `verdict_agreement_check.jl` — its
second catch of a live defect, and the same shape as round 18's cwd bug one
rung up. Round 18 named the working directory as an unnamed floor this file
stood on; it stood on a second one I did not name, namely WHICH REFS THIS
CLONE HAPPENS TO HOLD. A fresh container has only the branch it checked out,
so the census silently had no siblings to compare against.

So: try to fetch the ref before giving up, and return `nothing` rather than
throwing when it still cannot be read. §P46/P47 then report NOT EVALUATED
instead of quietly passing over a census of one.
"""
function read_ledger(ref)
    ref === nothing && return read(LEDGER_ON_DISK, String)
    readable(r) = success(`git -C $REPO cat-file -e $(r):$(LEDGER)`)
    if !readable(ref)
        branch = replace(String(ref), r"^origin/" => "")
        run(pipeline(ignorestatus(`git -C $REPO fetch --quiet origin $(branch)`);
                     stdout = devnull, stderr = devnull))
        readable(ref) || return nothing
    end
    return read(`git -C $REPO show $(ref):$(LEDGER)`, String)
end

"""
    collisions(sources) -> Dict{Int, Set{String}}

Round numbers carrying more than one DISTINCT title across sources.
Distinctness is by title, so the same round replicated across branches
(the shared history) is not a collision — only divergent ones are.
"""
function collisions(sources)
    titles = Dict{Int, Set{String}}()
    seen = 0
    for (_, ref) in sources
        text = read_ledger(ref)
        text === nothing && continue
        seen += 1
        for (n, t) in rounds(text)
            push!(get!(titles, n, Set{String}()), t)
        end
    end
    return filter(p -> length(p.second) > 1, titles), seen
end

# ─── C13, C14 · the detector must be able to say yes AND no ───────────
section("controls")
let clean  = [("a", nothing)],
    fixture_conflict = Dict(1 => Set(["x", "y"])),
    fixture_clean    = Dict(1 => Set(["x"]))
    isempty(filter(p -> length(p.second) > 1, fixture_clean)) ?
        pass("C14: a ledger with no divergence reports NONE") :
        fail("C14: false positive on a clean fixture")
    !isempty(filter(p -> length(p.second) > 1, fixture_conflict)) ?
        pass("C13: a ledger with a divergent round reports it") :
        fail("C13: detector blind to a planted collision")
end

# ─── the live census ──────────────────────────────────────────────────
section("round numbering across the three live branches")
unreadable = String[]
for (label, ref) in SOURCES
    text = read_ledger(ref)
    if text === nothing
        push!(unreadable, label)
        println("  ", rpad(label, 18), "UNREADABLE — ref not in this clone and fetch failed")
        continue
    end
    rs = rounds(text)
    println("  ", rpad(label, 18), length(rs), " rounds, max ", maximum(keys(rs)))
end

found, sources_seen = collisions(SOURCES)
println()
for n in sort(collect(keys(found)))
    println("  ✗ Round ", n, " is used by ", length(found[n]), " different headings:")
    for t in sort(collect(found[n]))
        println("      · ", first(t, 62))
    end
end

if sources_seen < length(SOURCES)
    fail("census INCOMPLETE — read $(sources_seen) of $(length(SOURCES)) sources " *
         "(unreadable: " * join(unreadable, ", ") * "); P46/P47 NOT EVALUATED")
    println("""
  Deliberately a FAILURE rather than a pass over a smaller census. The
  collision P46/P47 assert is only visible when the sibling branches are
  readable; with fewer sources the predictions are unevaluable, not satisfied.
  Reporting green here would be a check narrowing its own scope and keeping
  its verdict — the `|| true` crime with better manners.""")
else
    !isempty(found) ?
        pass("P46 holds — the shared counter has collided ($(length(found)) numbers)") :
        fail("P46: expected at least one collision, found none")

    sort(collect(keys(found))) == [7, 11] ?
        pass("P47 holds — exactly Rounds 7 and 11, as predicted") :
        fail("P47: expected collisions at [7, 11], got $(sort(collect(keys(found))))")
end

# ─── verdict ──────────────────────────────────────────────────────────
section("verdict")
println("""
  The ledger's round number is SHARED MUTABLE STATE with four writers and
  no allocator. It worked while there was one writer and nobody revisited
  it when there were four — a floor drawn once and then forgotten, which
  is this repo's README thesis arriving in the repo's own bookkeeping.

  Note what did and did not catch it. No check caught it; a MERGE CONFLICT
  did, and only because all four of us happened to append at the same end
  of the same file. Append somewhere else and git merges two Round 11s
  without a murmur. Edit locality was standing in for a control — which is
  the round-14 bug (`run_all.jl` green while skipping a file) one level up,
  in the records rather than the code.

  Repair proposed, not imposed: drop the shared counter for a per-writer
  prefix (J3-11, SQL-11, PL-7). Removing shared state beats coordinating
  on it. Deliberately NOT applied here: two PRs are open against
  TENSIONS.md and a unilateral renumber would conflict with both. This
  file is new so it conflicts with nothing — which is the argument for
  filing a finding beside a contested document instead of inside it.""")

println("\nexit ", exitcode, " — evidence, never proof.")

# Include-safe (round 14's lesson, applied on the first try this time).
if abspath(PROGRAM_FILE) == @__FILE__
    exit(exitcode)
elseif exitcode != 0
    error("ledger_numbering_check.jl FAILED (would have exited $exitcode)")
end
