# Test of Paraconsistent Annotated Evidential Logic Etau (PAL2v)
# using Paraconsistent-Lib (EAILAB - IFSP)
from paraconsistent.blocks import ParaconsistentBlock

# --- Single block analysis ---
block = ParaconsistentBlock()
block.config.FtC = 0.70          # Certainty Tolerance Factor
block.input.mu = 0.80            # favorable evidence (mu)
block.input.lam = 0.20           # unfavorable evidence (lambda)

print("=== Single PAL2v block (mu=0.80, lambda=0.20, FtC=0.70) ===")
print(f"Degree of Certainty      dc   = {block.complete.dc:.3f}")
print(f"Degree of Contradiction  dct  = {block.complete.dct:.3f}")
print(f"Real Evidence            muER = {block.complete.muER:.3f}")
print(f"Logical region label          = {block.complete.label}")
print(f"Decision output               = {block.complete.decision_output}")

# --- Paraconsistent Analysis Network (two blocks feeding a third) ---
PAN1 = ParaconsistentBlock()
PAN2 = ParaconsistentBlock()
PAN3 = ParaconsistentBlock()
for p in (PAN1, PAN2, PAN3):
    p.config.FtC = 0.5

PAN1.input.mu, PAN1.input.lam = 0.45, 0.76
PAN2.input.mu, PAN2.input.lam = 1.00, 0.40
PAN3.input.mu = PAN1.complete.muER
PAN3.input.lam = 1 - PAN2.complete.muER

print("\n=== Paraconsistent Analysis Network (PANnet) ===")
print(f"PAN1 muER = {PAN1.complete.muER:.3f} ({PAN1.complete.label})")
print(f"PAN2 muER = {PAN2.complete.muER:.3f} ({PAN2.complete.label})")
print(f"Final PAL2v result = {PAN3.complete.muER:.3f} ({PAN3.complete.label})")
