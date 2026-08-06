"""
THE INSTRUMENT TURNED ON ITSELF
Hidden assumptions, hidden decision points, hidden collapses, self-undermining,
and the unstatable/unprovable in Paraconsistent Annotated Evidential Logic
Etau (PAL2v) -- demonstrated by execution wherever possible.

Seven demonstrations:
  A. THE ENCODING DEGREE OF FREEDOM: the mapping world -> (mu, lam) is not
     part of the logic. Same phenomenon (Simpson/Berkeley, real data), five
     defensible encodings, materially different verdicts. This audits MY OWN
     silent choice in the earlier paradox study.
  B. TRIVALENT COLLAPSE / SORITES REVENGE: decision_output and region labels
     are SHARP partitions of a continuous space. The vagueness expelled from
     the object language reappears at the region boundaries -- higher-order
     sorites on the lattice itself.
  C. THE REVENGE LIAR: 'this sentence's annotation lies strictly below the
     line mu+lam=1' -- a sentence about its own LATTICE POSITION. The ordinary
     Liar found a home at the center; the revenge Liar provably has none.
  D. CURRY'S PARADOX: 'if this sentence is true then 0=1'. Trivializes via
     modus ponens + contraction ALONE -- negation never appears, so blocking
     explosion (which is about negation) does not help. Also: PAL2v's
     propositional annotations cannot even EXPRESS a conditional's self-
     reference; the paradox is invisible to it, not solved by it.
  E. FUSION NON-ASSOCIATIVITY: the block-network combination of 3 sources
     depends on the parenthesization. Same evidence, different tree, different
     verdict -- and the formalism designates no canonical tree.
  F. IGNORANCE/BALANCE/WEIGHT COLLAPSE: (0.5,0.5) encodes 'one weak study
     pro, one weak study con' AND '10,000 studies exactly split'. Keynesian
     weight of evidence is unstatable in two dimensions, with decision-
     relevant consequences.
  G. THE CLASSICAL METALANGUAGE: the region classifier itself is a cascade of
     bivalent comparisons (source-inspected). Paraconsistency is administered
     by a perfectly classical bureaucracy; the logic does not, and cannot,
     apply to its own machinery.
"""
import inspect
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from paraconsistent.blocks import ParaconsistentBlock
from paraconsistent.core import labels as core_labels

FTC = 0.5

def pal(mu, lam, ftc=FTC):
    b = ParaconsistentBlock()
    b.config.FtC = ftc
    b.input.mu = float(np.clip(mu, 0, 1))
    b.input.lam = float(np.clip(lam, 0, 1))
    return b.complete

# =====================================================================
# A. THE ENCODING DEGREE OF FREEDOM
# =====================================================================
print("=" * 78)
print("A. THE ENCODING PROBLEM: the biggest hidden decision point")
print("=" * 78)
print("""The logic begins at (mu, lam). The mapping WORLD -> (mu, lam) is not part
of the formalism -- yet it determines everything downstream. Re-encode the
SAME Berkeley 1973 data (H = 'admissions biased against women') five
defensible ways. In the earlier paradox study I silently chose encoding E1.""")

berkeley = [("A",825,512,108,89),("B",560,353,25,17),("C",325,120,593,202),
            ("D",417,138,375,131),("E",191,53,393,94),("F",373,22,341,24)]
m_apps=sum(r[1] for r in berkeley); m_adm=sum(r[2] for r in berkeley)
f_apps=sum(r[3] for r in berkeley); f_adm=sum(r[4] for r in berkeley)
agg_gap = m_adm/m_apps - f_adm/f_apps                       # +0.142
gaps = [(fad/fa - mad/ma, fa+ma) for d,ma,mad,fa,fad in berkeley]
w_gap = sum(g*w for g,w in gaps)/sum(w for _,w in gaps)     # dept-level, ~+0.01 (favors women slightly)

encodings = {
 "E1 gap/2*max-rate (my earlier choice)":
     (0.5 + agg_gap/(2*(m_adm/m_apps)), 0.5 + w_gap/(2*0.20)),
 "E2 gap normalized by 0.5 (less aggressive)":
     (0.5 + agg_gap/1.0,               0.5 + w_gap/1.0),
 "E3 one-sided (only positive gaps count)":
     (max(0.0, agg_gap)/0.2,           max(0.0, w_gap)/0.2),
 "E4 dept-majority as counter-evidence":
     (0.5 + agg_gap/0.4,               4/6),
 "E5 significance-weighted (z-score squash)":
     (1/(1+np.exp(-agg_gap/0.03)),     1/(1+np.exp(-w_gap/0.03))),
}
print(f"\n{'encoding':<46} {'(mu,lam)':>14} {'dc':>7} {'dct':>7} {'region':<7} {'decision'}")
enc_results = []
for name, (mu, lam) in encodings.items():
    c = pal(mu, lam)
    dec = {1.0:"ACCEPT",0.0:"REJECT",0.5:"UNDEC"}[c.decision_output]
    enc_results.append((name, c))
    print(f"{name:<46} ({c.mu:.2f},{c.lam:.2f})   {c.dc:>+7.3f} {c.dct:>+7.3f} {c.label:<7} {dec}")
verdicts = {r[1].decision_output for r in enc_results}
regions = {r[1].label for r in enc_results}
print(f"\n-> {len(encodings)} defensible encodings, {len(regions)} distinct regions, "
      f"{len(verdicts)} distinct decisions, dc spread = "
      f"{max(r[1].dc for r in enc_results)-min(r[1].dc for r in enc_results):+.3f}.")
print("""-> The 'verdict of the paraconsistent analysis' was substantially MY verdict,
   smuggled in through the encoding. The logic's rigor begins only after the
   most consequential step is over. GIGO is not solved; it is DIGNIFIED.""")

# =====================================================================
# B. TRIVALENT COLLAPSE & SORITES REVENGE
# =====================================================================
print("\n" + "=" * 78)
print("B. THE SHARP EDGES OF A LOGIC OF VAGUENESS")
print("=" * 78)
print("""PAL2v 'dissolved' the sorites by replacing a sharp heap/not-heap line with
regions. But the REGIONS have sharp boundaries, and decision_output is a
STEP FUNCTION. Probe a hair's width around region borders:""")
eps = 1e-9
probes = [
    ("decision flip", (0.75 + FTC/2 - eps, 0.25 - FTC/2 + eps + 0), None),
]
# find muER threshold empirically: decision flips when muER crosses FtC
pairs = [((0.7499999, 0.25), (0.7500001, 0.25)),
         ((0.62, 0.3799999), (0.62, 0.3800001))]
for (a, b) in pairs:
    ca, cb = pal(*a), pal(*b)
    if ca.decision_output != cb.decision_output or ca.label != cb.label:
        print(f"  ({a[0]:.7f},{a[1]:.7f}) -> region={ca.label:<6} decision={ca.decision_output}")
        print(f"  ({b[0]:.7f},{b[1]:.7f}) -> region={cb.label:<6} decision={cb.decision_output}")
        print(f"    delta inputs = 2e-7 -> DISCONTINUOUS jump in output.\n")
# region boundary scan: count label changes along a fine line
mus = np.linspace(0, 1, 20001)
labels_line = [pal(m, 1 - m + 0.2 if 1 - m + 0.2 <= 1 else 1).label for m in mus]
changes = sum(1 for i in range(1, len(labels_line)) if labels_line[i] != labels_line[i-1])
print(f"  Scanning 20,001 points along a lattice chord: {changes} sharp label "
      f"transitions,\n  each an unmarked cliff where 'quasi-true' becomes 'inconsistent' "
      f"by 5e-5 of evidence.")
print("""-> HIGHER-ORDER SORITES: 'exactly which (mu,lam) is the last quasi-true
   point?' has a sharp, arbitrary answer -- the very thing the logic was
   praised for not having. The vagueness was not dissolved; it was RELOCATED
   into the metalanguage (region definitions, FtC, decision thresholds).
   Fuzzy borders of fuzzy borders: an infinite regress bought off with one
   hard-coded partition.""")

# =====================================================================
# C. THE REVENGE LIAR
# =====================================================================
print("\n" + "=" * 78)
print("C. REVENGE: the sentence PAL2v cannot place")
print("=" * 78)
print("""Ordinary Liar found a fixed point at the center I -- the lattice's escape
hatch. Now close the hatch with a sentence about its own LATTICE POSITION:
   R:  'R's own degree of certainty is negative'   (i.e. lam > mu: 'I sit on
       the FALSE side of the lattice.')
Faithfulness map: annotate R according to whether what R says holds of R's
current annotation:
   if lam > mu  (R's claim TRUE)  -> conclusive evidence FOR R  -> (1, 0)
                                     ...whose dc=+1 is NOT negative.
   if lam <= mu (R's claim FALSE) -> conclusive evidence AGAINST -> (0, 1)
                                     ...whose dc=-1 IS negative.
Iterate F(m,l) = (1,0) if l>m else (0,1) from anywhere, incl. the center:""")
pts = [(0.3, 0.3), (0.9, 0.9), (0.5, 0.5), (1.0, 0.0), (0.0, 1.0)]
for m0, l0 in pts:
    m, l, seen = m0, l0, []
    for _ in range(8):
        seen.append((m, l))
        m, l = (1.0, 0.0) if l > m else (0.0, 1.0)
    print(f"  start ({m0:.1f},{l0:.1f}): orbit -> {seen[:5]} ...")
print("""  Fixed point requires F(m,l)=(m,l): at (1,0) the claim '0>1' is false, so
  F=(0,1) != (1,0); at (0,1) the claim '1>0' is true, so F=(1,0) != (0,1).
  NO FIXED POINT EXISTS; every orbit enters the 2-cycle (1,0)<->(0,1) --
  verified above. Even the center (0.5,0.5), which absorbed the ordinary
  Liar, is expelled: '0.5>0.5' is false -> (0,1) -> (1,0) -> ... oscillation.
  And note: DAMPING no longer rescues it. Averaged updates converge to
  (0.5,0.5), but at (0.5,0.5) R's claim 'dc<0' is determinately FALSE while
  the annotation asserts perfect indeterminacy -- the fixed point is now
  UNFAITHFUL to the semantics it was meant to represent. The escape hatch
  is closed from the inside.
-> The lattice tamed the Liar only because the Liar spoke the OLD language.
   A sentence that speaks PAL2v's language ('my dct is negative') resurrects
   the paradox INSIDE the machinery meant to contain it. Every richer logic
   mints the currency of its own revenge. PAL2v cannot state -- let alone
   place -- its own semantic self-reference.""")

# =====================================================================
# D. CURRY'S PARADOX: the armor is negation-shaped; Curry has no negation
# =====================================================================
print("\n" + "=" * 78)
print("D. CURRY'S PARADOX: triviality without contradiction")
print("=" * 78)
print("""C: 'if C is true, then 0=1'.   Derivation uses ONLY modus ponens and
contraction -- NO negation, NO inconsistency anywhere:
   1. Suppose C.       [assumption]
   2. C -> (0=1).      [that IS C, line 1]
   3. 0=1.             [MP 1,2]
   4. C -> (0=1).      [discharge 1-3]
   5. C.               [4 is what C says]
   6. 0=1.             [MP 4,5]
Paraconsistency blocks EXPLOSION (a negation principle). Curry never uses
negation: the ┬-vertex is never visited; there is nothing to quarantine.
Demonstration that PAL2v's evidential state gives no purchase:""")
c_curry = pal(0.5, 0.5)   # what annotation should C even get? any choice is arbitrary
print(f"  annotate C at maximal noncommitment: region={c_curry.label}, dct={c_curry.dct:+.2f}")
print("""  -- but the derivation above is insensitive to C's annotation: it operates
  on the CONDITIONAL structure, which PAL2v's atomic (mu,lam) annotations do
  not represent at all. The library has no conditional connective; 'C -> D'
  cannot be written, so Curry cannot be STATED, hence neither solved nor
  blocked -- merely invisible.
-> Two failures in one: (i) expressive -- self-referential conditionals are
   outside the language; (ii) strategic -- even in richer paraconsistent
   logics, Curry forces surrender of contraction or MP, an amputation far
   deeper than tolerating contradictions, and one PAL2v never discusses
   because it cannot reach the question.""")

# =====================================================================
# E. FUSION NON-ASSOCIATIVITY
# =====================================================================
print("\n" + "=" * 78)
print("E. NETWORK ORDER-DEPENDENCE: no canonical way to combine evidence")
print("=" * 78)
print("""Three sources about one hypothesis: S1=(0.9,0.2), S2=(0.4,0.7), S3=(0.6,0.5).
Standard PANnet chaining (as in the library's own docs): downstream block
takes mu = upstream muER, lam = 1 - other-upstream muER. Compare the three
possible tree shapes:""")
S = [(0.9, 0.2), (0.4, 0.7), (0.6, 0.5)]
def fuse(a, b):
    ca, cb = pal(*a), pal(*b)
    return (ca.muER, 1 - cb.muER)
orders = {"(S1*S2)*S3": fuse(fuse(S[0], S[1]), S[2]),
          "S1*(S2*S3)": fuse(S[0], fuse(S[1], S[2])),
          "(S1*S3)*S2": fuse(fuse(S[0], S[2]), S[1])}
outs = {}
for name, ann in orders.items():
    c = pal(*ann)
    outs[name] = c
    dec = {1.0:"ACCEPT",0.0:"REJECT",0.5:"UNDEC"}[c.decision_output]
    print(f"  {name}: final (mu,lam)=({ann[0]:.3f},{ann[1]:.3f}) "
          f"dc={c.dc:+.3f} region={c.label:<6} {dec}")
spread = max(o.dc for o in outs.values()) - min(o.dc for o in outs.values())
print(f"\n-> Same three sources, dc spread across orderings = {spread:+.3f}"
      f" ({len({o.decision_output for o in outs.values()})} distinct decisions,"
      f" {len({o.label for o in outs.values()})} distinct regions).")
print("""-> Fusion is NON-ASSOCIATIVE and NON-COMMUTATIVE, and the formalism
   specifies no canonical tree. The analyst's wiring diagram is another
   hidden free parameter -- like Simpson's paradox, the conclusion depends
   on how you aggregate, and the logic that DIAGNOSED that problem for
   statistics exhibits it, undiagnosed, in its own plumbing.""")

# =====================================================================
# F. WEIGHT-OF-EVIDENCE COLLAPSE
# =====================================================================
print("\n" + "=" * 78)
print("F. WHAT (0.5, 0.5) CANNOT SAY: the missing third dimension")
print("=" * 78)
n_pairs = [(1, 1), (10, 10), (5000, 5000)]
print("  scenario                              annotation   dc     dct   region")
for n_pro, n_con in n_pairs:
    # any reasonable evidence-average of n_pro supporting & n_con refuting studies
    mu = n_pro / (n_pro + n_con); lam = n_con / (n_pro + n_con)
    c = pal(mu, lam)
    print(f"  {n_pro:>5} studies pro, {n_con:>5} studies con   "
          f"({mu:.2f},{lam:.2f})  {c.dc:+.2f}  {c.dct:+.2f}  {c.label}")
print("""-> IDENTICAL lattice point for 2 anecdotes and 10,000 trials. Keynes's
   'weight of argument' (1921) -- how MUCH evidence, as opposed to its
   BALANCE -- is unstatable in two dimensions. Consequences are decision-
   relevant: the value of gathering more information, the stability of the
   verdict under one new study, the width of any confidence band -- all
   invisible. PAL2v collapses (balance, weight) -> balance exactly the way
   scalar probability collapses (mu, lam) -> one number: the same crime it
   was recruited to expose, one floor up.
   [The library's radial metrics d, D do not help: they too are functions of
   the single point (mu,lam), blind to sample size behind it.]""")

# =====================================================================
# G. THE CLASSICAL METALANGUAGE
# =====================================================================
print("\n" + "=" * 78)
print("G. THE CONSISTENT BUREAUCRACY: source inspection of the classifier")
print("=" * 78)
src = inspect.getsource(core_labels.classify_12_regions_asymmetric)
n_if = src.count("if ")
n_cmp = sum(src.count(op) for op in (">=", "<=", " > ", " < "))
print(f"  classify_12_regions_asymmetric: {n_if} if-statements, ~{n_cmp} crisp comparisons.")
print("""  Every one is a BIVALENT decision: mu+lam-1 >= fd_pos is true or false,
  never quasi-true, never inconsistent. Excerpt:
      if dc >= th.ftc_pos:  return 't'
      if dct >= th.fd_pos:  return '┬'
-> The paraconsistent verdicts are produced by a classical machine. The logic
   does not apply to its own application. This is not an implementation
   accident but a THEOREM-SHAPED necessity: a classifier whose own outputs
   were paraconsistently annotated would need a meta-classifier, and so on --
   the regress is stopped only by a floor of bivalence. Paraconsistency is
   therefore not an alternative FOUNDATION; it is a managed dialect,
   spoken with permission, inside a classical host. (Da Costa knew this:
   C-systems have a classical metatheory. The marketing seldom mentions it.)""")

# =====================================================================
# FIGURE
# =====================================================================
fig, axes = plt.subplots(1, 2, figsize=(14, 6.2))
ax = axes[0]
ax.plot([0,1,0,-1,0],[1,0,-1,0,1], color="gray", lw=1)
cols = plt.get_cmap("tab10")
for i, (name, c) in enumerate(enc_results):
    ax.scatter(c.dc, c.dct, s=200, marker="*", color=cols(i), edgecolors="k",
               zorder=5, label=f"{name.split('(')[0].strip()} [{c.label}]")
ax.set_title("A. One phenomenon (Berkeley data), five defensible encodings:\nthe verdict is chosen before the logic begins")
ax.set_xlabel("dc"); ax.set_ylabel("dct")
ax.set_xlim(-1.2, 1.2); ax.set_ylim(-1.15, 1.15)
ax.legend(fontsize=7.5, loc="lower left"); ax.grid(alpha=0.25)

ax = axes[1]
n = 601
mus_g = np.linspace(0, 1, n); lams_g = np.linspace(0, 1, n)
lab_idx, Z = {}, np.zeros((n, n))
for i, l in enumerate(lams_g):
    for j, m in enumerate(mus_g):
        lb = pal(m, l).label
        Z[i, j] = lab_idx.setdefault(lb, len(lab_idx))
# mark boundary pixels
B = np.zeros_like(Z)
B[1:, :] += (np.diff(Z, axis=0) != 0)
B[:, 1:] += (np.diff(Z, axis=1) != 0)
ax.imshow((B > 0), origin="lower", extent=[0, 1, 0, 1], cmap="Greys", aspect="auto")
ax.set_title("B. The sharp skeleton of a logic of vagueness:\nevery black line is a bivalent cliff (higher-order sorites)")
ax.set_xlabel("mu"); ax.set_ylabel("lambda")
fig.tight_layout()
fig.savefig("results/critique_figure.png", dpi=130)
plt.close(fig)

print("\nArtifacts written to results/.")
