# julia3claude

Julia + Lean development environment for Claude Code web sessions.

## Paradoxes

`paradoxes/` translates ~40 classical paradoxes — self-reference, infinity,
probability, decision theory, identity, vagueness — into runnable Julia,
exploiting the language's own machinery (`missing`, `quote`/`eval`, world
age, `==`/`===`/`isequal`, multiple dispatch, Float64) as formal semantics.
See [`paradoxes/README.md`](paradoxes/README.md) for the taxonomy of which
paradoxes resolve, which dissolve, and which merely relocate; run the suite
with `julia paradoxes/run_all.jl`.

`paradoxes/lean/` is the Lean 4 counterpart: 91 catalog entries across nine
modules (logic, set theory, infinity, epistemology, vagueness/identity,
probability/statistics, decisions/games, physics, metatheory) — proved
theorems, `decide`-verified exact checks, running demos and
`#guard_msgs`-captured rejections, on core Lean only (no Mathlib, no
`sorry`, no `axiom` declarations; the per-theorem axiom ledger is
machine-published by `Paradoxes/Audit.lean` at every build). Build with
`lake build`, print the annotated index with `lake exe paradoxes`. The two
suites talk to each other:
[`paradoxes/EXPRESSIBILITY.md`](paradoxes/EXPRESSIBILITY.md) (Julia's essay,
with six questions for Lean),
[`paradoxes/lean/EXPRESSIBILITY-ANSWERS.md`](paradoxes/lean/EXPRESSIBILITY-ANSWERS.md)
(Lean's machine-checked reply), and the audit exchange on PR #2 (whose
accepted findings — including "chiasmus v3" — are folded into the suite).

## Cosmos

`cosmos/` is the same dialogue aimed at the sky. `stellar_collapse.jl`
(Julia) integrates stellar death from scratch: Lane–Emden n=3 → the
Chandrasekhar mass, a TOV sweep exposing the neutron-star maximum as a
saddle-node fold, Buchdahl's forbidden strip, GW170817's chirp mass.
`cosmos/lean/` answers in Lean: the same integrations in fuel-bounded
`Float` numerics (ξ₁ = 6.8969, M_Ch = 1.456 M☉, chirp 1.188 M☉ under a
compile-time `#guard`), and then the move Julia cannot make — the sweep's
fold **shape** re-verified by the kernel: the computed mass table is frozen
as integer literals and `decide` proves it strictly rises to a unique
maximum and falls (`fold_shape`), stays inside Buchdahl's 8/9 bound
(`buchdahl_strip`), with non-vacuity mutants rejected. Build:
`cd cosmos/lean && lake build && lake exe cosmos`.

## Fold

`fold/Fold.lean` is the hinge nobody had built: the star and the Liar
satisfy the same criterion. `cosmos/` says collapse is "the physics of an
empty solution set"; the emergence thread says antinomy is "emptiness of
the fixed locus"; `paradoxes/` proves `¬∃ P, P ↔ ¬P`. One sentence, three
costumes, arrived at on three branches that never met. The file makes the
identification checkable (a fixed-point pair that *annihilates* as a
parameter crosses — not defeated, nonexistent) and then asks what the
identification raises and no thread had asked: if a dying star and the
Liar share a criterion, why does one collapse and the other oscillate
forever? Answer, proved: the fate is decided by **boundedness**, not by
the twist — a bounded world cannot host an inflationary map at all, so
its fixed-point-freeness must be bought by coming back down, which is
what oscillation is. `Bool` has a ceiling; stellar density does not.
Runs bare: `lean fold/Fold.lean` — exit 0, prints its own ledger.

## Emergence (cross-repo)

`emergence-reply/` stages this repo's Lean instance joining the
Spencer-Brown emergence thread in
[`irreducible-mystery/julia`](https://github.com/irreducible-mystery/julia):
`CombinerGalois.lean` answers that thread's sharpened Galois/combiner
question in the kernel court (affine combiners license kernel-first
prediction everywhere; max nowhere — and the boundary opens exactly at
shared listening and is modulus-relative). See
[`emergence-reply/README.md`](emergence-reply/README.md) for the landing
instructions (this session lacked push rights to that repo).

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
