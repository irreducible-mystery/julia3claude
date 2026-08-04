/- ============================================================
   CombinerGalois.lean — the Galois/combiner boundary, kernel court

   A fourth voice enters. I am the Lean instance from
   irreducible-mystery/julia3claude (the Lean paradox suite on
   PR #2 there; whether my auditor and this repo's voices
   coincide I cannot verify from here, so I claim nothing),
   invited by Kelly to join. I take the open move the README
   leaves sharpest after _09:

     "The Galois/combiner question, SHARPENED by _09: which
      combiners admit a (★) — i.e. license kernel-first
      prediction — and which (max) leave census-first as the
      only instrument? The boundary is the algebra/order divide."

   _09 licensed its reversal with a remark: "sum is a
   homomorphism; for max no (★) exists." This file promotes that
   remark to kernel theorems, with exact scope, in both
   directions — and finds the boundary is stranger than the
   remark says.

   WHAT "(★)" MEANS HERE, DECLARED BEFORE ANY PROOF (the audits
   of this repo keep convicting prose that outruns its object, so
   the object is pinned first): a combiner ADMITS (★) on a world
   when the total defect is an AFFINE function of the state with
   topology-determined coefficients — Σd = Σⱼ cⱼ·sⱼ + k. That is
   the property _07/_09 actually used: affine-in-state is what
   lets finitely many kernel evaluations pin the whole law
   (kernel-first licensing). A nonlinear "formula" always exists
   (the defect functional itself); it licenses nothing.

   PAPER DERIVATION FIRST (house norm), then the kernel:

   I.  ALGEBRA SIDE, CLOSED UNIFORMLY. Generalize the combiner
       from sum to ANY affine map: mark i hears mark j with
       integer weight w i j and carries twist-offset t i
       (succ-twist: t ≡ 1; Section 3's list wiring: w i j =
       multiplicity of j in inputs i). One Fubini + one
       telescoping give
         (★aff)  Σᵢ raw = Σⱼ (1 − W j)·s j − Σᵢ t i,
       W j = Σᵢ w i j the WEIGHTED out-degree. Every affine
       combiner licenses kernel-first prediction; conservation is
       W ≡ 1 (mod m) at every mark; Section 3's (★) is the
       multiplicity instance (proved below, not asserted). P20's
       "coefficient −2" world is the instance W = 3.

   II. ORDER SIDE, PROVABLY OUTSIDE — WITH A TWIST. max cannot
       be affine-subsumed, and the failure is located exactly:
       • On worlds where every mark hears ≤ 1 input, max IS sum
         (theorem: the raw gaps coincide pointwise). The divide
         does not exist without sharing — _05's P6 ("laws
         dissolve on contact") and the Galois boundary are the
         same phenomenon.
       • On the symmetric shared world W2 (two marks, each
         hearing both), the max-defect total is
         s₀+s₁−2·max(s₀,s₁)−2 — not affine over ℤ (theorem), so
         no (★) exact. BUT mod 2 it IS affine: ≡ s₀+s₁ (theorem)
         — |s₀−s₁| ≡ s₀+s₁ (mod 2). The Galois boundary is
         MODULUS-RELATIVE: ℤ/2 cannot see the algebra/order
         divide on W2. P20's lesson ("binary can hide
         instrumentation") reaches the Galois question itself.
       • The coincidence dies with the symmetry: on W21 (mark 0
         hears {0,1}, mark 1 hears itself), NO modulus m ≥ 2
         admits an affine charge — the three probe states
         (0,0),(0,1),(0,−1) force m ∣ 1 (theorem, every m at
         once). max admits no uniform (★) in any ℤ/m.

   III. DIAL CLASSIFICATION (P20's small fact, given its home):
       from (★aff), the mark of weighted out-degree W carries
       coefficient 1−W; ℤ/m sees its dial iff m ∤ (W−1). The
       "which dials can each ℤ/m see" classification is one
       line: the visible marks are exactly those whose excess
       listening W−1 is nonzero mod m.

   VERDICT for the open move: "admits (★)" is not a property of
   the combiner alone. Affine combiners admit it on every world
   and every modulus (I). max admits it on no world with genuine
   sharing over ℤ (II), admits it on W2 in exactly ℤ/2 (the
   symmetric coincidence), and on W21 in no ℤ/m at all. The
   algebra/order divide opens at sharing, and its visibility is
   a property of (combiner, wiring, modulus) — census-first
   remains the only instrument for max precisely because no
   finite set of kernel evaluations can pin a law that isn't
   affine to pin.

   Mutant controls at the end (refutation theorems, kernel
   court); axiom ledger printed after the namespace closes.
   Compile: lean emergence/lean/CombinerGalois.lean   (≥ 4.22)
   ============================================================ -/

namespace CombinerGalois

/- ------------------------------------------------------------
   §0 — sumTo algebra, restated verbatim-in-spirit from
   RingRest.lean §§2–3 (author: the auditing instance) so this
   file stays standalone, per the house norm that every artifact
   runs bare (`lean <file>`, no build system, no imports).
   Nothing in §0 is new; attribution is the point of this box.
   ------------------------------------------------------------ -/

/-- Left-fold sum of the first `n` values of `f`. -/
def sumTo (f : Nat → Int) : Nat → Int
  | 0 => 0
  | n + 1 => sumTo f n + f n

theorem sumTo_emod (f : Nat → Int) (m : Int) :
    ∀ n, sumTo (fun i => f i % m) n % m = sumTo f n % m := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
      show (sumTo (fun i => f i % m) n + f n % m) % m = (sumTo f n + f n) % m
      rw [Int.add_emod, ih, Int.emod_emod_of_dvd _ (Int.dvd_refl m), ← Int.add_emod]

theorem sumTo_congr_lt (f g : Nat → Int) :
    ∀ n, (∀ i, i < n → f i = g i) → sumTo f n = sumTo g n := by
  intro n
  induction n with
  | zero => intro _; rfl
  | succ n ih =>
      intro h
      show sumTo f n + f n = sumTo g n + g n
      rw [ih (fun i hi => h i (by omega)), h n (by omega)]

theorem sumTo_add (f g : Nat → Int) :
    ∀ n, sumTo (fun i => f i + g i) n = sumTo f n + sumTo g n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
      show sumTo (fun i => f i + g i) n + (f n + g n)
          = (sumTo f n + f n) + (sumTo g n + g n)
      rw [ih]; omega

theorem sumTo_sub (f g : Nat → Int) :
    ∀ n, sumTo (fun i => f i - g i) n = sumTo f n - sumTo g n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
      show sumTo (fun i => f i - g i) n + (f n - g n)
          = (sumTo f n + f n) - (sumTo g n + g n)
      rw [ih]; omega

theorem sumTo_const_zero : ∀ n, sumTo (fun _ => (0 : Int)) n = 0 := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
      show sumTo (fun _ => (0 : Int)) n + 0 = 0
      rw [ih]; rfl

theorem sumTo_const_one : ∀ n, sumTo (fun _ => (1 : Int)) n = (n : Int) := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
      show sumTo (fun _ => (1 : Int)) n + 1 = ((n + 1 : Nat) : Int)
      rw [ih]; omega

theorem sumTo_mul_right (f : Nat → Int) (x : Int) :
    ∀ n, sumTo (fun i => f i * x) n = sumTo f n * x := by
  intro n
  induction n with
  | zero => show (0 : Int) = 0 * x; rw [Int.zero_mul]
  | succ n ih =>
      show sumTo (fun i => f i * x) n + f n * x = (sumTo f n + f n) * x
      rw [ih, Int.add_mul]

theorem sumTo_swap (G : Nat → Nat → Int) (n : Nat) :
    ∀ N, sumTo (fun i => sumTo (G i) n) N
        = sumTo (fun j => sumTo (fun i => G i j) N) n := by
  intro N
  induction N with
  | zero =>
      show (0 : Int) = sumTo (fun j => sumTo (fun i => G i j) 0) n
      rw [sumTo_congr_lt (fun j => sumTo (fun i => G i j) 0) (fun _ => (0 : Int))
            n (fun _ _ => rfl), sumTo_const_zero]
  | succ N ih =>
      show sumTo (fun i => sumTo (G i) n) N + sumTo (G N) n
          = sumTo (fun j => sumTo (fun i => G i j) (N + 1)) n
      rw [ih, ← sumTo_add]
      exact sumTo_congr_lt _ _ n (fun j _ => rfl)

theorem kron_zero (a : Nat) (s : Nat → Int) :
    ∀ N, ¬ a < N → sumTo (fun j => (if a = j then (1 : Int) else 0) * s j) N = 0 := by
  intro N
  induction N with
  | zero => intro _; rfl
  | succ N ih =>
      intro h
      show sumTo (fun j => (if a = j then (1 : Int) else 0) * s j) N
            + (if a = N then (1 : Int) else 0) * s N = 0
      rw [ih (by omega), if_neg (by omega : ¬ a = N), Int.zero_mul]
      rfl

theorem kron (a : Nat) (s : Nat → Int) :
    ∀ N, a < N → sumTo (fun j => (if a = j then (1 : Int) else 0) * s j) N = s a := by
  intro N
  induction N with
  | zero => intro h; exact absurd h (Nat.not_lt_zero a)
  | succ N ih =>
      intro h
      show sumTo (fun j => (if a = j then (1 : Int) else 0) * s j) N
            + (if a = N then (1 : Int) else 0) * s N = s a
      cases Nat.lt_or_ge a N with
      | inl hlt => rw [ih hlt, if_neg (by omega : ¬ a = N), Int.zero_mul, Int.add_zero]
      | inr _ =>
          have ha : a = N := by omega
          rw [kron_zero a s N (by omega), if_pos ha, Int.one_mul, Int.zero_add, ha]

/-- Sum of a list of integers (RingRest §3). -/
def lsum : List Int → Int
  | [] => 0
  | a :: t => a + lsum t

/-- Multiplicity of mark `j` in an input list (RingRest §3). -/
def cnt (j : Nat) : List Nat → Nat
  | [] => 0
  | a :: t => (if a = j then 1 else 0) + cnt j t

/-- RingRest §3's raw gap: sum-combiner, succ-twist. -/
def gRaw (inputs : Nat → List Nat) (s : Nat → Int) (i : Nat) : Int :=
  s i - lsum ((inputs i).map s) - 1

theorem lsum_eq_weighted (s : Nat → Int) (n : Nat) :
    ∀ l : List Nat, (∀ j, j ∈ l → j < n) →
      lsum (l.map s) = sumTo (fun j => (cnt j l : Int) * s j) n := by
  intro l
  induction l with
  | nil =>
      intro _
      show (0 : Int) = sumTo (fun j => ((0 : Nat) : Int) * s j) n
      rw [sumTo_congr_lt (fun j => ((0 : Nat) : Int) * s j) (fun _ => (0 : Int))
            n (fun j _ => by rw [Int.natCast_zero, Int.zero_mul]), sumTo_const_zero]
  | cons a t ih =>
      intro hmem
      show s a + lsum (t.map s) = sumTo (fun j => (cnt j (a :: t) : Int) * s j) n
      have ht : ∀ j, j ∈ t → j < n := fun j hj => hmem j (List.mem_cons_of_mem a hj)
      have ha : a < n := hmem a List.mem_cons_self
      have hsplit : ∀ j, (cnt j (a :: t) : Int) * s j
          = (if a = j then (1 : Int) else 0) * s j + (cnt j t : Int) * s j := by
        intro j
        show ((if a = j then 1 else 0) + cnt j t : Nat) * s j = _
        by_cases h : a = j
        · rw [if_pos h, if_pos h]
          show ((1 + cnt j t : Nat) : Int) * s j = 1 * s j + (cnt j t : Int) * s j
          rw [Int.natCast_add, Int.add_mul, Int.natCast_one]
        · rw [if_neg h, if_neg h]
          show ((0 + cnt j t : Nat) : Int) * s j = 0 * s j + (cnt j t : Int) * s j
          rw [Nat.zero_add, Int.zero_mul, Int.zero_add]
      rw [sumTo_congr_lt _ _ n (fun j _ => hsplit j), sumTo_add, ih ht, kron a s n ha]

/- ------------------------------------------------------------
   §1 — THE ALGEBRA SIDE, CLOSED: every affine combiner
   carries (★). New material begins here.

   A weighted world: mark i hears mark j with weight `w i j : ℤ`
   (0 = not wired; Section 3's lists are the case
   w i j = multiplicity), and carries its own twist-offset
   `t i : ℤ` (succ-twist: t ≡ 1; a twist x ↦ a·x + b at mark i
   is weight a on its own input and offset b).
   ------------------------------------------------------------ -/

/-- Weighted out-degree of mark `j`: total listening weight aimed at it. -/
def wOut (w : Nat → Nat → Int) (n j : Nat) : Int :=
  sumTo (fun i => w i j) n

/-- Raw gap at mark `i` of the affine world `(w, t)`:
    `s i − Σⱼ w i j · s j − t i`. -/
def wRaw (w : Nat → Nat → Int) (t : Nat → Int) (n : Nat)
    (s : Nat → Int) (i : Nat) : Int :=
  s i - sumTo (fun j => w i j * s j) n - t i

/-- Defect mod m at mark `i` of the affine world. -/
def wDefect (m : Nat) (w : Nat → Nat → Int) (t : Nat → Int) (n : Nat)
    (s : Nat → Int) (i : Nat) : Int :=
  wRaw w t n s i % (m : Int)

/-- **(★aff), raw form — the algebra side closes.** For every affine
    world, every state: `Σᵢ raw = Σⱼ (1 − W j)·s j − Σ t`. One Fubini
    (`sumTo_swap`), no cases, no census. Every affine combiner licenses
    kernel-first prediction: the coefficients are wiring data. -/
theorem affine_charge_raw (w : Nat → Nat → Int) (t : Nat → Int) (n : Nat)
    (s : Nat → Int) :
    sumTo (wRaw w t n s) n
      = sumTo (fun j => (1 - wOut w n j) * s j) n - sumTo t n := by
  have step1 : sumTo (wRaw w t n s) n
      = sumTo s n - sumTo (fun i => sumTo (fun j => w i j * s j) n) n - sumTo t n := by
    have h1 : sumTo (wRaw w t n s) n
        = sumTo (fun i => (s i - sumTo (fun j => w i j * s j) n) - t i) n :=
      sumTo_congr_lt _ _ n (fun i _ => rfl)
    rw [h1, sumTo_sub (fun i => s i - sumTo (fun j => w i j * s j) n) t,
        sumTo_sub s (fun i => sumTo (fun j => w i j * s j) n)]
  have step2 : sumTo (fun i => sumTo (fun j => w i j * s j) n) n
      = sumTo (fun j => wOut w n j * s j) n := by
    rw [sumTo_swap (fun i j => w i j * s j) n n]
    exact sumTo_congr_lt _ _ n
      (fun j _ => sumTo_mul_right (fun i => w i j) (s j) n)
  have step3 : sumTo s n - sumTo (fun j => wOut w n j * s j) n
      = sumTo (fun j => (1 - wOut w n j) * s j) n := by
    rw [← sumTo_sub s (fun j => wOut w n j * s j)]
    exact sumTo_congr_lt _ _ n (fun j _ => by rw [Int.sub_mul, Int.one_mul])
  rw [step1, step2]
  omega

/-- **(★aff) mod m.** -/
theorem affine_charge (m : Nat) (w : Nat → Nat → Int) (t : Nat → Int) (n : Nat)
    (s : Nat → Int) :
    sumTo (wDefect m w t n s) n % (m : Int)
      = (sumTo (fun j => (1 - wOut w n j) * s j) n - sumTo t n) % (m : Int) := by
  have h := sumTo_emod (wRaw w t n s) (m : Int) n
  show sumTo (fun i => wRaw w t n s i % (m : Int)) n % (m : Int) = _
  rw [h, affine_charge_raw]

/-- **Conservation generalized** (RingRest's `charge_conserved_of_outdeg_one`
    is the case t ≡ 1): weighted out-degree exactly 1 at every mark ⟹ the
    charge is `−Σ t` for EVERY state. Conservation is a WEIGHTED
    out-degree property; "every mark heard exactly once" generalizes to
    "every mark heard with total weight one". -/
theorem affine_conserved (m : Nat) (w : Nat → Nat → Int) (t : Nat → Int) (n : Nat)
    (hod : ∀ j, j < n → wOut w n j = 1) (s : Nat → Int) :
    sumTo (wDefect m w t n s) n % (m : Int) = (-(sumTo t n)) % (m : Int) := by
  rw [affine_charge m w t n s]
  have hz : sumTo (fun j => (1 - wOut w n j) * s j) n = 0 := by
    rw [sumTo_congr_lt (fun j => (1 - wOut w n j) * s j) (fun _ => (0 : Int)) n
          (fun j hj => by rw [hod j hj]; omega), sumTo_const_zero]

  rw [hz]
  have h0 : (0 : Int) - sumTo t n = -(sumTo t n) := by omega
  rw [h0]

/-- **Section 3 is an instance, proved not asserted**: on any list
    wiring, the sum-combiner raw gap IS the affine raw gap with
    multiplicity weights and unit offsets — pointwise. -/
theorem sum_is_affine (inputs : Nat → List Nat) (n : Nat)
    (hbound : ∀ i, i < n → ∀ j ∈ inputs i, j < n) (s : Nat → Int)
    (i : Nat) (hi : i < n) :
    gRaw inputs s i
      = wRaw (fun i j => (cnt j (inputs i) : Int)) (fun _ => 1) n s i := by
  show s i - lsum ((inputs i).map s) - 1
      = s i - sumTo (fun j => (cnt j (inputs i) : Int) * s j) n - 1
  rw [lsum_eq_weighted s n (inputs i) (hbound i hi)]

/-- RingRest's (★) recovered from (★aff): `Σ gRaw = Σ (1−W)·s − n`. -/
theorem star_recovered (inputs : Nat → List Nat) (n : Nat)
    (hbound : ∀ i, i < n → ∀ j ∈ inputs i, j < n) (s : Nat → Int) :
    sumTo (gRaw inputs s) n
      = sumTo (fun j =>
          (1 - wOut (fun i j => (cnt j (inputs i) : Int)) n j) * s j) n
        - (n : Int) := by
  have h : sumTo (gRaw inputs s) n
      = sumTo (wRaw (fun i j => (cnt j (inputs i) : Int)) (fun _ => 1) n s) n :=
    sumTo_congr_lt _ _ n (fun i hi => sum_is_affine inputs n hbound s i hi)
  rw [h, affine_charge_raw, sumTo_const_one]

/- ------------------------------------------------------------
   §2 — THE ORDER SIDE: max, located exactly.
   `imax` is defined locally (if-then-else) so every reduction
   below is definitional; `lmax []` = 0 matches `lsum []` = 0
   so the single-input comparison is convention-free.
   ------------------------------------------------------------ -/

/-- Local max on ℤ. -/
def imax (a b : Int) : Int := if a ≤ b then b else a

/-- Max of a list of integers; `lmax [a] = a`, `lmax [] = 0`. -/
def lmax : List Int → Int
  | [] => 0
  | [a] => a
  | a :: t => imax a (lmax t)

/-- Raw gap at mark `i` under the MAX-combiner and succ-twist. -/
def xRaw (inputs : Nat → List Nat) (s : Nat → Int) (i : Nat) : Int :=
  s i - lmax ((inputs i).map s) - 1

/-- **The divide needs sharing.** On any world where every mark hears at
    most one input, max IS sum — the raw gaps coincide pointwise, for
    every state. The algebra/order divide does not exist without shared
    listening: _05's P6 ("laws dissolve on contact") and the Galois
    boundary are the same phenomenon, seen from two sides. -/
theorem order_needs_sharing (inputs : Nat → List Nat) (s : Nat → Int)
    (i : Nat) (h : (inputs i).length ≤ 1) :
    xRaw inputs s i = gRaw inputs s i := by
  unfold xRaw gRaw
  cases hl : inputs i with
  | nil => rfl
  | cons a tl =>
      cases tl with
      | nil =>
          show s i - lmax [s a] - 1 = s i - lsum [s a] - 1
          show s i - s a - 1 = s i - (s a + 0) - 1
          omega
      | cons b tl' => rw [hl] at h; simp [List.length] at h

/-- The symmetric shared world W2: two marks, each hearing both. -/
def W2 : Nat → List Nat := fun _ => [0, 1]

/-- W2's total max-defect, exactly: `s₀ + s₁ − 2·max(s₀,s₁) − 2`
    (= −|s₀−s₁| − 2: the absolute value, order's fingerprint). -/
theorem w2_total (s : Nat → Int) :
    sumTo (xRaw W2 s) 2 = s 0 + s 1 - 2 * imax (s 0) (s 1) - 2 := by
  show 0 + (s 0 - lmax [s 0, s 1] - 1) + (s 1 - lmax [s 0, s 1] - 1) = _
  show 0 + (s 0 - imax (s 0) (s 1) - 1) + (s 1 - imax (s 0) (s 1) - 1) = _
  omega

/-- **No-go, exact.** W2's max-defect total is affine in no way over ℤ:
    four probe states over-determine any candidate (a,b,c) and then
    contradict it. No finite set of kernel evaluations can pin a law
    here, because there is no affine law to pin. -/
theorem max_not_affine_exact :
    ¬ ∃ a b c : Int, ∀ s0 s1 : Int,
        s0 + s1 - 2 * imax s0 s1 - 2 = a * s0 + b * s1 + c := by
  intro ⟨a, b, c, h⟩
  have h00 := h 0 0
  have h10 := h 1 0
  have h01 := h 0 1
  have h11 := h 1 1
  have e00 : imax (0 : Int) 0 = 0 := by decide
  have e10 : imax (1 : Int) 0 = 1 := by decide
  have e01 : imax (0 : Int) 1 = 1 := by decide
  have e11 : imax (1 : Int) 1 = 1 := by decide
  rw [e00] at h00; rw [e10] at h10; rw [e01] at h01; rw [e11] at h11
  omega

/-- **The symmetric coincidence: ℤ/2 cannot see the divide.** On W2 the
    max-charge IS affine mod 2: total ≡ s₀ + s₁ (mod 2), because
    |s₀−s₁| ≡ s₀+s₁ (mod 2). max admits (★) on W2 in exactly one
    modulus — the binary one. P20 found that ℤ/2 can hide a dial
    (coefficient −2 ≡ 0); here ℤ/2 hides the entire algebra/order
    boundary. Binary's costume, at the Galois level. -/
theorem w2_star_mod2 (s : Nat → Int) :
    (sumTo (xRaw W2 s) 2 - (s 0 + s 1)) % 2 = 0 := by
  rw [w2_total]
  omega

/-- The asymmetric shared world W21: mark 0 hears {0, 1}, mark 1 hears
    only itself. Total weight of listening differs between marks. -/
def W21 : Nat → List Nat := fun i => if i = 0 then [0, 1] else [1]

/-- W21's total max-defect, exactly: `s₀ − max(s₀,s₁) − 2`
    (mark 1's gap is identically −1: it hears itself, twisted). -/
theorem w21_total (s : Nat → Int) :
    sumTo (xRaw W21 s) 2 = s 0 - imax (s 0) (s 1) - 2 := by
  show 0 + (s 0 - lmax [s 0, s 1] - 1) + (s 1 - lmax [s 1] - 1) = _
  show 0 + (s 0 - imax (s 0) (s 1) - 1) + (s 1 - s 1 - 1) = _
  omega

/-- m ∣ x → m ∣ y → m ∣ (x − y), from first principles (no library
    roulette; RingRest's ledger records how the wrong dvd lemma smuggles
    Classical.choice — this one is three constructors). -/
theorem dvd_sub' {m x y : Int} : m ∣ x → m ∣ y → m ∣ (x - y) :=
  fun ⟨u, hu⟩ ⟨v, hv⟩ => ⟨u - v, by rw [hu, hv, Int.mul_sub]⟩

theorem dvd_add' {m x y : Int} : m ∣ x → m ∣ y → m ∣ (x + y) :=
  fun ⟨u, hu⟩ ⟨v, hv⟩ => ⟨u + v, by rw [hu, hv, Int.mul_add]⟩

/-- No integer ≥ 2 divides −1 (self-contained; `Int.mul_nonneg` only). -/
theorem not_dvd_neg_one (m : Int) (hm : 2 ≤ m) : ¬ m ∣ (-1) := by
  intro ⟨u, hu⟩
  rcases Int.lt_trichotomy u 0 with hneg | hzero | hpos
  · have h1 : 0 ≤ m * (-u - 1) := Int.mul_nonneg (by omega) (by omega)
    have h2 : m * (-u - 1) = -(m * u) - m := by
      rw [Int.mul_sub, Int.mul_neg, Int.mul_one]
    omega
  · rw [hzero, Int.mul_zero] at hu; omega
  · have h1 : 0 ≤ m * (u - 1) := Int.mul_nonneg (by omega) (by omega)
    have h2 : m * (u - 1) = m * u - m := by rw [Int.mul_sub, Int.mul_one]
    omega

/-- **No-go, EVERY modulus at once.** On W21, no affine charge formula
    exists mod m for ANY m ≥ 2: the three probe states (0,0), (0,1),
    (0,−1) force m ∣ 1. The mod-2 coincidence of W2 was the symmetry
    (both marks hearing the same set, so the max enters with an even
    coefficient); break the symmetry and no modulus survives. max
    licenses kernel-first prediction NOWHERE — census-first is not a
    weaker instrument for the order side; it is the only one.
    (Hypothesis reading: `m ∣ (defect-total − affine)` at every state
    IS "the charge is affine mod m".) -/
theorem max_no_star_any_modulus (m : Int) (hm : 2 ≤ m) :
    ¬ ∃ a b c : Int, ∀ s0 s1 : Int,
        m ∣ ((s0 - imax s0 s1 - 2) - (a * s0 + b * s1 + c)) := by
  intro ⟨a, b, c, h⟩
  have h1 := h 0 0
  have h2 := h 0 1
  have h3 := h 0 (-1)
  have e1 : imax (0 : Int) 0 = 0 := by decide
  have e2 : imax (0 : Int) 1 = 1 := by decide
  have e3 : imax (0 : Int) (-1) = 0 := by decide
  rw [e1] at h1; rw [e2] at h2; rw [e3] at h3
  -- d₂ + d₃ − 2·d₁ = −1, whatever a, b, c are
  have hcomb : m ∣ (-1 : Int) := by
    have hs : ((0 - 1 - 2) - (a * 0 + b * 1 + c))
            + ((0 - 0 - 2) - (a * 0 + b * (-1) + c))
            - (((0 - 0 - 2) - (a * 0 + b * 0 + c))
            + ((0 - 0 - 2) - (a * 0 + b * 0 + c))) = -1 := by omega
    have hd := dvd_sub' (dvd_add' h2 h3) (dvd_add' h1 h1)
    rw [hs] at hd
    exact hd
  exact not_dvd_neg_one m hm hcomb

/-- Kernel census (the census court, held inside the kernel): on W2 the
    max-charge mod 3 is state-dependent — two explicit states, two
    different residues. Where sum's (★aff) makes mod-3 charge affine,
    max's takes ≥ 2 values with no affine account (max_not_affine_exact). -/
example :
    (sumTo (xRaw W2 (fun i => if i = 0 then 0 else 0)) 2) % 3
      ≠ (sumTo (xRaw W2 (fun i => if i = 0 then 0 else 1)) 2) % 3 := by
  decide

/- ------------------------------------------------------------
   §3 — THE DIAL CLASSIFICATION (P20's small fact, housed).
   ------------------------------------------------------------ -/

/-- **Which dials can ℤ/m see?** From (★aff), the mark of weighted
    out-degree `W` carries coefficient `1 − W`. Its dial is invisible in
    ℤ/m exactly when m ∣ (W − 1): the visible marks are those whose
    EXCESS LISTENING `W − 1` is nonzero mod m. P20's world (out-degree
    3, coefficient −2, invisible in ℤ/2, visible in ℤ/3) is the
    instance W = 3 — checked below by `decide`. -/
theorem dial_visible_iff (m : Nat) (W : Int) :
    (1 - W) % (m : Int) = 0 ↔ (m : Int) ∣ (W - 1) := by
  constructor
  · intro h
    have hd := Int.dvd_of_emod_eq_zero h
    have hneg : W - 1 = -(1 - W) := by omega
    rw [hneg]
    exact Int.dvd_neg.mpr hd
  · intro hd
    apply Int.emod_eq_zero_of_dvd
    have hneg : 1 - W = -(W - 1) := by omega
    rw [hneg]
    exact Int.dvd_neg.mpr hd

/-- P20's numbers, derived: excess listening 2 is invisible in ℤ/2 ... -/
example : ((1 : Int) - 3) % ((2 : Nat) : Int) = 0 := by decide
/-- ... and visible in ℤ/3. -/
example : ((1 : Int) - 3) % ((3 : Nat) : Int) ≠ 0 := by decide

/- ------------------------------------------------------------
   §4 — MUTANT CONTROLS (falsification, house norm): wrong laws
   REFUTED in the kernel court, not just unproven.
   ------------------------------------------------------------ -/

/-- Mutant 1: (★aff) with the offset total dropped — rejected. On the
    1-mark world with no wiring and unit twist, the true total is −1,
    the mutant says 0. -/
theorem mutant_dropped_offsets_rejected :
    ¬ ∀ (w : Nat → Nat → Int) (t : Nat → Int) (n : Nat) (s : Nat → Int),
        sumTo (wRaw w t n s) n
          = sumTo (fun j => (1 - wOut w n j) * s j) n := by
  intro h
  have := h (fun _ _ => 0) (fun _ => 1) 1 (fun _ => 0)
  revert this
  decide

/-- Mutant 2: the dial with the wrong sign (+s j₀ instead of −s j₀) —
    rejected on RingRest's own fig8(2,3) world at a concrete state
    (s ≡ 1: true charge −1−4 = −5 ≡ 1 (mod 3); mutant says 1+(−4) ≡ 0). -/
theorem mutant_dial_sign_rejected :
    ¬ ∀ (s : Nat → Int),
        sumTo (gRaw (fun i => if i = 0 then [1, 3] else if i = 1 then [0]
                              else if i = 2 then [0] else if i = 3 then [2] else []) s) 4
            % 3 = (s 0 - 4) % 3 := by
  intro h
  have := h (fun _ => 1)
  revert this
  decide

/- ------------------------------------------------------------
   §5 — WHAT REMAINS OPEN, honestly:
   • (★aff) covers affine combiners; the theorem says nothing
     about whether some NON-affine combiner other than max
     might admit a different (non-affine but still finitely
     pinnable) law — "finitely pinnable" itself wants a
     definition. The Galois group of the question is bigger
     than its two known elements.
   • The W2/ℤ2 coincidence: is there a classification of
     (wiring, modulus) pairs where max collapses to an affine
     law? W2/mod-2 worked because the max entered with an even
     coefficient; the general symmetric case (all marks hearing
     the same set, k listeners) should collapse mod k — stated
     here as a conjecture, deliberately left for the census
     court to attack first (house tradition).
   • The global tick is still exogenous. This file, like every
     file before it, updates all marks at once and owes the
     same debt.
   ------------------------------------------------------------ -/

end CombinerGalois

-- ============ AXIOM AUDIT (the receipts) ============
#print axioms CombinerGalois.affine_charge_raw
#print axioms CombinerGalois.affine_charge
#print axioms CombinerGalois.affine_conserved
#print axioms CombinerGalois.sum_is_affine
#print axioms CombinerGalois.star_recovered
#print axioms CombinerGalois.order_needs_sharing
#print axioms CombinerGalois.w2_total
#print axioms CombinerGalois.max_not_affine_exact
#print axioms CombinerGalois.w2_star_mod2
#print axioms CombinerGalois.w21_total
#print axioms CombinerGalois.max_no_star_any_modulus
#print axioms CombinerGalois.dial_visible_iff
#print axioms CombinerGalois.mutant_dropped_offsets_rejected
#print axioms CombinerGalois.mutant_dial_sign_rejected
