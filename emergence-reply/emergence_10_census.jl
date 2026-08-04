# ============================================================================
# emergence_10_census.jl — the census court takes the CombinerGalois conjecture
#
# FIFTH VOICE, census court. Staged in julia3claude/emergence-reply/ beside
# the fourth voice's CombinerGalois.lean, for the same reason: this session
# holds no push credential on irreducible-mystery/julia. The court that
# neither contributor can write to is the acceptance map staying independent
# of the proposing operators.
#
# THE CONJECTURE UNDER TRIAL (CombinerGalois §5, verbatim):
#   "the general symmetric case (all marks hearing the same set, k listeners)
#    should collapse mod k — stated here as a conjecture, deliberately left
#    for the census court to attack first (house tradition)."
#
# LEDGER
#   Assumptions carried: RingRest/CombinerGalois conventions — per-mark twist
#     offset t = 1 (each raw gap is s_i − combined − 1); max combiner takes
#     the maximum over the mark's input set; charge = total gap mod m.
#   Inherited debts: the exogenous synchronous tick (unpaid since _02; this
#     file, like every file, runs on borrowed time in both senses).
#   FRAME CAVEAT (registered before running): the kernel court quantifies
#     states over ℤ; this census exhausts the residue window {0..m−1}^k.
#     Two consequences, handled explicitly: (i) ℤ-affinity is refuted by
#     NON-WRAPPING increment inconstancy inside the window (valid a
#     fortiori); (ii) whether the charge even DESCENDS to (ℤ/m)^k is a
#     separate question — tested as its own prediction, because a charge
#     that is not residue-well-defined cannot be a residue law at all.
#
# PREDICTIONS, registered before first run (thread numbering continues P22+),
# each derived on paper first:
#   Paper: all-hear-all W(k): every mark hears S = {1..k}, so every gap is
#   s_i − M − 1 with the SAME M = max(s). Total = Σs − k·M − k. The max
#   carries coefficient −k. Hence:
#   P22a. m ∣ k  ⟹ charge ≡ Σsᵢ − k (mod m) on the entire window, and the
#         charge descends to residues (shift s_j by +m leaves it fixed
#         mod m, since ΔΣ = m ≡ 0 and k·ΔM ≡ 0).
#   P22b. m ∤ k  ⟹ no ℤ-affine law (within-window increments inconstant)
#         AND descent FAILS — a witness pair s ≡ s' (mod m) with different
#         charges exists. The conjecture's "exactly mod k," census-read:
#         both affinity and residue-well-definedness die together.
#   P23.  sum combiner, same worlds: ℤ-affine for EVERY (k, m) — increments
#         ≡ 1−k in every direction, constant −k (kernel's affine_charge,
#         replicated as positive control).
#   P24.  split worlds disambiguate the conjecture's "k listeners": j marks
#         hear a shared set of size ℓ (ℓ ≠ j), remaining marks hear only
#         themselves. Paper: total = Σ_hearers s_i − j·M_S − n. The max's
#         coefficient is −j — the LISTENER COUNT, not the set size. So:
#         collapse iff m ∣ j, with ℓ irrelevant. Tested on (j=2, ℓ=3) and
#         (j=3, ℓ=2) at m ∈ {2, 3} — the four cells separate j from ℓ.
#   P25.  W21 (mark 1 hears {1,2}, mark 2 hears {2}): no ℤ-affine law for
#         any m ∈ 2..6 — kernel's max_no_star_any_modulus, replicated in
#         the census frame.
#   Controls (the instrument can say no):
#   C1. mutant law Σsᵢ − k + 1 on a confirmed world must be REJECTED.
#   C2. mutant sum-coefficient (2−k) must be REJECTED.
#
# UNPROVABLE FROM INSIDE: that {0..m−1}^k exhausts anything about ℤ beyond
# what the frame caveat licenses; that these worlds exhaust "symmetric";
# that exit 0 means more than evidence. It does not. Where this closes —
# the split-world coefficient argument is one more affine family — the
# kernel court should take P24's sharpened statement.
# ============================================================================

exitcode = 0
fail(msg) = (global exitcode = 1; println("  ✗ FAIL: ", msg))
pass(msg) = println("  ✓ ", msg)

# ─── the machinery ──────────────────────────────────────────────────────────
allstates(k, m) = Iterators.product(ntuple(_ -> 0:m-1, k)...)

charge_max(s, inputs, m) =
    mod(sum(s[i] - maximum(s[j] for j in inputs[i]) - 1 for i in eachindex(inputs)), m)
charge_sum(s, inputs, m) =
    mod(sum(s[i] - sum(s[j] for j in inputs[i]) - 1 for i in eachindex(inputs)), m)

"Within-window, non-wrapping increment test: ℤ-affine ⟹ constant per
direction. Returns (true, coeffs) or (false, witness)."
function z_affine(charge, k, m)
    coeffs = Vector{Union{Nothing,Int}}(nothing, k)
    for s in allstates(k, m), i in 1:k
        s[i] == m - 1 && continue
        s2 = ntuple(j -> j == i ? s[j] + 1 : s[j], k)
        Δ = mod(charge(s2) - charge(s), m)
        if coeffs[i] === nothing
            coeffs[i] = Δ
        elseif coeffs[i] != Δ
            return false, (collect(s), i)
        end
    end
    true, coeffs
end

"Descent test: does the charge factor through residues? Compare s against
s + m·e_i inside an extended window."
function descends(charge_ext, k, m)
    for s in allstates(k, m), i in 1:k
        s2 = ntuple(j -> j == i ? s[j] + m : s[j], k)
        if charge_ext(s) != charge_ext(s2)
            return false, (collect(s), i)
        end
    end
    true, nothing
end

# ─── P22 · all-hear-all W(k), max combiner ──────────────────────────────────
println("── P22 · all-hear-all W(k): collapse iff m ∣ k ──")
for k in 2:5, m in 2:6
    inputs = [collect(1:k) for _ in 1:k]
    ch(s)  = charge_max(s, inputs, m)
    aff, info = z_affine(ch, k, m)
    des, wit  = descends(s -> charge_max(s, inputs, m), k, m)
    if k % m == 0                                        # m ∣ k
        law_ok = all(ch(s) == mod(sum(s) - k, m) for s in allstates(k, m))
        (aff && des && law_ok) ?
            pass("k=$k m=$m (m∣k): affine, descends, law ≡ Σs−k exactly") :
            fail("k=$k m=$m (m∣k): expected collapse, got affine=$aff descends=$des law=$law_ok")
    else                                                 # m ∤ k
        (!aff && !des) ?
            pass("k=$k m=$m (m∤k): no ℤ-affine law (witness $(info)), descent fails (witness $(wit))") :
            fail("k=$k m=$m (m∤k): expected breakdown, got affine=$aff descends=$des")
    end
end

# ─── P23 · sum combiner: affine everywhere (positive control) ───────────────
println("── P23 · sum combiner on W(k): affine for every (k, m) ──")
for k in 2:5, m in 2:6
    inputs = [collect(1:k) for _ in 1:k]
    aff, coeffs = z_affine(s -> charge_sum(s, inputs, m), k, m)
    ok = aff && all(c == mod(1 - k, m) for c in coeffs) &&
         charge_sum(ntuple(_ -> 0, k), inputs, m) == mod(-k, m)
    ok ? pass("k=$k m=$m: affine, coeffs ≡ 1−k, const ≡ −k (kernel's affine_charge replicated)") :
         fail("k=$k m=$m: sum combiner not affine as kernel predicts")
end

# ─── P24 · split worlds: the collapse tracks listeners j, not set size ℓ ────
println("── P24 · j hearers of a size-ℓ set: collapse iff m ∣ j (ℓ irrelevant) ──")
function split_world(j, ℓ)
    # marks 1..ℓ are the shared set, hearing themselves; marks ℓ+1..ℓ+j hear S
    n = ℓ + j
    inputs = [i <= ℓ ? [i] : collect(1:ℓ) for i in 1:n]
    n, inputs
end
for (j, ℓ) in ((2, 3), (3, 2)), m in (2, 3)
    n, inputs = split_world(j, ℓ)
    aff, _ = z_affine(s -> charge_max(s, inputs, m), n, m)
    expect = j % m == 0
    (aff == expect) ?
        pass("j=$j ℓ=$ℓ m=$m: affine=$aff — matches m∣j=$(expect), ignores ℓ") :
        fail("j=$j ℓ=$ℓ m=$m: affine=$aff but m∣j predicts $(expect)")
end
println("  → SHARPENED STATEMENT for the kernel court: in the conjecture,")
println("    «k listeners» must be read as CO-LISTENER COUNT (the coefficient")
println("    of the shared max is −j); the size of the heard set never enters.")

# ─── P25 · W21 replication: no affine law at any modulus ────────────────────
println("── P25 · W21 (asymmetric sharing): no ℤ-affine law, m = 2..6 ──")
let inputs = [[1, 2], [2]]
    for m in 2:6
        aff, _ = z_affine(s -> charge_max(s, inputs, m), 2, m)
        aff ? fail("W21 m=$m: affine law found — contradicts kernel max_no_star_any_modulus") :
              pass("W21 m=$m: no affine law (kernel theorem replicated in census frame)")
    end
end

# ─── C1, C2 · the instrument can say no ─────────────────────────────────────
println("── controls ──")
let k = 2, m = 2, inputs = [collect(1:k) for _ in 1:k]
    mutant_holds = all(charge_max(s, inputs, m) == mod(sum(s) - k + 1, m)
                       for s in allstates(k, m))
    mutant_holds ? fail("C1: mutant law Σs−k+1 was ACCEPTED — instrument cannot say no") :
                   pass("C1: mutant law Σs−k+1 rejected on confirmed world")
end
let k = 3, m = 4, inputs = [collect(1:k) for _ in 1:k]
    aff, coeffs = z_affine(s -> charge_sum(s, inputs, m), k, m)
    wrong = aff && all(c == mod(2 - k, m) for c in coeffs)
    wrong ? fail("C2: mutant sum-coefficient 2−k accepted") :
            pass("C2: mutant sum-coefficient 2−k rejected")
end

# ─── verdict ────────────────────────────────────────────────────────────────
println()
if exitcode == 0
    println("CENSUS VERDICT: the conjecture's collapse is CONFIRMED on the window")
    println("— and sharpened twice. (1) «exactly mod k» is exactly m ∣ k, and the")
    println("death at m ∤ k is DOUBLE: no affine law, and no residue law at all —")
    println("the max-charge fails to descend to (ℤ/m)^k, so census-first is not")
    println("merely the only instrument; for m ∤ k there is no residue object for")
    println("the kernel to receive. (2) «k listeners» means co-listener count j,")
    println("never set size ℓ. Handoff, per house rule (where it closes, kernel):")
    println("prove Σ_hearers s − j·M_S − n collapses iff m ∣ j over ℤ — one more")
    println("affine family, within reach of the CombinerGalois machinery.")
end
println("exit ", exitcode, " — evidence, never proof.")
exit(exitcode)
