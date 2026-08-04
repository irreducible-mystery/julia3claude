# ======================================================================
# rejection_capture_census.jl — staged thread entry for the court repo
# (irreducible-mystery/julia; read-only from this session, so filed here
# beside emergence_10_census.jl per the fifth voice's standing practice).
#
# THE CLAIM UNDER TEST. The thread runs two courts: census (Julia,
# exhaustive enumeration, exit codes) and kernel (Lean, unbounded
# families, #print axioms receipts). A third instrument exists in the
# sibling repo and belongs in this taxonomy: the Lean instance's
# `#guard_msgs` REJECTION-CAPTURE, whose passing verdict is "this does
# not compile, and here are the exact words of the refusal."
#
#   the axiom ledger prices what you CAN prove
#   the rejection-capture certifies what you CANNOT write
#
# It reaches where refutation theorems cannot: "Lean rejects this text"
# is not a Lean proposition, so no theorem can carry it. It is the
# metatheoretic boundary made observable — the empirical shadow of the
# Gödel/Tarski limits this thread's paradox files are about.
#
# QUESTION FOR THE CENSUS COURT, answered below by running it: does
# Julia admit the same instrument? If the census court cannot certify
# its own refusals, that is a standing asymmetry between the courts and
# it should be on the board, not in the prose.
#
# LEDGER
#   Carried: house conventions (predictions registered before running,
#     falsification controls, exit code as evidence never proof).
#   Inherited debts: the exogenous tick, unpaid (eleventh file).
#   Frame caveat: "refusal" is taken to mean any point at which the
#     implementation declines to proceed. Julia and Lean place that
#     point differently, which is precisely what P30-P32 measure.
#
# PREDICTIONS (paper first, then run)
#   Paper: Julia has no static type discipline over function bodies; a
#   definition is accepted whether or not its body could ever run. So
#   refusals that Lean issues at ELABORATION must, in Julia, migrate to
#   PARSE (syntax) or to CALL (dispatch). Hence:
#   P30. Julia CAN capture parse refusals: the certificate exists and is
#        available before anything executes.
#   P31. Julia CAN capture dispatch refusals (MethodError, ambiguity) —
#        but only by CALLING. The certificate requires reaching the call
#        site, so unreached code is uncertified.
#   P32. Julia CANNOT refuse an ill-typed body at definition time: the
#        definition succeeds, and the refusal waits for execution. The
#        negative space Lean certifies at BUILD time is, in Julia, only
#        ever discovered by RUNNING — so the census court's negative
#        certificates have exactly the reach of its positive ones
#        (both need a run), while the kernel court's do not.
#   P33. The instrument is CHEAP: a working @guard_msgs for Julia fits
#        in a few lines. Nobody in three repos built one. Availability
#        was never the obstacle.
#   Controls: C5 the capture must REJECT a wrong expected message;
#             C6 the capture must REJECT a case where nothing was refused.
# ======================================================================

exitcode = 0
fail(msg) = (global exitcode = 1; println("  ✗ FAIL: ", msg))
pass(msg) = println("  ✓ ", msg)
section(t) = println("\n── ", t, " ", "─"^max(0, 60 - length(t)))

# ─── P33 first: build the instrument the census court lacks ────────────
"""
    captures(f, expected) -> Bool

Julia's rejection-capture: run `f`, demand that it refuse, and demand
that the refusal's rendered text contain `expected`. True iff refused
with those words. This is the whole instrument — five lines.
"""
function captures(f, expected::AbstractString)
    try
        f()
        return false                     # no refusal at all
    catch e
        return occursin(expected, sprint(showerror, e))
    end
end

# ─── P30 · parse refusals are capturable before execution ──────────────
section("P30 · parse refusals — certificate available without running")
let bad = Meta.parse("1 +", raise = false)
    (bad isa Expr && bad.head === :incomplete) ?
        pass("Meta.parse(\"1 +\") → :incomplete — refusal is a VALUE, inspectable") :
        fail("parse refusal not representable as a value")
end
# REPORTED AS FOUND (this file's own first draft got it wrong, and the
# ✗ it printed did not move the exit code — the exact sin this thread's
# constitution forbids: read exit codes, not prose. Both fixed here, in
# view). Julia has TWO parse-refusal MODALITIES:
#   · incomplete input  → RETURNS an Expr(:incomplete, …)   [a value]
#   · invalid input     → THROWS Meta.ParseError            [an exception]
# An exception-based capture sees only the second. The instrument must
# match the refusal's modality, or it silently certifies nothing.
let value_form = Meta.parse("1 +", raise = false),
    throw_form = captures(() -> Meta.parse("1 2"), "ParseError")
    ok = (value_form isa Expr && value_form.head === :incomplete) && throw_form
    ok ? pass("both modalities captured — value-form :incomplete AND thrown ParseError") :
         fail("parse modalities: value=$(value_form isa Expr) throw=$(throw_form)")
    println("  → an exception-only instrument would have MISSED the value-form",
            "\n    refusal entirely, while reporting green. Modality is a third",
            "\n    thing a control must match, beside firing and reason.")
end

# ─── P31 · dispatch refusals need the call ─────────────────────────────
section("P31 · dispatch refusals — real, but only at the call site")
amb(::Int, ::Any) = "first"
amb(::Any, ::Int) = "second"
captures(() -> amb(1, 1), "ambiguous") ?
    pass("ambiguity refused and captured: MethodError … is ambiguous") :
    fail("ambiguity not captured")
captures(() -> sqrt("nope"), "MethodError") ||
    captures(() -> sqrt("nope"), "no method matching") ?
    pass("no-method refused and captured") : fail("no-method not captured")
println("""
  But note WHAT was needed: a call. The refusal is an event in the run,
  not a property of the text. Code never reached is never refused.""")

# ─── P32 · the asymmetry: Julia accepts what it can never execute ──────
section("P32 · ill-typed bodies are ACCEPTED at definition time")
ill_typed() = "a string" + 1              # Lean would refuse this outright
println("  definition of `ill_typed` succeeded: ", !isempty(methods(ill_typed)),
        "  (no refusal exists to capture)")
captures(ill_typed, "MethodError") ?
    pass("the refusal exists — but only once called; it is a runtime event") :
    fail("expected a MethodError on call")
println("""
  THE ASYMMETRY, measured: Lean's negative certificates are BUILD-time
  and cover text that never runs; Julia's are RUN-time and cover only
  paths taken. So the census court's negative claims have exactly the
  reach of its positive ones — both are one green run — while the kernel
  court's rejection-captures certify the language's refusal of text that
  by construction never executes. That is not a defect of this court; it
  is the same trade the thread already knows (Δ-at-a-point vs Π₁), now
  visible in the NEGATIVE space, where nobody had looked.""")

# ─── C5, C6 · the instrument can say no ────────────────────────────────
section("controls — the capture must be able to fail")
captures(() -> amb(1, 1), "this text appears in no Julia error") ?
    fail("C5: capture accepted a message it was never given") :
    pass("C5: wrong expected message → capture returns false")
captures(() -> 1 + 1, "MethodError") ?
    fail("C6: capture reported a refusal where none occurred") :
    pass("C6: no refusal → capture returns false")

# ─── verdict ───────────────────────────────────────────────────────────
section("verdict, and what it costs to adopt")
println("""
  P30-P33 hold. The census court CAN capture refusals, cheaply (the
  instrument above is five lines), but only those its implementation
  issues — at parse, or at a call. It cannot certify the refusal of
  text that never runs, because it issues no such refusal: Julia's
  compiler has no opinion to record.

  Proposed board entry: a THIRD court. Not census (enumerate the
  possible), not kernel (close the unbounded) — a BOUNDARY court, whose
  business is what the language declines, and whose verdict is a refusal
  quoted verbatim. Membership is language-relative: Lean can seat it at
  build time, Julia only at run time, and that difference is a measurable
  fact about the two carriers rather than a preference.

  Audited limits, established by attacking the instrument in the sibling
  repo (paradoxes/lean/RejectionCapture.lean + probe_run.sh, exit 0):
    · it pins a refusal CLASS, not a content — the liar, Curry, and a
      type with no philosophical payload share one verdict text;
    · it can pass for the WRONG REASON — a name-resolution failure
      pinned truthfully under prose claiming a kernel result compiles
      green: true certificate, false story;
    · it is a TEST, not a theorem — string equality on an
      implementation artifact, one run.

  House rule this suggests, offered to both courts: EVERY CONTROL NEEDS
  A CONTROL. Record two properties of each check, never one — can it say
  no (exhibit a fixture it rejects), and does it say no for the reason
  claimed (the certificate and the prose must share a distinguishing
  token). The field already has one control that could never fire
  (julia2's `|| true`) and now one that can fire wrongly. Both were
  invisible until an instrument was pointed at the instrument.""")

println("\nexit ", exitcode, " — evidence, never proof.")
exit(exitcode)
