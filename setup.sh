#!/usr/bin/env bash
# Install the Julia and Lean toolchains in a Claude Code web session (or any
# sandboxed Linux x86_64 box whose egress allows github.com, conda.anaconda.org,
# and the Ubuntu archive, but blocks the languages' own download hosts).
#
# Why not the official installers?
#   - install.julialang.org, julialang-s3.julialang.org and pkg.julialang.org
#     are blocked, so juliaup cannot download Julia. The official conda-forge
#     build (conda.anaconda.org) is used instead, fetched with micromamba.
#   - elan.lean-lang.org and release.lean-lang.org are blocked, so elan cannot
#     resolve or download toolchains itself. elan and the Lean toolchain are
#     fetched straight from their GitHub release assets and registered with
#     `elan toolchain link`.
#
# Idempotent: each step is skipped when its result already exists.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LEAN_VERSION="${LEAN_VERSION:-4.32.2}"   # newest tag with linux assets as of 2026-08
JULIA_VERSION="${JULIA_VERSION:-}"       # empty = whatever conda-forge publishes today
JULIA_ENV=/opt/julia-env
LEAN_ROOT=/opt/lean

# --- zstd (needed to unpack Lean's .tar.zst release assets) ------------------
if ! command -v zstd >/dev/null; then
    # No `apt-get update` first, because an image that already has package
    # lists does not need one. If the lists are stale or absent the install
    # 404s, so that case refreshes and retries rather than aborting under
    # `set -e`. Not observed failing in this sandbox; it is one line.
    apt-get install -y zstd || { apt-get update && apt-get install -y zstd; }
fi

# --- Julia via micromamba + conda-forge --------------------------------------
if ! command -v micromamba >/dev/null; then
    curl -sL -o /usr/local/bin/micromamba \
        "https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-linux-64"
    chmod +x /usr/local/bin/micromamba
fi
if [ ! -x "$JULIA_ENV/bin/julia" ]; then
    micromamba create -y -r /opt/mamba -p "$JULIA_ENV" -c conda-forge \
        "julia${JULIA_VERSION:+==$JULIA_VERSION}"
fi

# The package server is unreachable; an empty JULIA_PKG_SERVER makes Pkg fall
# back to git clones from GitHub (registry, packages, and JLL artifacts all
# resolve to github.com URLs). An UNSET one resolves to pkg.julialang.org,
# which is blocked, so this is not a preference — nothing Pkg does works
# without it.
#
# It used to be exported from /root/.bashrc alone, and /usr/local/bin/julia
# was a bare symlink to the conda binary. Bash reads .bashrc only when it is
# interactive: a script, a CI job, a `bash -lc`, and this repo's own agent
# sessions all got an unset variable and reached for the blocked host. The
# fix was in the shell; the failure was in every other shell. So it is
# exported here instead, in a wrapper every invocation must pass through —
# the same move as putting a probe inside its instrument rather than in the
# protocol around it. `${JULIA_PKG_SERVER-}` defaults it to empty while
# leaving an explicitly set value (even a non-empty one) alone, so a box
# with a reachable server can still use it.
#
# setup_check.sh §2 is the check, and it fails on the pre-wrapper install.
#
# THE `rm -f` IS LOAD-BEARING, and this is the second time the same shape bit
# this file. /usr/local/bin/julia was a SYMLINK to the conda binary, so the
# first draft's `cat > /usr/local/bin/julia` followed it and overwrote the
# Julia executable with the wrapper — which then exec'd itself forever. A fix
# whose own failure path destroys the thing it was protecting. Written to a
# temp file and moved into place: `mv` replaces the link, it does not follow
# it. setup_check.sh §2′ is the check for THAT, and it reads the first two
# bytes of the real binary, because a wrapper that wraps a wrapper looks
# exactly like a working install from outside.
tmp_wrapper=$(mktemp)
cat > "$tmp_wrapper" <<'WRAPPER'
#!/usr/bin/env bash
# Installed by julia3claude/setup.sh. See setup_check.sh §2 for why this is a
# wrapper and not a symlink: an unset JULIA_PKG_SERVER resolves to the
# blocked pkg.julialang.org, and exporting it from .bashrc reaches only
# interactive bash.
REAL=/opt/julia-env/bin/julia
# Refuse to exec a script: if $REAL is ever itself a wrapper (it was, once,
# for one afternoon), exec would loop until the process table filled. Pure
# builtin, no subprocess, so it costs nothing per invocation.
magic=""; read -rn2 magic < "$REAL" 2>/dev/null || true
if [ "$magic" = "#!" ]; then
    echo "julia: $REAL is a shell script, not the Julia binary." >&2
    echo "       Something overwrote it. Restore it before using Julia:" >&2
    echo "       re-run julia3claude/setup.sh after deleting $REAL," >&2
    echo "       or extract bin/julia from the cached conda package under" >&2
    echo "       /opt/mamba/pkgs/https/.../julia-*.conda (a zip holding" >&2
    echo "       pkg-julia-*.tar.zst)." >&2
    exit 70
fi
export JULIA_PKG_SERVER="${JULIA_PKG_SERVER-}"
exec "$REAL" "$@"
WRAPPER
chmod 755 "$tmp_wrapper"
rm -f /usr/local/bin/julia          # the link, never through the link
mv "$tmp_wrapper" /usr/local/bin/julia

# Kept as well: the REPL is the one place a reader might set it by hand, and
# seeing it in .bashrc explains why. It is no longer load-bearing.
grep -q JULIA_PKG_SERVER /root/.bashrc || echo 'export JULIA_PKG_SERVER=""' >> /root/.bashrc

# --- Lean via elan, toolchain side-loaded from GitHub ------------------------
if [ ! -x /root/.elan/bin/elan ]; then
    tmp=$(mktemp -d)
    curl -sL -o "$tmp/elan.tar.gz" \
        "https://github.com/leanprover/elan/releases/latest/download/elan-x86_64-unknown-linux-gnu.tar.gz"
    tar xzf "$tmp/elan.tar.gz" -C "$tmp"
    # --default-toolchain none: resolving "stable" needs release.lean-lang.org
    "$tmp/elan-init" -y --default-toolchain none
    rm -rf "$tmp"
fi
export PATH="/root/.elan/bin:$PATH"
grep -q '.elan/bin' /root/.bashrc || echo 'export PATH="$HOME/.elan/bin:$PATH"' >> /root/.bashrc

if [ ! -d "$LEAN_ROOT/lean-$LEAN_VERSION-linux" ]; then
    mkdir -p "$LEAN_ROOT"
    curl -sL -o "$LEAN_ROOT/lean.tar.zst" \
        "https://github.com/leanprover/lean4/releases/download/v$LEAN_VERSION/lean-$LEAN_VERSION-linux.tar.zst"
    tar --zstd -xf "$LEAN_ROOT/lean.tar.zst" -C "$LEAN_ROOT"
    rm -f "$LEAN_ROOT/lean.tar.zst"
fi
elan toolchain link "leanprover/lean4:v$LEAN_VERSION" "$LEAN_ROOT/lean-$LEAN_VERSION-linux" 2>/dev/null || true
elan default "leanprover/lean4:v$LEAN_VERSION"
ln -sf /root/.elan/bin/lean /root/.elan/bin/lake /root/.elan/bin/elan /usr/local/bin/

# --- check, not report -------------------------------------------------------
# This used to print three version strings. A printed version cannot tell a
# working install from a broken one, which is how the JULIA_PKG_SERVER defect
# above survived: every run of this script reported success while `using Pkg`
# from a script reached for a blocked host. The postconditions are now checked
# and the exit code says which class failed. No `|| true`.
# `set -e` would kill the script on a nonzero check before the dispatch below
# could say which class of failure it was, so the status is captured instead.
# That is not a `|| true`: nothing is swallowed, every class is named, and the
# script exits with the check's own code.
echo
rc=0
"$HERE/setup_check.sh" || rc=$?
case $rc in
  0) ;;
  1) echo "setup.sh: a postcondition FAILED — the install is not usable as documented" ;;
  2) echo "setup.sh: the CHECK ITSELF is not trustworthy — a stress mutation did not fire" ;;
  3) echo "setup.sh: a tool could not be measured — treat this as a failed probe, not a pass" ;;
  4) echo "setup.sh: INSTALL OK. A recorded number in README.md has drifted — nothing is"
     echo "          broken; update the table's measured line. This exits nonzero on"
     echo "          purpose: drift costs a red run instead of waiting to be found later." ;;
  *) echo "setup.sh: setup_check.sh exited $rc (unclassified)" ;;
esac
exit $rc
