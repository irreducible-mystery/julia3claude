"""
BLACK HOLE PHYSICS under Paraconsistent Annotated Evidential Logic Etau (PAL2v).

Black holes are the sharpest known locus of inter-theoretic contradiction:
General Relativity (GR) and Quantum Mechanics (QM) are each supported by
overwhelming evidence in their own domains, yet at the horizon and the
singularity they issue directly opposed verdicts. We encode four core
puzzles as evidence annotations (mu, lam) and analyze them on the lattice.

  A. INFORMATION PARADOX -- proposition H_info: "information escapes in the
     Hawking radiation (evaporation is unitary)".
       mu  <- unitarity of QM + Page-curve entropy accounting + (post-2019)
              replica-wormhole islands calculations
       lam <- Hawking's 1975 semiclassical result: exactly thermal radiation,
              no dependence on infallen state
     Encoded AS A FUNCTION OF EVAPORATION TIME using Page's theorem: before
     the Page time the two accounts numerically agree; the contradiction is
     LOCALIZED in the late-time regime.

  B. FIREWALL (AMPS) PARADOX -- the postulate triple {unitarity, no-drama,
     semiclassical EFT at the horizon} is jointly inconsistent via monogamy
     of entanglement. We fuse the three postulates in a paraconsistent
     network, exhibit the inconsistency, then test each of the three
     candidate resolutions (drop one postulate) for restored consistency.

  C. THE SINGULARITY -- proposition H_sing(r): "GR's description is valid at
     areal radius r". Evidence sweep from the horizon down to the Planck
     length: curvature-invariant blowup erodes favorable evidence while the
     Penrose singularity theorem GUARANTEES geodesic incompleteness (the
     theory certifies its own boundary). Question: is r=0 an INCONSISTENT
     state (dct -> +1) or a PARACOMPLETE one (dct -> -1)? PAL2v can tell
     these apart; classical logic cannot.

  D. COMPLEMENTARITY -- observer-relative annotations. The infalling
     observer (Alice) and the external observer (Bob) each have a fully
     consistent story; only the illegitimate "superobserver" fusion of both
     produces contradiction. PAL2v formalizes WHY complementarity works:
     annotations indexed by observer never explode; fusing them does.

Physical inputs used (order-of-magnitude, standard values):
  - Page time t_Page ~ 0.54 * t_evap  (Page 1993)
  - Curvature at horizon of solar-mass BH: K ~ 1/(GM)^4 -> tiny; at r->0: divergent
  - Planck length l_p = 1.6e-35 m; horizon r_s(M_sun) = 2.95e3 m
"""
import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from paraconsistent.blocks import ParaconsistentBlock

FTC = 0.5

def pal(mu, lam, ftc=FTC):
    b = ParaconsistentBlock()
    b.config.FtC = ftc
    b.input.mu = float(np.clip(mu, 0, 1))
    b.input.lam = float(np.clip(lam, 0, 1))
    return b.complete

def show(tag, c, note=""):
    dec = {1.0: "ACCEPT", 0.0: "REJECT", 0.5: "UNDECIDED"}[c.decision_output]
    print(f"  {tag:<38} (mu={c.mu:.2f},lam={c.lam:.2f}) dc={c.dc:+.3f} "
          f"dct={c.dct:+.3f} region={c.label:<6} {dec}")
    if note:
        print(f"    -> {note}")
    return dict(item=tag, mu=c.mu, lam=c.lam, dc=c.dc, dct=c.dct,
                region=c.label, decision=dec)

rows = []

# =====================================================================
# A. INFORMATION PARADOX -- time-resolved
# =====================================================================
print("=" * 78)
print("A. BLACK HOLE INFORMATION PARADOX (time-resolved along evaporation)")
print("=" * 78)
print("""H_info: 'information escapes; evaporation is unitary'
Page's theorem: for t < t_Page (~54% of lifetime) the ENTANGLEMENT ENTROPY of
radiation predicted by unitarity is NUMERICALLY IDENTICAL to Hawking's thermal
entropy -- the two theories agree early on. They diverge only after t_Page:
Hawking's curve keeps rising (information loss), Page's curve turns down
(information return). We encode instantaneous evidence at each time:
  mu(t)  = unitary account's support = 1 - (normalized gap it must explain)
  lam(t) = thermal account's counter-evidence = normalized entropy gap
plus constant background weights: QM unitarity is tested to extreme precision
(w_qm=0.95), semiclassical gravity is tested only indirectly (w_sc=0.85).""")

t = np.linspace(0.001, 1.0, 400)          # fraction of evaporation lifetime
t_page = 0.54
# normalized entropy curves (units of max entanglement entropy)
S_hawking = t / t_page * (t <= t_page) + (t > t_page) * (t / t_page)   # keeps rising
S_hawking = t * 1.85                                                   # linear rise, thermal
S_page = np.minimum(t * 1.85, (1 - t) * 1.85 * (t_page/(1-t_page)))    # rises then falls
gap = np.abs(S_hawking - S_page) / S_hawking.max()                      # normalized disagreement

w_qm, w_sc = 0.95, 0.85
mu_t  = w_qm * (1 - 0.0 * gap)          # unitarity's support is theory-wide, constant
lam_t = w_sc * gap / gap.max()          # thermal counter-evidence grows with the gap
dc_t  = np.array([pal(m, l).dc  for m, l in zip(mu_t, lam_t)])
dct_t = np.array([pal(m, l).dct for m, l in zip(mu_t, lam_t)])
regions_t = [pal(m, l).label for m, l in zip(mu_t, lam_t)]

i_page = np.argmin(np.abs(t - t_page))
i_late = -1
print(f"\n  early time  (t=0.10 t_evap): dc={dc_t[40]:+.3f} dct={dct_t[40]:+.3f} region={regions_t[40]}")
print(f"  Page time   (t=0.54 t_evap): dc={dc_t[i_page]:+.3f} dct={dct_t[i_page]:+.3f} region={regions_t[i_page]}")
print(f"  end stage   (t=1.00 t_evap): dc={dc_t[i_late]:+.3f} dct={dct_t[i_late]:+.3f} region={regions_t[i_late]}")
first_conflict = t[np.argmax(dct_t > 0.25)]
print(f"  contradiction becomes significant (dct>0.25) at t = {first_conflict:.2f} t_evap"
      f"  -- i.e. AFTER the Page time: PAL2v localizes the paradox in late-time"
      f"  radiation, exactly where the replica-wormhole 'islands' fix operates.")
rows.append(show("A. info paradox @ end-stage", pal(mu_t[-1], lam_t[-1]),
    "Late-time: high mu AND high lam -> quasi-inconsistent band. The paradox is not "
    "'QM vs GR everywhere' but a localized late-time contradiction."))

# post-2019 update: island formula reproduces Page curve WITHIN semiclassical gravity
print("\n  Post-2019 update (Penington; Almheiri et al.): replica-wormhole islands")
print("  derive the Page curve from semiclassical gravity itself -> the thermal")
print("  counter-evidence at late times is revised sharply downward:")
rows.append(show("A. info paradox after islands", pal(0.95, 0.25),
    "Contradiction drains away: dct drops toward 0, region moves into 't'. "
    "PAL2v cleanly represents PARADOX RESOLUTION as evidence revision -- the "
    "lattice position migrates from quasi-inconsistent to true."))

# =====================================================================
# B. FIREWALL (AMPS) PARADOX
# =====================================================================
print("\n" + "=" * 78)
print("B. AMPS FIREWALL PARADOX (monogamy of entanglement)")
print("=" * 78)
print("""Three postulates, each individually near-certain:
  P1 unitarity (Page curve)         : late radiation R maximally entangled with early radiation E
  P2 no-drama (equivalence princ.)  : infalling mode B maximally entangled with interior partner A
  P3 semiclassical EFT at horizon   : B is the SAME mode as R's purifier
Monogamy of entanglement: B cannot be maximally entangled with BOTH E and A.
Encode H_smooth: 'the horizon is smooth (no firewall)'.
  mu  <- P2 evidence (equivalence principle: tested to 1e-15, but only in
         low-curvature regimes; horizon extrapolation discounts it)
  lam <- P1+P3 jointly force B entangled with E, contradicting smoothness""")
P1, P2, P3 = 0.95, 0.90, 0.85     # evidential weights of the postulates
c = pal(P2, P1 * P3)
rows.append(show("B. smooth horizon (all 3 postulates)", c,
    "Region ┬-adjacent: near-maximal contradiction. The postulate TRIPLE is "
    "jointly inconsistent even though each member is individually near-certain -- "
    "the signature of a genuine theoretical paradox, now quantified."))

print("\n  Testing the three candidate resolutions (drop/discount one postulate):")
resolutions = [
    ("drop P1 (Hawking: info loss)",      pal(P2, 0.10 * P3)),
    ("drop P2 (AMPS: firewall exists)",   pal(0.10, P1 * P3)),
    ("drop P3 (complementarity/ER=EPR)",  pal(P2, P1 * 0.10)),
]
for name, cc in resolutions:
    rows.append(show(f"B. {name}", cc))
print("""    -> Each drop restores |dct| ~ 0 and a decisive verdict, but lands in a
    DIFFERENT region: drop-P1 & drop-P3 restore 't' (smooth horizon), drop-P2
    restores 'f' (firewall). PAL2v shows the paradox is exactly a 3-way
    forced choice, and measures how much evidence each escape route burns.""")

# =====================================================================
# C. THE SINGULARITY -- GR validity sweep to the Planck scale
# =====================================================================
print("\n" + "=" * 78)
print("C. THE SINGULARITY: paracompleteness, not inconsistency")
print("=" * 78)
print("""H_GR(r): 'GR's spacetime description is valid at radius r' (solar-mass BH).
  mu(r)  <- empirical support, eroded as Kretschmann curvature K(r) ~ 48G^2M^2/r^6
            approaches the Planck curvature (quantum gravity regime)
  lam(r) <- positive counter-evidence AGAINST the description. Crucially, near
            r=0 there is no experiment refuting GR -- there is NO EVIDENCE AT
            ALL. lam grows only mildly (theoretical unease), it does not -> 1.
The question PAL2v can pose and classical logic cannot:
  is the singularity ┬ (contradiction: over-determined) or ┴ (paracomplete:
  UNDER-determined, theory silence)?""")

r_s = 2.95e3                      # Schwarzschild radius, solar mass (m)
l_p = 1.616e-35                   # Planck length (m)
r = np.logspace(np.log10(r_s), np.log10(l_p), 300)
# curvature ratio to Planck curvature: K/K_p = (l_p^2 * sqrt(48) G M / r^3)^2 approx
# use log-scaled proximity-to-Planck measure
x = (np.log10(r_s) - np.log10(r)) / (np.log10(r_s) - np.log10(l_p))   # 0 at horizon -> 1 at l_p
mu_r  = 1 / (1 + np.exp(14 * (x - 0.80)))    # near-1 until deep interior, collapses near Planck
lam_r = 0.05 + 0.15 * x                      # mild theoretical unease only -- no refuting data
dc_r  = np.array([pal(m, l).dc  for m, l in zip(mu_r, lam_r)])
dct_r = np.array([pal(m, l).dct for m, l in zip(mu_r, lam_r)])

for frac, tag in ((0.0, "horizon r_s"), (0.5, "deep interior"), (0.8, "quantum-gravity onset"), (1.0, "r -> l_p")):
    i = int(frac * (len(r) - 1))
    cc = pal(mu_r[i], lam_r[i])
    rows_i = show(f"C. GR validity @ {tag}", cc)
    if frac in (0.0, 1.0):
        rows.append(rows_i)
print("""    -> As r -> l_p the state slides DOWN the lattice toward ┴ (paracomplete):
    dct -> -0.8, not +1. VERDICT: the singularity is not a contradiction in
    nature; it is a region where our theory GOES SILENT (evidence-starved).
    Penrose's theorem is thus reread: GR proves its own incompleteness --
    a Godel-like self-certification, marked ┴, awaiting quantum gravity.
    Contrast: the INFORMATION paradox trends toward ┬ (over-determined).
    Same black hole, two opposite epistemic pathologies -- only a
    two-dimensional logic can distinguish them.""")

# =====================================================================
# D. BLACK HOLE COMPLEMENTARITY -- observer-indexed annotations
# =====================================================================
print("\n" + "=" * 78)
print("D. COMPLEMENTARITY: observer-indexed annotations & the superobserver")
print("=" * 78)
print("""H_cross: 'Alice's infalling qubit is inside the horizon at time t_B'.
  Alice (infalling): crosses uneventfully (no-drama). Her evidence: qubit inside.
  Bob (external): sees infalling matter red-shifted, 'scrambled' on the stretched
  horizon, and re-emitted in radiation. His evidence: qubit OUTSIDE (never crossed).""")
alice = pal(0.95, 0.05)
bob   = pal(0.05, 0.95)
rows.append(show("D. Alice's frame: qubit inside", alice))
rows.append(show("D. Bob's frame: qubit inside", bob))
print("  Each observer's annotation set is fully consistent (regions t and f).")
print("\n  The forbidden SUPEROBSERVER fuses both frames (max of each evidence):")
superobs = pal(0.95, 0.95)
rows.append(show("D. superobserver fusion", superobs,
    "Fusion -> ┬-adjacent, near-maximal dct. But no physical agent can perform "
    "this fusion: verifying both stories requires crossing the horizon AND "
    "collecting the radiation, which the geometry itself forbids (Hayden-Preskill "
    "bounds). PAL2v gives complementarity a precise logical form: annotations are "
    "OBSERVER-INDEXED; contradiction appears only in an index-collapsing fusion "
    "that spacetime renders operationally impossible. The paradox is real in the "
    "formalism but quarantined by physics."))

# =====================================================================
# FIGURES
# =====================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

# left: information paradox over evaporation time
ax = axes[0]
ax.plot(t, S_hawking / S_page.max(), label="Hawking thermal entropy (rising)", color="crimson")
ax.plot(t, S_page / S_page.max(), label="Page curve (unitary)", color="navy")
ax2 = ax.twinx()
ax2.plot(t, dct_t, color="darkorange", lw=2, label="dct (contradiction degree)")
ax2.set_ylabel("dct", color="darkorange"); ax2.set_ylim(-1, 1)
ax.axvline(t_page, color="gray", ls="--", lw=1)
ax.annotate("Page time", (t_page + 0.01, 1.55), fontsize=9)
ax.set_xlabel("t / t_evap"); ax.set_ylabel("entanglement entropy (normalized)")
ax.set_title("Information paradox: contradiction is LOCALIZED\nafter the Page time")
h1, l1 = ax.get_legend_handles_labels(); h2, l2 = ax2.get_legend_handles_labels()
ax.legend(h1 + h2, l1 + l2, loc="upper left", fontsize=9); ax.grid(alpha=0.3)

# right: GR validity sweep to the singularity
ax = axes[1]
ax.plot(x, mu_r, label="mu: empirical support for GR description", color="navy")
ax.plot(x, lam_r, label="lambda: refuting evidence (none exists!)", color="crimson")
ax.plot(x, dct_r, label="dct: slides toward PARACOMPLETE (-1)", color="darkorange", lw=2)
ax.axhline(0, color="gray", lw=0.5)
ax.set_xlabel("depth toward singularity (0 = horizon, 1 = Planck scale, log-radial)")
ax.set_ylabel("value")
ax.set_title("Singularity: GR goes SILENT (┴), it does not contradict itself (┬)")
ax.legend(fontsize=9, loc="center left"); ax.grid(alpha=0.3)
fig.tight_layout()
fig.savefig("results/blackhole_dynamics.png", dpi=130)
plt.close(fig)

# master lattice
fig, ax = plt.subplots(figsize=(8.6, 7.2))
ax.plot([0, 1, 0, -1, 0], [1, 0, -1, 0, 1], color="gray", lw=1)
ax.axhline(0, color="gray", lw=0.4); ax.axvline(0, color="gray", lw=0.4)
cmap = plt.get_cmap("tab10")
mk = ["*", "P", "o", "s", "D", "^", "v", "X", "p", "h", "8", "<"]
for i, s in enumerate(rows):
    ax.scatter(s["dc"], s["dct"], s=210, marker=mk[i % len(mk)], color=cmap(i % 10),
               edgecolors="k", zorder=5, label=f"{s['item']}  [{s['region']}]")
# trajectories
traj_info = [(pal(m, l).dc, pal(m, l).dct) for m, l in zip(mu_t[::20], lam_t[::20])]
ax.plot([p[0] for p in traj_info], [p[1] for p in traj_info], ":", color="crimson",
        lw=1.6, label="info paradox: evaporation trajectory")
traj_sing = [(pal(m, l).dc, pal(m, l).dct) for m, l in zip(mu_r[::12], lam_r[::12])]
ax.plot([p[0] for p in traj_sing], [p[1] for p in traj_sing], "--", color="navy",
        lw=1.6, label="GR validity: horizon -> singularity")
ax.annotate("┬ inconsistent\n(over-determined)", (0, 1.03), ha="center", fontsize=9)
ax.annotate("┴ paracomplete\n(theory silence)", (0, -1.16), ha="center", fontsize=9)
ax.annotate("t", (1.03, 0), fontsize=11); ax.annotate("f", (-1.09, 0), fontsize=11)
ax.set_xlim(-1.35, 1.35); ax.set_ylim(-1.3, 1.25)
ax.set_xlabel("dc (degree of certainty)"); ax.set_ylabel("dct (degree of contradiction)")
ax.set_title("Black hole physics on the PAL2v lattice")
ax.legend(loc="lower left", fontsize=7.2)
fig.tight_layout()
fig.savefig("results/blackhole_lattice.png", dpi=130)
plt.close(fig)

with open("results/blackhole_summary.csv", "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys()); w.writeheader(); w.writerows(rows)

print("\n" + "=" * 78)
print("SUMMARY: black hole puzzles on the lattice")
print("=" * 78)
print(f"{'item':<42} {'dc':>7} {'dct':>7}  {'region':<7} {'decision'}")
for s in rows:
    print(f"{s['item']:<42} {s['dc']:>+7.3f} {s['dct']:>+7.3f}  {s['region']:<7} {s['decision']}")
print("\nArtifacts written to results/.")
