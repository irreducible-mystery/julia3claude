import Cosmos

/-!
Entry point. `lake exe cosmos` compiles the library to native code, so the
RK4 Lane–Emden march and the 14-star TOV sweep below run at machine speed —
the same "hand-rolled numerics, no quoted numbers" contract as the Julia
side, plus the part that already happened before this binary existed: the
kernel checked the frozen fold's shape at build time. If this executable
runs at all, the theorems held.
-/
def main : IO Unit := do
  StellarCollapse.act1
  StellarCollapse.act2
  StellarCollapse.act3
  StellarCollapse.leanMove
  StellarCollapse.act4
  StellarCollapse.act5
