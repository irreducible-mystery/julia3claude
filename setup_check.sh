#!/usr/bin/env bash
# setup_check.sh — the postconditions of setup.sh, as exit codes.
#
# WHY THIS EXISTS
#
# setup.sh ended by printing three version strings. A printed version is a
# report, not a check: it cannot distinguish a working install from one whose
# egress workaround never reached the shell that needs it. This file is the
# check, and the first thing it caught was exactly that (§2) — the documented
# fix for the single most important block in this sandbox was written to
# /root/.bashrc, which a script, a CI job, or a non-interactive session never
# reads. `julia -e 'using Pkg; ...'` from any of those resolved the package
# server to https://pkg.julialang.org, which the README itself lists as
# blocked. A fix placed where the failure it was written for cannot reach it:
# the same shape as a `|| true`, and as a probe that lives outside its own
# instrument.
#
# It also supplies the pin class `paradoxes/pin_check.jl` §5 declares empty.
# That registry pins five numbers, all `in_tree`, and prints the tally as a
# finding against itself — "5 in_tree, 0 toolchain, 0 unreachable. I pinned
# every number that was easy to pin and none that was not." The README's
# toolchain table is a `toolchain`-class number: its derivation is
# `julia --version`, not a file count, so no in-tree check can reach it. It
# had drifted. The table said Julia 1.12.6; the script installs whatever
# conda-forge publishes, which is 1.13.0 today.
#
# P56 is NOT touched. It is a registered claim about THAT registry and it
# still holds there: every pin in pin_check.jl is in_tree. What changes is
# that the gap the claim describes is now covered from outside the suite —
# outside, because a box with Julia and no Lean should still get a green
# `run_all.jl`, and a check that needs `lean` cannot promise that.
#
# ANATOMY, borrowed unchanged from pin_check.jl:
#   BODY    — the claim's location AND an independent derivation, so
#             "claimed" and "actual" are separately computed.
#   STRESS  — a mutation that MUST break the check. A check that cannot
#             fail is a `|| true` with better manners.
#   EXPIRY  — a recorded measurement carries its date and its instrument;
#             drift costs a red run instead of waiting to be found later.
#
# EXIT CODES (precedence: 2, then 1, then 3, then 4)
#   0  every check holds
#   1  a functional postcondition FAILED — something is actually broken
#   2  a STRESS mutation did not break its check — the instrument certifies
#      nothing, which is worse than a failure it can name
#   3  could not measure (a tool is missing) — probe failure, not a reading
#   4  the install works and a RECORDED NUMBER HAS DRIFTED — nothing is
#      broken, the record is stale. One edit to the README table fixes it.
#
# Usage:  ./setup_check.sh          (run by setup.sh at the end)

set -uo pipefail
cd "$(dirname "$0")"

README="README.md"
RAW_JULIA="/opt/julia-env/bin/julia"

broke=0 vacuous=0 unmeasured=0 drifted=0
pass()  { echo "  ✓ $1"; }
fail()  { echo "  ✗ FAIL: $1"; broke=1; }
vac()   { echo "  ✗ VACUOUS: $1"; vacuous=1; }
blind() { echo "  ? UNMEASURED: $1"; unmeasured=1; }
drift() { echo "  ✗ DRIFT: $1"; drifted=1; }
note()  { echo "  · $1"; }
section() { printf '\n── %s %s\n' "$1" "$(printf '─%.0s' $(seq 1 $((56 - ${#1} > 0 ? 56 - ${#1} : 0))))"; }

# ─── §1 · the tools exist and run ─────────────────────────────────────
# Presence is measured by running them, not by `command -v`: a dangling
# symlink resolves on PATH and fails on use.
section "§1 · the tools run"
for t in julia lean lake elan; do
    if ! command -v "$t" >/dev/null 2>&1; then
        blind "$t is not on PATH — setup.sh has not run, or not as root"
    elif "$t" --version >/dev/null 2>&1; then
        pass "$t runs ($( "$t" --version 2>&1 | head -1 ))"
    else
        fail "$t is on PATH but exits nonzero on --version"
    fi
done

# ─── §2 · the egress workaround, in the shell that actually needs it ──
# BODY. The README's claim: setup.sh "sets JULIA_PKG_SERVER="" in
# /root/.bashrc, which makes Pkg fall back to git clones from GitHub".
# The derivation: ask Pkg, from a NON-INTERACTIVE shell with the variable
# absent from the environment — a script, a CI job, an agent session. If
# the workaround only reaches interactive bash, this is where it shows.
section "§2 · JULIA_PKG_SERVER reaches a non-interactive shell"
pkg_server_of() {   # $1: julia executable. Prints the resolved server or <none>.
    env -u JULIA_PKG_SERVER "$1" --startup-file=no \
        -e 'using Pkg; print(something(Pkg.pkg_server(), "<none>"))' 2>/dev/null
}
if ! command -v julia >/dev/null 2>&1; then
    blind "§2 needs julia on PATH"
else
    got=$(pkg_server_of "$(command -v julia)")
    case "$got" in
        "<none>") pass "Pkg resolves no package server — git fallback is live" ;;
        "")       blind "could not ask Pkg (julia ran but produced nothing)" ;;
        *)        fail "Pkg resolves '$got' — that host is blocked here, so every
          Pkg operation from a script or CI will fail. The fix in
          /root/.bashrc does not reach this shell." ;;
    esac

    # STRESS. The pre-fix install path is still on disk: setup.sh used to
    # symlink the conda binary straight onto PATH, so the raw binary IS the
    # mutant, no mocking needed. It must resolve the blocked host — if it
    # does not, §2 is detecting nothing and certifying it as a pass.
    if [ -x "$RAW_JULIA" ]; then
        raw=$(pkg_server_of "$RAW_JULIA")
        if [ "$raw" = "<none>" ]; then
            vac "the raw conda binary ALSO resolves no server, so §2 cannot
          tell a wrapped install from a bare symlink. Either Julia's
          default changed or JULIA_PKG_SERVER is set in this process."
        else
            pass "stress holds — the bare binary resolves '$raw', so §2 discriminates"
        fi
    else
        blind "no raw binary at $RAW_JULIA to stress §2 against"
    fi
fi

# ─── §2′ · the wrapped binary is a binary ─────────────────────────────
# A wrapper that wraps a wrapper passes every check above: §2 asks Pkg what
# server it resolved, and a self-exec'ing script never gets far enough to
# answer, or answers correctly on the one call that survives. This section
# exists because the first draft of the wrapper was installed with
# `cat > /usr/local/bin/julia`, which followed the symlink that path then was
# and overwrote the Julia executable. The repair held for the file it was
# aimed at and destroyed the file underneath it.
#
# So: the thing the wrapper execs must not itself start with `#!`.
section "§2′ · the wrapped executable is the real binary"
if [ ! -e "$RAW_JULIA" ]; then
    blind "nothing at $RAW_JULIA to inspect"
else
    magic=""; read -rn2 magic < "$RAW_JULIA" 2>/dev/null || true
    if [ "$magic" = "#!" ]; then
        fail "$RAW_JULIA is a shell script, not the Julia binary — something
          overwrote it (a \`cat >\` through the /usr/local/bin/julia symlink
          will do it). Julia on this box is a loop, not an interpreter."
    else
        pass "$RAW_JULIA does not start with a shebang"
    fi
    # And it must actually run, which a two-byte check cannot establish.
    if "$RAW_JULIA" -e 'exit(0)' >/dev/null 2>&1; then
        pass "stress holds — $RAW_JULIA executes Julia code"
    else
        fail "$RAW_JULIA will not run \`exit(0)\` — present, not usable"
    fi
fi

# ─── §3 · toolchain pins: the README table vs the installed toolchain ─
# The pin class pin_check.jl §5 counts as zero. Claimed side: the table in
# README.md. Derived side: the toolchain itself.
section "§3 · toolchain pins (claimed in $README, derived from the toolchain)"
claim_row() {       # $1: row label. Prints the first version on that row.
    grep -E "^\| *$1 *\|" "$README" 2>/dev/null \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}
installed_julia=$(julia --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
installed_lean=$(lean --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
installed_lake=$(lake --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

pin() {             # $1 name, $2 claimed, $3 derived, $4 pinned-by (or "unpinned")
    if [ -z "$3" ]; then
        blind "$1: nothing installed to derive from"
    elif [ -z "$2" ]; then
        fail "$1: no claim found in $README — the locator grips nothing, which
          reports as drift while meaning MISS (pin_check.jl §3′)"
    elif [ "$2" = "$3" ]; then
        pass "$1: table says $2, toolchain says $3 ($4)"
    else
        drift "$1: table says $2, toolchain says $3 ($4). Nothing is broken —
          the recorded measurement has expired. Update the table's
          measured line and re-run."
    fi
}
pin "julia" "$(claim_row Julia)" "$installed_julia" "unpinned: conda-forge latest"
pin "lean"  "$(claim_row Lean)"  "$installed_lean"  "pinned by LEAN_VERSION"
pin "lake"  "$(grep -oE 'Lake 5?[0-9]*\.[0-9]+\.[0-9]+' "$README" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)" \
            "$installed_lake" "ships with the Lean toolchain"

# STRESS for §3: a deliberately wrong claim must be caught. Without this the
# comparison above could be string-equal by construction and nobody would know.
if [ "999.0.0" = "$installed_julia" ]; then
    vac "§3 stress: a claim of 999.0.0 matched the toolchain"
else
    pass "stress holds — a wrong claim (999.0.0 vs $installed_julia) is caught"
fi

# ─── §4 · every lean-toolchain in the tree is actually installed ──────
# The README warns: "A lean-toolchain file pointing at a version other than
# the linked one will make elan try to download it from the blocked host."
# That is a silent, slow failure at the next `lake build`, so it is checked
# here instead of being discovered there.
section "§4 · lean-toolchain files name an installed toolchain"
if ! command -v elan >/dev/null 2>&1; then
    blind "§4 needs elan"
else
    linked=$(elan toolchain list 2>/dev/null)
    found=0
    while IFS= read -r f; do
        found=1
        want=$(tr -d '[:space:]' < "$f")
        if printf '%s\n' "$linked" | grep -qxF "$want"; then
            pass "$f wants $want — linked"
        else
            fail "$f wants $want, which is NOT linked. The next \`lake build\` here
          will try to fetch it from release.lean-lang.org (blocked).
          Re-run setup.sh with LEAN_VERSION=${want##*:v}"
        fi
    done < <(find . -name lean-toolchain -not -path './.git/*' | sort)
    [ "$found" = 1 ] || blind "no lean-toolchain files found in the tree"

    # STRESS: a name that cannot be installed must not be reported as linked.
    if printf '%s\n' "$linked" | grep -qxF 'leanprover/lean4:v0.0.0-nonexistent'; then
        vac "§4 stress: a fabricated toolchain name was found in elan's list"
    else
        pass "stress holds — a fabricated toolchain name is not matched"
    fi
fi

# ─── §5 · Lean elaborates, and can still refuse ───────────────────────
# House discipline, from paradoxes/lean/probe_run.sh: "an instrument that
# cannot fail certifies nothing". A `lean` that accepts everything would
# pass a compile check and prove nothing about the install.
section "§5 · lean elaborates, and refuses what it should"
if ! command -v lean >/dev/null 2>&1; then
    blind "§5 needs lean"
else
    work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
    printf 'theorem t : 1 + 1 = 2 := by decide\n' > "$work/ok.lean"
    if lean "$work/ok.lean" >/dev/null 2>&1; then
        pass "a true theorem elaborates"
    else
        fail "lean cannot elaborate \`1 + 1 = 2\` — the toolchain is not usable"
    fi
    printf 'theorem t : 1 + 1 = 3 := by decide\n' > "$work/bad.lean"
    if lean "$work/bad.lean" >/dev/null 2>&1; then
        vac "lean ACCEPTED \`1 + 1 = 3\` — §5 certifies nothing"
    else
        pass "stress holds — a false theorem is refused"
    fi
fi

# ─── §6 · what this check does not cover ──────────────────────────────
# Printing the incompleteness rather than implying it (pin_check.jl §4).
section "§6 · not covered here"
cat <<'EOF'
  · That `lake build` succeeds in paradoxes/lean and cosmos/lean. Minutes,
    not seconds, so it is not in the install path. Run it yourself; §4 only
    establishes that it will not reach for a blocked host first.
  · That Pkg can actually CLONE anything. §2 establishes the server is out
    of the way; it does not touch the network, deliberately — a check that
    needs egress cannot run in a box that has none.
  · The Julia version itself, which is unpinned by construction. §3 catches
    the RECORD going stale, not the toolchain moving. Set JULIA_VERSION to
    pin it if a result ever depends on the version.
  · Anything outside this tree. The `unreachable` class in pin_check.jl §5
    is still empty, and still where most of this repo's recorded errors
    actually landed.
  · Whether /usr/local/bin/julia is a symlink, a wrapper, or the binary
    itself. §2 and §2' check what it DOES, not what it is, because the next
    install method should not have to come back and edit this file.
EOF

# ─── verdict ──────────────────────────────────────────────────────────
section "verdict"
if   [ "$vacuous"    = 1 ]; then code=2; echo "  INSTRUMENT NOT TRUSTWORTHY — a stress mutation did not break its check."
elif [ "$broke"      = 1 ]; then code=1; echo "  A POSTCONDITION FAILED — the install does not do what setup.sh promises."
elif [ "$unmeasured" = 1 ]; then code=3; echo "  COULD NOT MEASURE — a tool was missing; this is a probe failure, not a pass."
elif [ "$drifted"    = 1 ]; then code=4; echo "  INSTALL OK, RECORD STALE — a recorded number drifted. Nothing is broken."
else code=0; echo "  every postcondition holds, and every stress mutation broke its check."
fi
echo
echo "exit $code — evidence, never proof."
exit $code
