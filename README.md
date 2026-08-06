# julia3claude
DEFINING AN ARBITRARY FLOOR IS NOT A PROBLEM. FORGETTING THAT IT IS AN ABRITRARY FLOOR IS. THERE IS NO FLOOR. THERE IS NO CEILING. 
Julia + Lean development environment for Claude Code web sessions.

## Paradoxes

`paradoxes/` translates ~40 classical paradoxes — self-reference, infinity,
probability, decision theory, identity, vagueness — into runnable Julia,
exploiting the language's own machinery (`missing`, `quote`/`eval`, world
age, `==`/`===`/`isequal`, multiple dispatch, Float64) as formal semantics.
See [`paradoxes/README.md`](paradoxes/README.md) for the taxonomy of which
paradoxes resolve, which dissolve, and which merely relocate; run the suite
with `julia paradoxes/run_all.jl`.

## Toolchains

| Tool  | Version | Source |
|-------|---------|--------|
| Julia | 1.12.6  | official conda-forge build, via micromamba |
| Lean  | 4.32.2 (+ Lake 5.0.0) | official GitHub release asset, registered with elan |

Run `./setup.sh` (as root) to install both. The script is idempotent.

## Why the setup is unusual

This environment's egress policy allows `github.com`, `conda.anaconda.org`,
the Ubuntu archive, and the major language package registries — but blocks the
hosts the official Julia/Lean installers rely on:

- `install.julialang.org`, `julialang-s3.julialang.org`, `pkg.julialang.org`
  (juliaup and the Pkg package server)
- `elan.lean-lang.org`, `release.lean-lang.org` (elan's installer and its
  toolchain download server)

`setup.sh` therefore:

1. installs **Julia** from conda-forge (the official binary build published
   there) using micromamba, which is itself fetched from GitHub releases;
2. installs **elan** from its GitHub release tarball with
   `--default-toolchain none`, downloads the Lean toolchain directly from
   `leanprover/lean4` GitHub release assets, and registers it via
   `elan toolchain link`.

## Package management notes

- **Julia Pkg** works with the package server disabled: `setup.sh` sets
  `JULIA_PKG_SERVER=""` in `/root/.bashrc`, which makes Pkg fall back to git
  clones from GitHub for the General registry and packages, and to GitHub
  release assets for JLL binary artifacts.
- **Lake/Lean** projects build offline once the toolchain is installed.
  Dependencies hosted on GitHub (e.g. mathlib4 sources) are cloneable;
  `lake exe cache get` for mathlib downloads olean caches from
  `releases.lake-lang.org` / Azure, which may be blocked — expect to build
  mathlib from source if so.
- A `lean-toolchain` file pointing at a version other than the linked one will
  make elan try to download it from the blocked host. Re-run `setup.sh` with
  `LEAN_VERSION=<x.y.z>` to side-load a different version first.
