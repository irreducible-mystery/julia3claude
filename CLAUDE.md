# CLAUDE.md — irreducible-mystery/julia3claude

Project memory for sessions working in this repository. It describes what is
here, how to get the toolchains installed in a sandboxed environment, and the
conventions the existing files already follow.

## What this repository is

A Julia + Lean working environment, and the studies built in it. Most of the
content is the same move repeated on different subject matter: take a body of
claims, run it in Julia where meaning is execution, assert it in Lean where
meaning is a kernel-checked theorem, and keep the disagreement between the two
as the result.

## Layout

| Path | Contents |
|---|---|
| `setup.sh` | Installs Julia and Lean. Idempotent, run as root. See *Toolchain* — the detour it takes is the point. |
| `paradoxes/` | ~40 classical paradoxes as runnable Julia (`01_…` … `12_…`), using the language's own machinery (`missing`, `quote`/`eval`, world age, `==`/`===`/`isequal`, dispatch, `Float64`) as formal semantics |
| `paradoxes/lean/` | The Lean 4 counterpart: 91 catalog entries across nine modules, core Lean only |
| `paradoxes/rust/` | A Rust port of the Lean suite's Probability and DecisionGames modules, `std` only, with a from-scratch `BigNat` |
| `paradoxes/EXPRESSIBILITY.md`, `lean/EXPRESSIBILITY-ANSWERS.md`, `TENSIONS.md` | The cross-language exchange, and the ledger of claims broken by contact with the sibling repo `julia2` |
| `cosmos/` | Stellar collapse: `stellar_collapse.jl` integrates Lane–Emden n=3, a TOV sweep, Buchdahl's bound and GW170817 from scratch; `cosmos/lean/` answers in core-Lean `Float` and freezes the mass table so the kernel can check the fold's *shape* |
| `paraconsistent/` | A five-session arc on Paraconsistent Annotated Evidential Logic Eτ (PAL2v) in Python, ending with the instrument turned on itself; reports, figures and CSVs under `paraconsistent/results/` |
| `emergence-reply/` | A contribution staged for `irreducible-mystery/julia`, left here because that session had no push rights; `CombinerGalois.lean` plus landing instructions |

There is no `.github/` directory and no CI.

## Toolchain

| Tool | Version | Source |
|---|---|---|
| Julia | 1.12.6 | official conda-forge build, via micromamba |
| Lean | 4.32.2 (+ Lake 5.0.0) | official GitHub release asset, registered with elan |

`./setup.sh` (as root) installs both and is safe to re-run. It takes an unusual
route because the typical sandbox egress policy here allows `github.com`,
`conda.anaconda.org`, the Ubuntu archive and the major package registries, but
blocks the languages' own download hosts — `install.julialang.org`,
`julialang-s3.julialang.org`, `pkg.julialang.org`, `elan.lean-lang.org`,
`release.lean-lang.org`. Consequences worth knowing before you debug a hang:

- Julia `Pkg` works only with the package server disabled. `setup.sh` sets
  `JULIA_PKG_SERVER=""` in `/root/.bashrc`, which makes Pkg fall back to git
  clones from GitHub and to GitHub release assets for JLL artifacts.
- Lake builds offline once the toolchain is installed. `lake exe cache get` for
  Mathlib pulls from hosts that may be blocked — expect a source build if so.
- A `lean-toolchain` file naming a version other than the linked one sends elan
  to a blocked host. Side-load it first with `LEAN_VERSION=<x.y.z> ./setup.sh`.

The committed `lean-toolchain` files pin `leanprover/lean4:v4.32.2`.

## Running

```sh
julia paradoxes/run_all.jl                      # every paradoxes/*.jl, in filename order
cd paradoxes/lean && lake build && lake exe paradoxes   # 9 modules, then the annotated catalog
cd paradoxes/rust && cargo test && cargo run    # the ported theorems, then the demos
julia cosmos/stellar_collapse.jl
cd cosmos/lean && lake build && lake exe cosmos # kernel checks at build time, then the five acts
python paraconsistent/experiment1_conflicting_data.py   # each script is standalone
```

Julia and Lean work use the standard library / core only — no packages, no
Mathlib. `paraconsistent/` is the exception and needs `paraconsistent`, `numpy`,
`pandas`, `matplotlib`, `scikit-learn`.

## Conventions

1. **Every claim is executed or proved, and scored honestly.** The Lean modules
   each end with a `catalog : List (String × String)` that grades their own
   entries: `THEOREM:` fully proved, `IDENTITY:` proved but unfolding to the
   modeling definitions, `VERIFIED:` exact finite check by `decide`, `DEMO:` an
   executed `#eval` exhibit. Keep that grading accurate rather than flattering.
2. **No `sorry`, no `axiom` declarations, no `partial`.** Assumptions appear as
   explicit hypotheses of the theorem; loops are fuel-bounded and total.
   `Paradoxes/Audit.lean` machine-publishes the per-theorem axiom ledger at
   every build, and classical uses of `Classical.choice` are flagged per entry.
3. **Trust boundaries are stated.** In `cosmos/lean`, the Float integrations are
   trusted as computation exactly like Julia's; the theorems certify only the
   frozen table. Say which part the kernel actually covers.
4. **Non-vacuity controls.** Mutants that must be rejected ship alongside the
   checks, so a theorem cannot pass by saying nothing.
5. **Corrections are recorded, not patched over.** `TENSIONS.md` is the two-way
   ledger of claims this repo now knows it overclaimed; the original text stays
   and the correction is written down next to it.
6. **Each directory's `README.md` is its index** — contents table, build
   commands and status taxonomy. Update it in the same change as the code.

## If you are changing things here

- Build what you touch: `lake build` for Lean, `julia <file>` for Julia,
  `cargo test` for Rust. A Lean change that elaborates is not the same as one
  whose catalog entry is still true.
- Keep the dependency-free constraint for Julia, Lean and Rust; it is what lets
  these suites build in a sandbox with most hosts blocked.
- If the toolchain will not install, read `setup.sh`'s header comment before
  reaching for the official installers — they are blocked here by design.
