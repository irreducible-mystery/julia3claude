# Paraconsistent Annotated Evidential Logic Eτ (PAL2v) — Explorations

A five-session arc exploring Paraconsistent Annotated Evidential Logic Eτ
(PAL2v, via the [`paraconsistent`](https://eailab-ifsp.github.io/Paraconsistent-Lib)
Python library, EAILAB-IFSP), ending with the instrument turned on itself.

In PAL2v every proposition carries an annotation (μ, λ) — favorable and
unfavorable evidence in [0,1] — from which the logic derives a degree of
certainty **dc = μ − λ**, a degree of contradiction **dct = μ + λ − 1**, and
a placement in a 12-region lattice: true *t*, false *f*, inconsistent *┬*,
paracomplete *┴*, undefined center *I*, plus eight quasi/transition states.
The recurring theme across all sessions: the lattice's deepest service is
**separating over-determination (┬, conflicting evidence) from
under-determination (┴, no evidence)** — a distinction classical logic
cannot state.

## The arc

| # | Study | Script | Report | Key finding |
|---|-------|--------|--------|-------------|
| 1 | Conflicting data & fuzzy boundaries | `experiment1_conflicting_data.py`, `experiment2_fuzzy_boundaries.py` | [`results/REPORT.md`](results/REPORT.md) | Contradiction (dct) as a measurable, orthogonal axis; principled abstention on Iris gets 100% accuracy on decided samples |
| 2 | Five paradoxes, five domains | `paradox_suite.py` | [`results/PARADOX_REPORT.md`](results/PARADOX_REPORT.md) | The lattice *taxonomizes* paradox: Liar/Russell saturate ┬; Sorites travels the certainty axis; Simpson/Condorcet sit between; non-explosion verified |
| 3 | Black holes | `blackhole_paraconsistent.py` | [`results/BLACKHOLE_REPORT.md`](results/BLACKHOLE_REPORT.md) | Information paradox → ┬ (over-determined), singularity → ┴ (theory silence) — the same object hosts opposite epistemic pathologies; islands resolution = lattice trajectory ┬ → t |
| 4 | The cartography of confabulation (agent's choice) | `confabulation_cartography.py` | [`results/CONFABULATION_REPORT.md`](results/CONFABULATION_REPORT.md) | Hallucination = ┴ masked as t, invisible to scalar confidence; RLHF as a vector field evacuating honest ignorance; pure introspection is bistable, informative only when externally anchored |
| 5 | The instrument turned on itself | `critique_suite.py` | [`results/CRITIQUE_REPORT.md`](results/CRITIQUE_REPORT.md) | Encoding is a laundered free parameter; sorites revenge at region borders; a revenge Liar with provably no fixed point; Curry unstatable; fusion non-associative; weight of evidence unstatable; classical metalanguage |

## Running

```bash
pip install paraconsistent numpy pandas matplotlib scikit-learn
python experiment1_conflicting_data.py   # etc. — each script is standalone
```

Each script writes plots/CSVs/logs into `results/` and prints a narrated
analysis to stdout (captured in `results/*_output.txt`).

`pal2v_test.py` is the original smoke test; `asp_test.lp` is an unrelated
Answer Set Programming (clingo) test from the same environment setup.

## The one-paragraph summary of the whole arc

PAL2v proved genuinely useful: it localizes contradictions (the information
paradox ignites only after the Page time; the AMPS trilemma is a quantified
three-way forced choice), distinguishes conflict from ignorance (singularity
as ┴, not ┬), and renders an AI's own failure modes geometric (confabulation
as the ┴-to-t diagonal — the longest journey on the lattice). But the final
audit shows the instrument cannot hold itself: its verdicts are downstream of
unformalized encoding choices, its region borders reintroduce the sharpness
it was praised for dissolving, its own semantic self-reference has no fixed
point, and its machinery is administered by a perfectly classical
metalanguage. Every logic of contradiction is consistent about its
contradictions; the regress ends not in a better logic but in a user.
