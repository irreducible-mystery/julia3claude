# ======================================================================
# verdict_agreement_check.jl — does the narration agree with the verdict?
#
# WHY. An outside voice on julia2#5 made the sharpest claim anyone has
# made about this work, and it lands:
#
#   "A system can agree that its checks are frame commitments and still
#    generate the next move as if the present checks report the world.
#    The theoretical acknowledgment stays sealed off from the generative
#    process."
#
# I have three receipts for that from a single day:
#   · `capture_census.jl` argues certificates must be HARVESTED, not
#     remembered — and hours later I handed PR #3 a hand-computed file
#     count that my own next commit made stale.
#   · `11_there_is_no_fifth.jl` says "a wall named as a cell is a floor
#     you have stopped seeing" — and drew the walls in the wrong place.
#   · `10_orbit_shapes.jl` and `11_…` argue a control must be able to
#     fire — and both ended in a bare `exit()` that silenced the file
#     after them.
#
# Each time the principle was stated and the next move was generated as
# if the principle were already operating. Annotation, not propagation.
#
# Their remedy, in their words: "make the cut visible by making its
# consequences MEASURABLE, not by annotating that a cut occurred."
# An erratum is an annotation. This file is the measurement.
#
# WHAT IT MEASURES, exactly one thing: for every suite file that has a
# failure channel, the printed FAILURE MARKERS and the EXIT CODE must
# agree. A `✗ FAIL` with exit 0 is prose overruling the verdict — the
# precise sin committed once already in `rejection_capture_census.jl`
# (a printed ✗ that never moved the exit code) and once in round 12
# (a verdict line reading "P37-P41 hold" while P40 had failed).
#
# WHAT IT DOES NOT MEASURE, said plainly rather than implied away:
# whether the PROSE conclusion is true. "All predictions hold" printed
# above a genuine failure would be caught only because the ✗ moves the
# code; a file that quietly declines to print ✗ at all is invisible
# here. This check closes the marker/exit-code seam. The prose/result
# seam stays open, and I do not have a mechanization for it — which is
# itself the honest report, since the note above is precisely about
# claiming more coverage than the instrument has.
#
# PREDICTIONS (registered before running):
#   P51. All four channel-carrying files agree: markers ⇔ exit code.
#   P52. The fossil files (01–08) carry no channel at all, so they are
#        vacuously consistent and the check must SAY SO rather than
#        counting them as evidence.
#   Controls: C17 a fixture printing ✗ FAIL and exiting 0 must be CAUGHT;
#             C18 a clean fixture must PASS (no false positive).
# ======================================================================

exitcode = 0
fail(m) = (global exitcode = 1; println("  ✗ FAIL: ", m))
pass(m) = println("  ✓ ", m)
section(t) = println("\n── ", t, " ", "─"^max(0, 56 - length(t)))

const HERE = @__DIR__
const MARKER = "✗ FAIL"

"""
    verdict(path) -> (markers::Int, code::Int)

Run `path` as its own process; count printed failure markers and read
the exit code. Both come from the RUN, never from reading the source.
"""
function verdict(path)
    out = IOBuffer()
    p = run(pipeline(ignorestatus(`julia $path`); stdout = out, stderr = devnull))
    text = String(take!(out))
    return (count(_ -> true, eachmatch(Regex(MARKER), text)), p.exitcode)
end

# ─── C17, C18 · the check must be able to catch and to clear ──────────
section("controls · a fixture that lies, and one that does not")
mktempdir() do dir
    liar = joinpath(dir, "liar_fixture.jl")
    write(liar, """
        println("  $MARKER: this fixture reports a failure")
        exit(0)   # ...and exits green anyway
        """)
    m, c = verdict(liar)
    (m > 0 && c == 0) ? pass("C17: caught it — $m marker(s), exit $c (prose overruling verdict)") :
                        fail("C17: the check did not catch a planted marker/exit disagreement")

    clean = joinpath(dir, "clean_fixture.jl")
    write(clean, """println("  ✓ nothing wrong here"); exit(0)""")
    m2, c2 = verdict(clean)
    (m2 == 0 && c2 == 0) ? pass("C18: clean fixture passes — no false positive") :
                           fail("C18: false positive on a clean fixture ($m2 markers, exit $c2)")
end

# ─── the live check ───────────────────────────────────────────────────
section("marker / exit-code agreement across the suite")
files = sort(filter(f -> endswith(f, ".jl") &&
                         f ∉ ("run_all.jl", basename(@__FILE__)),
                    readdir(HERE)))
channelled, fossils = String[], String[]
for f in files
    src = read(joinpath(HERE, f), String)
    (occursin(MARKER, src) ? channelled : fossils) |> v -> push!(v, f)
end

println("  channel-carrying: ", length(channelled), "   fossil (no channel): ", length(fossils))
agree = let n = 0
    for f in channelled
        m, c = verdict(joinpath(HERE, f))
        ok = (m > 0) == (c != 0)
        ok && (n += 1)
        println("  ", ok ? "✓" : "✗", "  ", rpad(f, 30), "markers=", m, "  exit=", c)
        ok || fail("$f: $m marker(s) but exit $c — narration and verdict disagree")
    end
    n
end
agree == length(channelled) ?
    pass("P51 holds — all $(length(channelled)) channel-carrying files agree") :
    fail("P51: $agree/$(length(channelled)) agree")

# ─── P52 · the fossils, reported rather than counted ──────────────────
section("P52 · what this check CANNOT see")
println("  fossil files with no failure channel at all: ", length(fossils))
foreach(f -> println("      ", f), fossils)
!isempty(fossils) ?
    pass("P52 holds — these are vacuously consistent and prove nothing") :
    fail("P52: expected the 01–08 fossil record to still be channel-free")
println("""
  A file that never prints a marker can never disagree with its exit
  code. Counting these as passes would be the same move the note
  criticises: a surface signal standing in for the underlying property.
  They are listed, not scored. Note that `pal2v_damping.jl` sits in this
  list on THIS branch and does not on PR #3's, where the carrier instance
  has already given it a channel that pins my round-10 erratum. That is
  the repair in flight, and it is not mine to duplicate.""")

section("verdict")
println("""
  One seam closed, and the other named. Marker-vs-exit-code now has a
  measurement that runs; prose-vs-result does not, and I have no
  mechanization to offer for it. That gap is the honest residue of the
  note that prompted this file — a check that claimed to cover it would
  be the acknowledgment sealing itself off from the generation, one
  level up, which is the thing being warned about.

  What propagates is the part that runs. What does not run stays an
  annotation, however well phrased.""")

println("\nexit ", exitcode, " — evidence, never proof.")

if abspath(PROGRAM_FILE) == @__FILE__
    exit(exitcode)
elseif exitcode != 0
    error("verdict_agreement_check.jl FAILED (would have exited $exitcode)")
end
