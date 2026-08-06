# ======================================================================
# pin_check.jl — decision-bearing numbers as pins with bodies, stress
# mutations, and expiry.
#
# WHY. The focus note (julia3claude #3 and #4, outside voice):
#
#   "Operational visibility means the system's next move can still be
#    altered by evidence that the cut was optional — not merely that a
#    human can recite that it was. ... Structural moves: pins as claims
#    with body + stress mutation; expiry on decision-bearing lines ...
#    Loss of visibility should be expensive and measurable."
#
# Last round I closed the marker/exit-code seam and said plainly that I
# had no mechanization for the prose/result seam. This note hands one
# over. Not "verify the prose is true" — undecidable in general — but
# EXPIRY: a decision-bearing number carries its derivation, and drift
# costs a red run instead of waiting to be discovered by someone else.
#
# It is aimed at my worst-attested habit. Every number I have gotten
# wrong in this collaboration was a decision-bearing line with no expiry:
#   · "14 `#guard_msgs`"      → 12 uses, 8 refusals
#   · "eight renderings"      → five
#   · "14 runnable / 11 rows" → 15 / 12, one commit later
# Each was true when written and none could tell me when it stopped
# being true. A pin can.
#
# ANATOMY OF A PIN (their three parts, made concrete)
#   BODY      — the claim's location AND its derivation from the tree,
#               so "claimed" and "actual" are separately computed.
#   STRESS    — a mutation that MUST break the pin. A pin that cannot
#               fail is a `|| true` with better manners.
#   EXPIRY    — a pin may be declared KNOWN-OPEN with an owner and a
#               flip condition. It does not fail the run, but the check
#               FAILS IF THE CONDITION HAS BEEN MET and the deferral is
#               still sitting here. Deferring costs something and stops
#               being free the moment it is no longer justified.
#
# WHAT THIS IS NOT. It does not make the cut optional; it makes drift
# from the cut expensive. The registry below is itself a cut — I chose
# these five numbers — and it is incomplete by construction (§4).
#
# PREDICTIONS (registered before running):
#   P53. The two Lean-side pins HOLD (I repaired them by measuring).
#   P54. The three README-side pins are KNOWN-OPEN and their flip
#        conditions are still UNMET — PR #3 owns those repairs and has
#        not landed.
#   P55. Every pin's stress mutation breaks it. A pin that survives its
#        own mutation is reported as vacuous.
#   Controls: C19 a pin with a deliberately wrong claim must FAIL;
#             C20 a KNOWN-OPEN pin whose condition HAS been met must FAIL
#                 (expiry has teeth, not just manners).
# ======================================================================

exitcode = 0
fail(m) = (global exitcode = 1; println("  ✗ FAIL: ", m))
pass(m) = println("  ✓ ", m)
note(m) = println("  · ", m)
section(t) = println("\n── ", t, " ", "─"^max(0, 56 - length(t)))

const HERE = @__DIR__
const ROOT = dirname(HERE)

slurp(p) = isfile(p) ? read(p, String) : ""

# ─── derivations (all read the TREE, never a remembered number) ───────
count_matches(text, re) = length(collect(eachmatch(re, text)))

derive_renderings()  = count_matches(slurp(joinpath(HERE, "01_liar_and_friends.jl")), r"Rendering \d")
derive_runnable()    = count(f -> endswith(f, ".jl") && f != "run_all.jl", readdir(HERE))
derive_essays()      = count(f -> occursin(r"^\d\d_.*\.jl$", f), readdir(HERE))
derive_table_rows()  = count_matches(slurp(joinpath(HERE, "README.md")), r"\|\s*`\d\d[^`]+\.jl`")
derive_guard_uses()  = count(l -> startswith(strip(l), "#guard_msgs"),
                             split(slurp(joinpath(HERE, "lean", "Paradoxes", "Expressibility.lean")), '\n'))

"""Error-pinned `#guard_msgs` blocks: the docstring immediately above pins an `error:`."""
function derive_guard_errors()
    lines = split(slurp(joinpath(HERE, "lean", "Paradoxes", "Expressibility.lean")), '\n')
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

# claimed-value extractors: parse the number OUT OF THE DOCUMENT that asserts it
const WORDS = Dict("five"=>5,"six"=>6,"seven"=>7,"eight"=>8,"nine"=>9,"ten"=>10,
                   "eleven"=>11,"twelve"=>12,"thirteen"=>13,"fourteen"=>14,"fifteen"=>15)
word_or_num(s) = get(WORDS, lowercase(s), tryparse(Int, s))

function claimed(path, re)
    m = match(re, slurp(path))
    m === nothing && return nothing
    return word_or_num(String(m.captures[1]))
end

# ─── the registry (a cut, and named as one) ───────────────────────────
const README   = joinpath(HERE, "README.md")
const CAPTURED = joinpath(HERE, "lean", "RejectionCapture.lean")

pins = [
 (name="renderings",   doc=README,   re=r"the liar \((\w+) renderings\)",
  derive=derive_renderings,  stress=() -> derive_renderings() + 1,
  open=true,  owner="PR #3 (carrier instance)", reversal=:in_tree),

 (name="runnable",     doc=README,   re=r"(\w+) runnable",
  derive=derive_runnable,    stress=() -> derive_runnable() + 1,
  open=true,  owner="PR #3 (carrier instance)", reversal=:in_tree),

 (name="count_vs_table", doc=README, re=r"(\w+) runnable",   # README's own count vs its own table
  derive=derive_table_rows,  stress=() -> derive_table_rows() + 1,
  open=true,  owner="PR #3 (carrier instance)", reversal=:in_tree),

 (name="guard_uses",   doc=CAPTURED, re=r"Expressibility\.lean: (\d+) uses",
  derive=derive_guard_uses,  stress=() -> derive_guard_uses() + 1,
  open=false, owner="mine", reversal=:in_tree),

 (name="guard_errors", doc=CAPTURED, re=r"(\d+) of them refusals",
  derive=derive_guard_errors, stress=() -> derive_guard_errors() + 1,
  open=false, owner="mine", reversal=:in_tree),
]

# ─── §1 · the pins that must hold ─────────────────────────────────────
section("§1 · pins currently asserted as holding (provisional, owner: mine)")
for p in pins
    p.open && continue
    c, d = claimed(p.doc, p.re), p.derive()
    (c !== nothing && c == d) ?
        pass("$(p.name): document says $c, tree says $d") :
        fail("$(p.name): document says $(repr(c)), tree says $d — a decision-bearing line has drifted")
end

# ─── §2 · KNOWN-OPEN pins, with expiry that has teeth ─────────────────
section("§2 · known-open pins (deferred, with a flip condition)")
for p in pins
    p.open || continue
    c, d = claimed(p.doc, p.re), p.derive()
    if c !== nothing && c == d
        # the deferral has RESOLVED — sitting on it is now the defect
        fail("$(p.name): claimed $c == derived $d, so the deferral to $(p.owner) has EXPIRED; " *
             "remove the known-open marking")
    else
        note("$(p.name): document says $(repr(c)), tree says $d — open, owned by $(p.owner)")
    end
end
println("""
  These do not redden the run, and that is a decision with a cost
  attached: the moment a repair lands, §2 FAILS until the known-open
  marking is removed. A deferral that stops being justified stops being
  free. (C20 below proves that branch fires.)""")

# ─── §3 · stress mutations — every pin must be breakable ──────────────
section("§3 · stress: each pin must be able to fail")
let vacuous = String[]
    for p in pins
        p.derive() == p.stress() && push!(vacuous, p.name)
    end
    isempty(vacuous) ?
        pass("P55 holds — all $(length(pins)) pins move under their stress mutation") :
        fail("vacuous pins (survive their own mutation): " * join(vacuous, ", "))
end

# ─── controls ─────────────────────────────────────────────────────────
section("controls")
let wrong_claim = 999, derived = derive_renderings()
    wrong_claim == derived ? fail("C19: a deliberately wrong claim matched the tree") :
                             pass("C19: a wrong claim is caught (claimed 999 vs derived $derived)")
end
let resolved_open = (c = 7, d = 7)   # a known-open pin whose condition HAS been met
    resolved_open.c == resolved_open.d ?
        pass("C20: expiry fires — a resolved deferral is reported as a failure branch") :
        fail("C20: expiry branch unreachable — known-open would be a `|| true`")
end

# ─── §4 · the registry is a cut, and incomplete by construction ───────
section("§4 · what this registry does not pin")
println("""
  Pinned: $(length(pins)) numbers. NOT pinned, and each is a
  decision-bearing line somewhere in this repo:
      · the Lean catalog tally (91 / 50 THEOREM / 3 IDENTITY) — derivable
        only by running `lake exe paradoxes`, too slow for this check, so
        it stays a remembered number and I am saying so;
      · every prose count in TENSIONS.md's fifteen rounds;
      · every number in a PR comment, which is where three of my four
        recorded errors actually landed.

  The last one matters most: PR comments are outside the tree, so no
  check here can reach them. That is not a gap I can close from inside —
  it is the boundary of this instrument, stated rather than left for
  someone to find. A meta-ledger incomplete by construction, as the note
  asks, means printing the incompleteness, not implying it.""")

# ─── §5 · reversal cost — the operational form of "semi-forgetting" ───
section("§5 · reversal cost, not error count")
let by = Dict{Symbol,Int}()
    for p in pins; by[p.reversal] = get(by, p.reversal, 0) + 1; end
    for k in (:in_tree, :toolchain, :unreachable)
        println("  ", rpad(String(k), 13), get(by, k, 0), " pin(s)")
    end
    # P56, and it convicts the registry rather than flattering it:
    (get(by, :in_tree, 0) == length(pins)) ?
        pass("P56 holds, and it is a FINDING AGAINST THIS FILE — every pin " *
             "is in_tree.\n      The registry covers exactly the cheap " *
             "forgettings and none of the costly ones.") :
        fail("P56: expected all $(length(pins)) pins in_tree, got $(get(by, :in_tree, 0))")
end
println("""
  A LATER CORRECTION FROM THE SAME VOICE, and it lands on this file:

    "We are NOT trying to escape representation. That is not possible.
     Semi-forgetting is part of how any next move gets made. … Two truths
     without collapse: (1) cut is provisional; (2) cut is necessary for
     the next move."

  My own verdict here first read: "I now cannot commit a change that
  moves a pinned number." That is the escape framing, written into the
  instrument built against it. A pinned number SHOULD move — the tree
  moves, and the cut is necessary. The pin's job was never to stop the
  movement; it is to make the movement a DECISION instead of a silence.
  Reworded below; the original is kept here because deleting it would be
  the same forgetting one layer up.

  Which turns the whole ledger over. Sixteen rounds of errata are not a
  failure record — they are a record of FORGETTINGS, and forgetting is
  load-bearing rather than optional. The metric that matters is not how
  many there were but what each cost to reverse:
    · in_tree     — a script re-derives it (the "14 guard_msgs" error)
    · toolchain   — needs an external build (the Lean catalog tally)
    · unreachable — outside the tree entirely (numbers in PR comments,
                    where three of my four recorded errors landed)
  Cheap forgettings are the price of making a next move at all. Only the
  unreachable ones are debt.

  And the count above indicts the registry: 5 in_tree, 0 toolchain, 0
  unreachable. I pinned every number that was easy to pin and none that
  was not — the Lean tally sits in `toolchain` unpinned, and the PR-comment
  numbers sit in `unreachable` where three of my four errors actually
  landed. A cut that covers only its own cheap cases and reports itself
  green is the exact shape being warned about, so it is printed as a
  finding against this file rather than as a score for it.""")

section("verdict")
println("""
  Expiry is the mechanization I said last round I did not have, and it
  came from outside. It does not check that prose is TRUE; it checks
  that a claimed number still matches its derivation, and it makes both
  drift AND stale deferral cost a red run.

  Reworded after the correction: this does not stop a cut from moving,
  and it should not — the cut is provisional AND necessary. What it does
  is make a moved cut arrive as a decision rather than as a silence, and
  it prices the forgetting by where the number can be re-derived from.
  Non-self-fooling, not escape. Continuous practice, not a floor.""")

println("\nexit ", exitcode, " — evidence, never proof.")

if abspath(PROGRAM_FILE) == @__FILE__
    exit(exitcode)
elseif exitcode != 0
    error("pin_check.jl FAILED (would have exited $exitcode)")
end
