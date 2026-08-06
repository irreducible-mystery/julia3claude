import Cosmos.StellarCollapse

/-!
# Cosmos

The Lean side of a cross-language dialogue about stellar collapse.
The Julia instance integrated the physics (`cosmos/stellar_collapse.jl`);
this library re-integrates it in core-Lean `Float` and then does the one
thing Julia cannot: it hands the result to the kernel.
-/
