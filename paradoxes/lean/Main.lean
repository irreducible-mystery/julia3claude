import Paradoxes

/-- Pretty-print one module's catalog. -/
def printCatalog (title : String) (entries : List (String × String)) : IO Unit := do
  IO.println s!"\n═══ {title} ({entries.length} entries) ═══"
  for (name, status) in entries do
    IO.println s!"  • {name}"
    IO.println s!"      {status}"

def catalogs : List (String × List (String × String)) :=
  [ ("Self-reference & semantics",        Paradoxes.SelfReference.catalog),
    ("Diagonalization: sets & computation", Paradoxes.Diagonal.catalog),
    ("The infinite",                       Paradoxes.Infinity.catalog),
    ("Knowledge & belief",                 Paradoxes.EpistemicBelief.catalog),
    ("Vagueness, identity & the classics", Paradoxes.VagueIdentity.catalog),
    ("Probability & statistics",           Paradoxes.Probability.catalog),
    ("Decisions, games & economics",       Paradoxes.DecisionGames.catalog),
    ("Physics",                            Paradoxes.Physics.catalog),
    ("Expressibility: answers to the Julia instance", Paradoxes.Expressibility.catalog) ]

def main : IO Unit := do
  IO.println "PARADOXES ACROSS DOMAINS — formalized, verified, and run in core Lean 4"
  IO.println "(statuses: THEOREM = proved · VERIFIED = decided finite/exact check ·"
  IO.println " DEMO = executed exhibit · GUARDED = rejection captured by #guard_msgs ·"
  IO.println " NOTE = honestly not formalizable here, and why)"
  for (title, entries) in catalogs do
    printCatalog title entries
  let total := (catalogs.map (·.2.length)).sum
  let count (pfx : String) : Nat :=
    (catalogs.map (fun c => (c.2.filter (fun e => e.2.startsWith pfx)).length)).sum
  IO.println s!"\n═══ TOTAL: {total} entries — {count "THEOREM"} THEOREM, {count "VERIFIED"} VERIFIED, {count "DEMO"} DEMO, {count "GUARDED"} GUARDED, {count "NOTE"} NOTE ═══"
