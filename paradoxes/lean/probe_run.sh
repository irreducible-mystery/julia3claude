#!/usr/bin/env bash
# probe_run.sh — drive RejectionCapture.lean and its mutants.
#
# House discipline: an instrument that cannot fail certifies nothing, so
# the probe is not trusted until the mutants are seen to be REJECTED.
# The probe itself must compile (its findings are green-by-design);
# each mutant must NOT compile, and for a stated reason.
#
# Usage:  paradoxes/lean/probe_run.sh          (needs lake + the suite's toolchain)
set -uo pipefail
cd "$(dirname "$0")"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
exitcode=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ FAIL: $1"; exitcode=1; }

run_lean() { cp "$1" ./_probe_tmp.lean; lake env lean ./_probe_tmp.lean > "$2" 2>&1; local r=$?; rm -f ./_probe_tmp.lean; return $r; }

echo "── the probe itself (must compile) ──"
if run_lean RejectionCapture.lean "$work/probe.out"; then
    pass "RejectionCapture.lean compiles — all 4 captures hold on this toolchain"
else
    fail "probe did not compile"; cat "$work/probe.out"
fi

echo "── mutant 1: wrong expected message (must be REJECTED) ──"
cat > "$work/m1.lean" <<'EOF'
/-- error: (kernel) arg #1 of 'M1.Liar.mk' has a POSITIVE occurrence of the datatypes being declared -/
#guard_msgs in
inductive M1Liar : Prop where
  | mk : ¬M1Liar → M1Liar
EOF
if run_lean "$work/m1.lean" "$work/m1.out"; then
    fail "mutant 1 compiled — the capture accepts a message it was not given"
else
    pass "mutant 1 rejected — string equality is enforced (see below)"
    grep -q "guard_msgs" "$work/m1.out" && echo "      (guard reported the mismatch itself)"
fi

echo "── mutant 2: a capture on a declaration that SUCCEEDS (must be REJECTED) ──"
cat > "$work/m2.lean" <<'EOF'
/-- error: (kernel) arg #1 of 'M2.Fine.mk' has a non positive occurrence of the datatypes being declared -/
#guard_msgs in
inductive M2Fine : Type where
  | mk : Nat → M2Fine
EOF
if run_lean "$work/m2.lean" "$work/m2.out"; then
    fail "mutant 2 compiled — a capture passed with NO error produced"
else
    pass "mutant 2 rejected — an unfired refusal cannot masquerade as one"
fi

echo "── mutant 3: the SAME capture text, a DIFFERENT paradox (must COMPILE) ──"
cat > "$work/m3.lean" <<'EOF'
-- Finding A, isolated: swap the liar for Curry, keep the certificate shape.
/-- error: (kernel) arg #1 of 'M3C.mk' has a non positive occurrence of the datatypes being declared -/
#guard_msgs in
inductive M3C : Prop where
  | mk : (M3C → False) → M3C
EOF
if run_lean "$work/m3.lean" "$work/m3.out"; then
    pass "mutant 3 compiled — one verdict text serves two distinct paradoxes:"
    echo "      the certificate pins the refusal CLASS, never the philosophy"
else
    fail "mutant 3 did not compile — finding A does not reproduce"
fi

echo
if [ $exitcode -eq 0 ]; then
    echo "PROBE VERDICT: the instrument is real (mutants 1-2 rejected) and its"
    echo "resolution limit is real (mutant 3 compiles). A rejection-capture"
    echo "certifies THAT the elaborator refused and WITH WHICH WORDS — not why"
    echo "the author says it refused. Pair every capture with prose that quotes"
    echo "the message's own distinguishing token, or the story stays uncertified."
fi
echo "exit $exitcode — evidence, never proof."
exit $exitcode
