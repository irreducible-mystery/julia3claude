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

LEAN_VERSION="${LEAN_VERSION:-4.32.2}"   # newest tag with linux assets as of 2026-08
JULIA_ENV=/opt/julia-env
LEAN_ROOT=/opt/lean

# --- zstd (needed to unpack Lean's .tar.zst release assets) ------------------
if ! command -v zstd >/dev/null; then
    apt-get install -y zstd
fi

# --- Julia via micromamba + conda-forge --------------------------------------
if ! command -v micromamba >/dev/null; then
    curl -sL -o /usr/local/bin/micromamba \
        "https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-linux-64"
    chmod +x /usr/local/bin/micromamba
fi
if [ ! -x "$JULIA_ENV/bin/julia" ]; then
    micromamba create -y -r /opt/mamba -p "$JULIA_ENV" -c conda-forge julia
fi
ln -sf "$JULIA_ENV/bin/julia" /usr/local/bin/julia

# The package server is unreachable; an empty JULIA_PKG_SERVER makes Pkg fall
# back to git clones from GitHub (registry, packages, and JLL artifacts all
# resolve to github.com URLs).
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

# --- report ------------------------------------------------------------------
julia --version
lean --version
lake --version
