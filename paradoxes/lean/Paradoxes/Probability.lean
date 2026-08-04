/-!
# Paradoxes of Probability and Statistics

Fourteen classical probability/statistics paradoxes formalized over *finite,
exact* sample spaces.  Every probability claim becomes a statement about
integer counts: uniform chance = "k cases out of n", comparisons of ratios
become cross-multiplied integer inequalities, and the whole thing is proved
by `decide` (kernel computation) or `omega`.  The `#eval` lines print the
underlying counting tables at compile time.  No measure theory is needed —
these paradoxes live entirely in the arithmetic of finite enumerations,
which is exactly why they are theorems, not mysteries.
-/

namespace Paradoxes.Probability

/- ----------------------------------------------------------------------
(1) MONTY HALL — game theory / conditional probability.

Story: a prize hides behind one of three doors; you pick a door; the host,
who knows where the prize is, opens a different, prize-free door and offers
you a switch.  Intuition screams "50/50 now", but switching wins 2/3 of the
time.

Formalized: enumerate all 9 equally likely (prize, pick) pairs in
Fin 3 × Fin 3.  Switching wins exactly when your first pick missed the
prize — 6 of 9 cases; staying wins in the 3 of 9 where you were right.
A richer weighted model also enumerates the host's door: each (prize, pick)
pair carries total weight 2 (host splits 1/1 when he has a choice, weight 2
when forced), 18 weight in all, and switching carries weight 12.  Even the
*conditional* table (pick door 0, host opens door 2) is 2-to-1 for
switching.

Resolution: the host's door-opening is not fresh evidence about YOUR door —
your pick was right with probability 1/3 and nothing the host is forced to
do changes that.  The enumeration makes the 2/3 an exact count.
---------------------------------------------------------------------- -/

def fin3 : List (Fin 3) := [0, 1, 2]

/-- All 9 equally likely (prize, pick) configurations. -/
def montyPairs : List (Fin 3 × Fin 3) :=
  fin3.flatMap fun prize => fin3.map fun pick => (prize, pick)

def switchWins (pc : Fin 3 × Fin 3) : Bool := pc.1 != pc.2
def stayWins   (pc : Fin 3 × Fin 3) : Bool := pc.1 == pc.2

theorem monty_hall :
    montyPairs.length = 9 ∧
    montyPairs.countP switchWins = 6 ∧
    montyPairs.countP stayWins = 3 := by decide

/-- Richer model: (prize, pick, host, weight).  When prize = pick the host
chooses either goat door (weight 1 each); otherwise he is forced (weight 2).
Every (prize, pick) pair thus carries total weight 2; grand total 18. -/
def montyFull : List (Fin 3 × Fin 3 × Fin 3 × Nat) :=
  fin3.flatMap fun prize => fin3.flatMap fun pick =>
    (fin3.filter fun host => host != pick && host != prize).map fun host =>
      (prize, pick, host, if prize == pick then 1 else 2)

def wSum (l : List (Fin 3 × Fin 3 × Fin 3 × Nat)) : Nat :=
  (l.map fun x => x.2.2.2).sum

theorem monty_hall_weighted :
    wSum montyFull = 18 ∧
    wSum (montyFull.filter fun x => x.1 != x.2.1) = 12 := by decide

/-- Conditional check: you picked door 0 and the host opened door 2.
Remaining weight 3, of which prize-behind-door-1 (switch wins) has weight 2. -/
theorem monty_hall_conditional :
    wSum (montyFull.filter fun x => x.2.1 == 0 && x.2.2.1 == 2) = 3 ∧
    wSum (montyFull.filter fun x =>
      x.2.1 == 0 && x.2.2.1 == 2 && x.1 != x.2.1) = 2 := by decide

#eval s!"Monty Hall: of {montyPairs.length} uniform (prize,pick) cases, switching wins {montyPairs.countP switchWins}, staying wins {montyPairs.countP stayWins}"
#eval s!"Monty Hall with host: total weight {wSum montyFull}, switch-wins weight {wSum (montyFull.filter fun x => x.1 != x.2.1)} (= 2/3)"

/- ----------------------------------------------------------------------
(2) THREE PRISONERS — conditional probability.

Story: three prisoners A, B, C; one (uniformly chosen) will be pardoned.
The warden, who knows, tells A the name of one of B, C who will be
executed (choosing fairly when both will be).  A thinks his survival
chance rose from 1/3 to 1/2; in fact it is still 1/3, while the unnamed
prisoner's chance rose to 2/3.

NOTE: this is Monty Hall relabeled — prisoners = doors, pardon = prize,
warden's named victim = host's opened door, "the unnamed other prisoner" =
"the door you would switch to".  `monty_hall_weighted` and
`monty_hall_conditional` above ARE the three-prisoners theorems under this
dictionary, so no separate formalization is given.
---------------------------------------------------------------------- -/

/- ----------------------------------------------------------------------
(3) BERTRAND'S BOX — conditional probability.

Story: three boxes hold two gold coins (GG), one gold + one silver (GS),
and two silver (SS).  Pick a box and a coin at random; the coin is gold.
Intuition says the box is GG or GS with chance 1/2 each; actually
P(other coin is gold) = 2/3.

Formalized: conditioning on "drew gold" leaves 3 equally likely gold
coins — two live in GG, one in GS.  The partner coin is gold for exactly
2 of the 3.

Resolution: condition on coins, not boxes: GG is twice as likely to have
produced a gold draw as GS.
---------------------------------------------------------------------- -/

inductive Box
  | GG | GS | SS
deriving DecidableEq, Repr

/-- The three equally likely gold coins, each labeled by its home box. -/
def goldCoins : List Box := [.GG, .GG, .GS]

def partnerIsGold : Box → Bool
  | .GG => true
  | _   => false

theorem bertrands_box :
    goldCoins.length = 3 ∧ goldCoins.countP partnerIsGold = 2 := by decide

#eval s!"Bertrand's box: {goldCoins.countP partnerIsGold} of the {goldCoins.length} equally likely gold coins have a gold partner: P = 2/3, not 1/2"

/- ----------------------------------------------------------------------
(4) BOY OR GIRL PARADOX — probability / ambiguity of conditioning.

Story: "Mr. Smith has two children. At least one of them is a boy. What is
the probability that both are boys?"  Depending on how the information was
obtained, the answer is 1/3 or 1/2 — and both camps are right about
different questions.

Formalized: families are ordered pairs (eldest, youngest) from
{BB, BG, GB, GG}, uniform.  Conditioning on "at least one boy" keeps
3 families of which 1 is BB; conditioning on "the eldest is a boy" keeps
2 of which 1 is BB.

Resolution: the paradox IS the ambiguity of the conditioning event.  Both
counts are exact; English underdetermines which event was observed.
---------------------------------------------------------------------- -/

inductive Child
  | boy | girl
deriving DecidableEq, Repr

/-- All four equally likely (eldest, youngest) families. -/
def families : List (Child × Child) :=
  [(.boy, .boy), (.boy, .girl), (.girl, .boy), (.girl, .girl)]

def bothBoys : Child × Child → Bool
  | (.boy, .boy) => true
  | _            => false

def someBoy : Child × Child → Bool
  | (.girl, .girl) => false
  | _              => true

def eldestBoy : Child × Child → Bool
  | (.boy, _) => true
  | _         => false

theorem boy_girl_at_least_one :
    families.countP someBoy = 3 ∧
    families.countP (fun f => someBoy f && bothBoys f) = 1 := by decide

theorem boy_girl_eldest :
    families.countP eldestBoy = 2 ∧
    families.countP (fun f => eldestBoy f && bothBoys f) = 1 := by decide

#eval s!"Boy-girl: P(BB | some boy) = {families.countP (fun f => someBoy f && bothBoys f)}/{families.countP someBoy}, but P(BB | eldest boy) = {families.countP (fun f => eldestBoy f && bothBoys f)}/{families.countP eldestBoy}"

/- ----------------------------------------------------------------------
(5) BIRTHDAY PARADOX — combinatorics.

Story: among just 23 people, the chance that two share a birthday already
exceeds 1/2, though 23 is tiny next to 365.

Formalized: the number of ways to give 23 people DISTINCT birthdays is the
falling factorial 365 · 364 · ⋯ · 343; the total is 365²³.  The theorem
`2 * (falling factorial) < 365²³` says P(all distinct) < 1/2 — an exact
comparison of two 59-digit integers, decided by the kernel, no floats.

Resolution: what matters is the ~23·22/2 = 253 PAIRS, not the 23 people.
---------------------------------------------------------------------- -/

/-- Falling factorial n · (n-1) · ⋯ · (n-k+1): ways to pick k distinct
ordered birthdays from n days. -/
def fallingProd (n k : Nat) : Nat :=
  (List.range k).foldl (fun acc i => acc * (n - i)) 1

theorem birthday_paradox : 2 * fallingProd 365 23 < 365 ^ 23 := by decide

/-- Float estimate of P(all 23 birthdays distinct) ≈ 0.4927. -/
def birthdayApprox : Float :=
  (List.range 23).foldl (fun acc i => acc * (365.0 - i.toFloat) / 365.0) 1.0

#eval s!"Birthday: distinct assignments = {fallingProd 365 23}"
#eval s!"Birthday: total assignments   = {(365 : Nat) ^ 23}"
#eval s!"Birthday: P(all 23 distinct) ≈ {birthdayApprox}, so P(shared birthday) ≈ {1.0 - birthdayApprox}"

/- ----------------------------------------------------------------------
(6) BASE-RATE FALLACY (false-positive paradox) — medicine's favorite.

Story: a disease afflicts 1 in 1000.  A test catches 99% of the sick
(sensitivity) but also flags 5% of the healthy.  You test positive.
Most people — including physicians in the famous surveys — guess you are
~95% likely sick.  Actually it is under 2%.

Formalized: per 100000 people — 100 sick of whom 99 test positive; 99900
healthy of whom 4995 test positive.  So positives number 99 + 4995 = 5094,
and P(sick | positive) = 99/5094 < 1/25.  All counts and the final
cross-multiplied inequality are decided.

Resolution: the false positives from the huge healthy majority swamp the
true positives from the tiny sick minority.  Never ignore the base rate.
---------------------------------------------------------------------- -/

def population    : Nat := 100000
def sickCount     : Nat := 100      -- prevalence 1/1000
def healthyCount  : Nat := 99900
def truePositives : Nat := 99       -- sensitivity 99%
def falsePositives : Nat := 4995    -- false-positive rate 5%

/-- The confusion table really does follow from the stated rates. -/
theorem base_rate_table :
    sickCount * 1000 = population ∧
    healthyCount = population - sickCount ∧
    truePositives * 100 = sickCount * 99 ∧
    falsePositives * 100 = healthyCount * 5 := by decide

/-- P(sick | positive) = 99/5094 < 1/25 (i.e. < 4%), by cross-multiplication. -/
theorem base_rate_fallacy :
    truePositives * 25 < truePositives + falsePositives := by decide

#eval s!"Base rate: of {population} people, {sickCount} sick ({truePositives} test +), {healthyCount} healthy ({falsePositives} test +)"
#eval s!"Base rate: P(sick | positive) = {truePositives}/{truePositives + falsePositives} ≈ {Float.ofNat truePositives / Float.ofNat (truePositives + falsePositives)} — under 1/25 despite a 99%-sensitive test"

/- ----------------------------------------------------------------------
(7) SLEEPING BEAUTY — philosophy of probability.

Story: Beauty is put to sleep; a fair coin is flipped.  Heads: she is
awakened once.  Tails: awakened twice (with amnesia between).  On an
awakening, what should her credence in heads be?  "Thirders" say 1/3,
"halfers" say 1/2, and the literature has fought for decades.

Formalized: run the experiment 2N times — N heads-runs and N tails-runs.
Heads-runs produce N awakenings, tails-runs produce 2N.  Thirder count:
heads-awakenings are exactly 1/3 of all awakenings (∀ N, 3·N = N + 2N).
Halfer count: heads-runs are exactly 1/2 of all runs (∀ N, 2·N = N + N).

Resolution (such as it is): both frequencies are exact theorems.  The
dispute is not arithmetic but semantic — whether "her credence on an
awakening" names the per-awakening ratio or the per-run ratio.
---------------------------------------------------------------------- -/

def headsRuns        (N : Nat) : Nat := N
def tailsRuns        (N : Nat) : Nat := N
def headsAwakenings  (N : Nat) : Nat := N        -- one awakening per heads-run
def tailsAwakenings  (N : Nat) : Nat := 2 * N    -- two per tails-run
def totalAwakenings  (N : Nat) : Nat := headsAwakenings N + tailsAwakenings N
def totalRuns        (N : Nat) : Nat := headsRuns N + tailsRuns N

/-- Thirder: among awakenings, heads-awakenings have exact frequency 1/3. -/
theorem sleeping_beauty_thirder (N : Nat) :
    3 * headsAwakenings N = totalAwakenings N := by
  unfold totalAwakenings headsAwakenings tailsAwakenings
  omega

/-- Halfer: among runs of the experiment, heads has exact frequency 1/2. -/
theorem sleeping_beauty_halfer (N : Nat) :
    2 * headsRuns N = totalRuns N := by
  unfold totalRuns headsRuns tailsRuns
  omega

#eval s!"Sleeping Beauty, N = 1000 runs each way: heads awakenings {headsAwakenings 1000} of {totalAwakenings 1000} (thirder 1/3); heads runs {headsRuns 1000} of {totalRuns 1000} (halfer 1/2)"

/- ----------------------------------------------------------------------
(8) TWO ENVELOPES — decision theory.

Story: two envelopes hold a and 2a; you get one uniformly at random.  The
seductive argument: "my envelope holds m; the other holds 2m or m/2 with
probability 1/2 each, so switching yields E = ½·2m + ½·(m/2) = 5m/4 > m —
always switch!"  By symmetry the other player argues the same.  Absurd.

Formalized: fix the pair (a, 2a).  If you hold the smaller, switching
gains 2a - a = +a; if the larger, a - 2a = -a.  Both cases equally likely,
so the (2×) expected gain is their sum: (2a - a) + (a - 2a) = 0, for every
integer a.

Resolution: the 5m/4 computation uses one symbol m for two different
random quantities — conditional on holding the smaller envelope m "is" a,
conditional on holding the larger m "is" 2a.  Fixing the actual pair
dissolves the paradox: the expected gain of switching is exactly 0.
---------------------------------------------------------------------- -/

def gainIfHoldingSmaller (a : Int) : Int := 2 * a - a
def gainIfHoldingLarger  (a : Int) : Int := a - 2 * a

theorem two_envelopes (a : Int) :
    gainIfHoldingSmaller a + gainIfHoldingLarger a = 0 := by
  unfold gainIfHoldingSmaller gainIfHoldingLarger
  omega

#eval s!"Two envelopes (a = 100): gain if holding smaller {gainIfHoldingSmaller 100}, if larger {gainIfHoldingLarger 100}, sum {gainIfHoldingSmaller 100 + gainIfHoldingLarger 100}"

/- ----------------------------------------------------------------------
(9) GAMBLER'S FALLACY — independence.

Story: the roulette wheel has come up red four times running, so black is
"due"... it is not.  (Monte Carlo, 1913: red 26 times; fortunes were lost
betting against the streak.)

Formalized: enumerate all 32 equally likely fair-coin sequences of length 5.
Exactly 2 start HHHH, and exactly 1 of those continues with a fifth H —
the conditional probability is 1/2, identical to the unconditional 16/32.
The cross-multiplied identity 1 · 32 = 2 · 16 is the independence statement.

Resolution: a fair coin has no memory; conditioning on the past does not
move the count.
---------------------------------------------------------------------- -/

def bools : List Bool := [true, false]

/-- All 32 equally likely length-5 coin sequences (true = heads). -/
def seqs5 : List (Bool × Bool × Bool × Bool × Bool) :=
  bools.flatMap fun a => bools.flatMap fun b => bools.flatMap fun c =>
    bools.flatMap fun d => bools.map fun e => (a, b, c, d, e)

def startsHHHH : Bool × Bool × Bool × Bool × Bool → Bool
  | (true, true, true, true, _) => true
  | _                           => false

def fifthH : Bool × Bool × Bool × Bool × Bool → Bool
  | (_, _, _, _, e) => e

theorem gamblers_fallacy :
    seqs5.length = 32 ∧
    seqs5.countP startsHHHH = 2 ∧
    seqs5.countP (fun s => startsHHHH s && fifthH s) = 1 ∧
    seqs5.countP fifthH = 16 ∧
    -- P(5th H | HHHH) = P(5th H):  1/2 = 16/32, cross-multiplied:
    seqs5.countP (fun s => startsHHHH s && fifthH s) * seqs5.length
      = seqs5.countP startsHHHH * seqs5.countP fifthH := by decide

#eval s!"Gambler's fallacy: {seqs5.countP startsHHHH} of {seqs5.length} sequences start HHHH; {seqs5.countP (fun s => startsHHHH s && fifthH s)} of those continue H — still 1/2, the coin has no memory"

/- ----------------------------------------------------------------------
(10) SIMPSON'S PARADOX — statistics (real kidney-stone data, Charig et
al. 1986).

Story and data (successes/patients):
                      Treatment A          Treatment B
  small stones        81/87  (93%)   >     234/270 (87%)
  large stones        192/263 (73%)  >     55/80   (69%)
  --------------------------------------------------------
  overall             273/350 (78%)  <     289/350 (83%)

A wins inside BOTH strata yet loses overall.

Formalized: both within-stratum comparisons as cross-multiplied integer
inequalities, the column sums, and the overall reversal — all by decide.

Resolution: stone size confounds — A (open surgery) was given the hard
large-stone cases, B (percutaneous) the easy small-stone ones.  The
aggregate mixes different case-loads; the stratified comparison is the
causally meaningful one.
---------------------------------------------------------------------- -/

theorem simpsons_paradox :
    -- small stones: 81/87 > 234/270
    81 * 270 > 234 * 87 ∧
    -- large stones: 192/263 > 55/80
    192 * 80 > 55 * 263 ∧
    -- totals really are the sums of the strata (350 patients each arm)
    81 + 192 = 273 ∧ 234 + 55 = 289 ∧ 87 + 263 = 350 ∧ 270 + 80 = 350 ∧
    -- overall: 273/350 < 289/350
    273 < 289 := by decide

#eval s!"Simpson (kidney stones): A wins small (81/87 vs 234/270) and large (192/263 vs 55/80) yet loses overall (273/350 vs 289/350)"

/- ----------------------------------------------------------------------
(11) WILL ROGERS PHENOMENON — statistics / medicine.

Story: "When the Okies left Oklahoma and moved to California, they raised
the average intelligence level in both states."  In oncology this is stage
migration: better imaging reclassifies the healthiest "late-stage" patients
as early-stage — and the measured survival of BOTH stages improves with no
patient getting better.

Formalized: move the element 90 from {90, 100} to {1, 2}.  Low group mean:
3/2 → 93/3 (1.5 → 31).  High group mean: 190/2 → 100/1 (95 → 100).  Both
rises are proved as cross-multiplied inequalities on List.sum/length.

Resolution: a transferred element below one group's mean but above the
other's raises both averages; comparing per-stage statistics across
classification regimes is meaningless.
---------------------------------------------------------------------- -/

def lowBefore  : List Nat := [1, 2]
def lowAfter   : List Nat := [1, 2, 90]
def highBefore : List Nat := [90, 100]
def highAfter  : List Nat := [100]

theorem will_rogers :
    -- low mean rises:  (1+2)/2 < (1+2+90)/3, cross-multiplied
    lowBefore.sum * lowAfter.length < lowAfter.sum * lowBefore.length ∧
    -- high mean rises: (90+100)/2 < 100/1, cross-multiplied
    highBefore.sum * highAfter.length < highAfter.sum * highBefore.length := by
  decide

#eval s!"Will Rogers: moving 90 raises low-group mean {lowBefore.sum}/{lowBefore.length} -> {lowAfter.sum}/{lowAfter.length} (1.5 -> 31) AND high-group mean {highBefore.sum}/{highBefore.length} -> {highAfter.sum}/{highAfter.length} (95 -> 100)"

/- ----------------------------------------------------------------------
(12) FRIENDSHIP PARADOX — network science (Feld 1991).

Story: on average, your friends have more friends than you do.  Not a
psychological illusion but a sampling artifact: popular people are
over-represented in friend lists.

Formalized: the star K_{1,3} on Fin 4 (person 0 friends with 1, 2, 3).
Degrees are 3,1,1,1: mean degree 6/4 = 1.5.  Each person's average friend
degree: the hub's friends average 1; each leaf's sole friend has degree 3.
Mean over persons of average-friend-degree = 10/4 = 2.5.  Since both means
are over the SAME 4 people, comparing them is comparing the scaled sums:
6 < 10, by decide.  (Each per-person average is an exact Nat here: 3/3
and 3/1, so Nat division is division.)

Resolution: high-degree vertices appear on many adjacency lists, so
"a friend of a random person" is degree-biased.
---------------------------------------------------------------------- -/

def verts : List (Fin 4) := [0, 1, 2, 3]

/-- Star K_{1,3}: vertex 0 adjacent to 1, 2, 3. -/
def adj (i j : Fin 4) : Bool :=
  (i == 0 && j != 0) || (j == 0 && i != 0)

def deg (v : Fin 4) : Nat := verts.countP (adj v)

/-- Average degree of v's friends (exact in Nat on this graph). -/
def avgFriendDeg (v : Fin 4) : Nat :=
  ((verts.filter (adj v)).map deg).sum / deg v

theorem friendship_paradox :
    (verts.map deg).sum = 6 ∧
    (verts.map avgFriendDeg).sum = 10 ∧
    (verts.map deg).sum < (verts.map avgFriendDeg).sum := by decide

#eval s!"Friendship paradox on K_(1,3): degrees {verts.map deg}, mean {(verts.map deg).sum}/4; avg-friend-degrees {verts.map avgFriendDeg}, mean {(verts.map avgFriendDeg).sum}/4 — your friends have more friends than you"

/- ----------------------------------------------------------------------
(13) ACCURACY PARADOX — machine learning.

Story: on a rare-positive task, the useless classifier that always says
"negative" gets higher accuracy than a model that actually detects
positives.

Formalized: 1000 samples, 10 positive.  Always-negative: 990 correct
(accuracy 990/1000), recall 0/10.  A real model with TP 8, FN 2, FP 48,
TN 942: 950 correct (950/1000), recall 8/10.  decide checks the table sums,
that 950 < 990, and that 0 < 8.

Resolution: under class imbalance, accuracy is dominated by the majority
class; use recall/precision/F1 instead.
---------------------------------------------------------------------- -/

def nSamples   : Nat := 1000
def nPositive  : Nat := 10
-- always-negative classifier
def nullCorrect : Nat := 990   -- TN = 990, everything else missed
def nullRecall  : Nat := 0
-- a genuinely useful model: TP 8, FN 2, FP 48, TN 942
def realCorrect : Nat := 8 + 942
def realRecall  : Nat := 8

theorem accuracy_paradox :
    nullCorrect = nSamples - nPositive ∧
    realCorrect = 950 ∧
    realCorrect < nullCorrect ∧      -- worse accuracy...
    nullRecall < realRecall := by    -- ...but the null model finds nothing
  decide

#eval s!"Accuracy paradox: always-negative scores {nullCorrect}/{nSamples} accuracy vs the real model's {realCorrect}/{nSamples}, yet recall {nullRecall}/{nPositive} vs {realRecall}/{nPositive}"

/- ----------------------------------------------------------------------
(14) BERKSON'S PARADOX — epidemiology / selection bias.

Story: in hospital data, two diseases that are independent in the
population appear negatively correlated — having one seems to "protect"
against the other.

Formalized: population of 100 with independent conditions A and B,
25 in each cell (A∧B, A∧¬B, ¬A∧B, ¬A∧¬B).  Independence in the
population: P(A|B) = P(A|¬B) = 1/2, verified as the cross-multiplied
equality 25·50 = 25·50.  The hospital admits anyone with A or B —
75 people.  Among the admitted, P(A|B) = 25/50 but P(A|¬B) = 25/25 = 1:
the cross-multiplied strict inequality 25·25 < 25·50 exhibits the induced
negative association.

Resolution: conditioning on the collider "admitted" (caused by both A and
B) manufactures dependence: among admitted patients, lacking B forces
having A.
---------------------------------------------------------------------- -/

/-- Population of 100: (hasA, hasB), 25 in each of the four cells. -/
def berksonPop : List (Bool × Bool) :=
  List.replicate 25 (true, true) ++ List.replicate 25 (true, false) ++
  List.replicate 25 (false, true) ++ List.replicate 25 (false, false)

/-- Hospital admits anyone with at least one condition. -/
def admitted : List (Bool × Bool) := berksonPop.filter fun p => p.1 || p.2

/-- In the population, A and B are independent:
P(A|B) = P(A|¬B), i.e. |A∧B|·|¬B| = |A∧¬B|·|B|. -/
theorem berkson_population_independent :
    berksonPop.length = 100 ∧
    berksonPop.countP (fun p => p.1 && p.2) * berksonPop.countP (fun p => !p.2)
      = berksonPop.countP (fun p => p.1 && !p.2) * berksonPop.countP (fun p => p.2) := by
  decide

/-- Among the 75 admitted, P(A|B) = 25/50 < P(A|¬B) = 25/25:
spurious negative association from selection. -/
theorem berksons_paradox :
    admitted.length = 75 ∧
    admitted.countP (fun p => p.1 && p.2) * admitted.countP (fun p => !p.2)
      < admitted.countP (fun p => p.1 && !p.2) * admitted.countP (fun p => p.2) := by
  decide

#eval s!"Berkson: population P(A|B) = {berksonPop.countP (fun p => p.1 && p.2)}/{berksonPop.countP (fun p => p.2)} = P(A|not B) = {berksonPop.countP (fun p => p.1 && !p.2)}/{berksonPop.countP (fun p => !p.2)} (independent)"
#eval s!"Berkson: among {admitted.length} admitted, P(A|B) = {admitted.countP (fun p => p.1 && p.2)}/{admitted.countP (fun p => p.2)} < P(A|not B) = {admitted.countP (fun p => p.1 && !p.2)}/{admitted.countP (fun p => !p.2)} — selection made A and B look negatively associated"

/- ---------------------------------------------------------------------- -/

def catalog : List (String × String) :=
  [ ("Monty Hall",
     "VERIFIED: by decide, switching wins 6/9 uniform (prize,pick) cases, staying 3/9; weighted host model 12/18, conditional table 2/3"),
    ("Three Prisoners",
     "NOTE: isomorphic to Monty Hall under prisoners=doors, pardon=prize, warden's named victim=opened door; covered by the Monty Hall theorems"),
    ("Bertrand's Box",
     "VERIFIED: by decide, 2 of the 3 equally likely gold coins have a gold partner: P(other gold | drew gold) = 2/3"),
    ("Boy or Girl",
     "VERIFIED: by decide, P(BB | at least one boy) = 1/3 yet P(BB | eldest is a boy) = 1/2; the ambiguity of the conditioning event is the paradox"),
    ("Birthday Paradox",
     "VERIFIED: by decide on exact big-integer arithmetic, 2 * (365 falling 23) < 365^23, so P(23 distinct birthdays) < 1/2; Float demo approx 0.4927"),
    ("Base-Rate Fallacy",
     "VERIFIED: by decide, 99 true vs 4995 false positives per 100000: P(sick | positive) < 1/25 despite a 99%-sensitive test"),
    ("Sleeping Beauty",
     "THEOREM: for all N, 3 * heads-awakenings = total awakenings and 2 * heads-runs = total runs; both exact, the dispute is which ratio 'credence' names"),
    ("Two Envelopes",
     "THEOREM: for all a : Int, gain-if-smaller + gain-if-larger = 0; the seductive 5m/4 argument equivocates on m across the two cases"),
    ("Gambler's Fallacy",
     "VERIFIED: by decide over all 32 length-5 sequences, exactly 1 of the 2 HHHH-starts continues H: conditional = unconditional = 1/2"),
    ("Simpson's Paradox",
     "VERIFIED: by decide on Charig kidney-stone data, A beats B in both strata (81*270>234*87, 192*80>55*263) yet loses overall 273 < 289 of 350"),
    ("Will Rogers Phenomenon",
     "VERIFIED: by decide, moving 90 from {90,100} to {1,2} raises both means (1.5 to 31 and 95 to 100) via cross-multiplied inequalities"),
    ("Friendship Paradox",
     "VERIFIED: by decide on star K_{1,3}, scaled mean degree 6 < scaled mean friend-degree 10 over the same 4 people: friends have more friends"),
    ("Accuracy Paradox",
     "VERIFIED: by decide, always-negative accuracy 990/1000 beats the real model's 950/1000 while recall is 0/10 vs 8/10 under 1% prevalence"),
    ("Berkson's Paradox",
     "VERIFIED: by decide, A,B independent in the 25/25/25/25 population but among the 75 admitted P(A|B) = 25/50 < P(A|not B) = 25/25") ]

#eval s!"Catalog: {catalog.length} paradoxes formalized"

end Paradoxes.Probability
