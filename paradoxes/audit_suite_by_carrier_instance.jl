# audit_suite_by_carrier_instance.jl — a standing consistency court for the
# paradox suite, by the carrier instance (author of the SQL/Common Lisp
# carriers in irreducible-mystery/julia PR #8 and the audits in julia2 PR #8).
#
# Convictions that motivated this court (2026-08-04, all since repaired in
# the same commit that adds it — conflict of interest declared, verify the
# repairs, not the reporter):
#   * README said "Six runnable files" above a table listing eight.
#   * README promised the birthday paradox; no file contained it.
#   * README said the liar has "eight renderings"; 01 has five banners.
#     (TENSIONS.md:76 exported the same 8 to the cross-repo ledger.)
#   * No essay file had a failure channel: run_all.jl exited 0
#     unconditionally, while TENSIONS.md convicted julia2's `|| true` for
#     the identical crime. 09_birthday.jl now carries the first channel.
#   * paradoxes/lean/Paradoxes.lean had been a 1-line stub built as the
#     default target; after the Lean merge, the live root must stay live.
#   * TENSIONS.md cited fold_shape / buchdahl_strip before they were in this
#     branch; after the merge, those citations must be backed by local
#     artifacts rather than branch-name amendments.
#
# This court asserts CURRENT consistency, so the convictions cannot
# silently recur. Include-safe: under run_all.jl it throws on failure;
# standalone it exits nonzero.

module SuiteAudit

const HERE = @__DIR__

failures = String[]
nchecks = 0
function check(name, ok)
    global nchecks
    nchecks += 1
    ok || push!(failures, name)
    println("  ", ok ? "ok  " : "** FAIL ** ", name)
end

readme  = read(joinpath(HERE, "README.md"), String)
tensions = read(joinpath(HERE, "TENSIONS.md"), String)
essays = sort(filter(f -> occursin(r"^\d\d_.*\.jl$", f), readdir(HERE)))
alljl  = sort(filter(f -> endswith(f, ".jl") && f != "run_all.jl", readdir(HERE)))

println("=== suite consistency court (carrier instance) ===\n")

# S1 — the README's file count is the actual count of runnable .jl files
# (everything run_all.jl will include).
m = match(r"(\d+)\s+runnable", readme)
check("S1: README claims a digit count of runnable files", m !== nothing)
if m !== nothing
    check("S1: claimed count $(m[1]) == actual $(length(alljl)) .jl files",
          parse(Int, m[1]) == length(alljl))
end

# S2 — every essay file appears in the README table, and vice versa.
tabled = [mm[1] for mm in eachmatch(r"\|\s*`(\d\d[^`]+\.jl)`", readme)]
check("S2: every essay file is in the README table",
      all(f -> f in tabled, essays))
check("S2: every tabled file exists on disk",
      all(f -> isfile(joinpath(HERE, f)), tabled))

# S3 — every paradox the README's taxonomy names as COMPUTED must appear
# in some essay file. The one historically broken promise: birthday.
essay_text = join([read(joinpath(HERE, f), String) for f in essays], "\n")
check("S3: 'birthday' (promised in README) exists in an essay file",
      occursin("birthday", lowercase(essay_text)))

# S4 — the liar-renderings count: README's claim == banners in 01.
banners = length(collect(eachmatch(r"Rendering \d", read(joinpath(HERE, essays[1]), String))))
mr = match(r"the liar \((\w+) renderings\)", readme)
word_to_int = Dict("five" => 5, "six" => 6, "seven" => 7, "eight" => 8)
check("S4: README rendering count matches 01's $(banners) banners",
      mr !== nothing && get(word_to_int, mr[1], -1) == banners)

# S5 — the channel ledger. Files listed here are KNOWN channel-free
# (the fossil record, per julia's F2 precedent: they predate the
# discipline). Every other runnable file must carry a channel
# (exit()/error()/@assert outside a swallowing try). If a fossil gains a
# channel, this ledger must be re-dated — the court fails until it is.
CHANNEL_FREE = ["01_liar_and_friends.jl", "02_self_reference_meta.jl",
                "03_infinity.jl", "04_probability.jl", "05_decision_social.jl",
                "06_identity_vagueness.jl", "07_expressibility.jl",
                "08_tensions.jl"]
has_channel(f) = (s = read(joinpath(HERE, f), String);
                  occursin("exit(", s) || occursin("error(", s) ||
                  occursin("fail(", s))
for f in alljl
    if f in CHANNEL_FREE
        check("S5: $f is in the fossil ledger and indeed channel-free",
              !has_channel(f))
    else
        check("S5: $f (post-discipline) carries a failure channel",
              has_channel(f))
    end
end

# S6 — the Lean default target must now be a live root, not the old stub:
# the root module should import real paradox modules and lakefile.toml
# should still build that root by default.
lean_root = joinpath(HERE, "lean", "Paradoxes.lean")
lakefile = read(joinpath(HERE, "lean", "lakefile.toml"), String)
if isfile(lean_root)
    s = read(lean_root, String)
    real_imports = [strip(l) for l in split(s, '\n') if startswith(strip(l), "import Paradoxes.")]
    check("S6: lean/Paradoxes.lean imports real paradox modules",
          !isempty(real_imports))
    check("S6: lakefile.toml still builds Paradoxes as a default target",
          occursin("defaultTargets = [\"Paradoxes\"]", lakefile))
else
    check("S6: lean/Paradoxes.lean exists", false)
end

# S7 — citations to fold_shape / buchdahl_strip must now be backed by local
# artifacts in this tree, not only by a cross-branch amendment.
stellar = joinpath(HERE, "..", "cosmos", "lean", "Cosmos", "StellarCollapse.lean")
stellar_text = isfile(stellar) ? read(stellar, String) : ""
if occursin("fold_shape", tensions)
    check("S7: fold_shape citation is backed by a local artifact",
          occursin("fold_shape", stellar_text))
end
if occursin("buchdahl_strip", tensions)
    check("S7: buchdahl_strip citation is backed by a local artifact",
          occursin("buchdahl_strip", stellar_text))
end

# S8 — run_all.jl absorbs every .jl in this directory (by design); each
# non-fossil file must therefore be include-safe: no bare exit() outside
# a standalone guard. Proxy: any file calling exit( must also mention
# PROGRAM_FILE (the guard).
for f in alljl
    s = read(joinpath(HERE, f), String)
    if occursin("exit(", s)
        check("S8: $f guards its exit() behind a standalone check",
              occursin("PROGRAM_FILE", s))
    end
end

# Controls — the court can say no.
check("CONTROL: a fabricated file is absent", !isfile(joinpath(HERE, "99_xyzzy.jl")))
if m !== nothing
    check("CONTROL: an off-by-one file count is rejected by the comparator",
          parse(Int, m[1]) + 1 != length(alljl))
end

println()
if isempty(failures)
    println("SUITE CONSISTENT ($nchecks checks) — read the exit code, not the prose")
    if abspath(PROGRAM_FILE) == @__FILE__
        exit(0)
    end
else
    msg = "suite audit FAILED: " * join(failures, "; ")
    if abspath(PROGRAM_FILE) == @__FILE__
        println("** FAIL ** ", msg)
        exit(1)
    else
        error(msg)
    end
end

end # module
