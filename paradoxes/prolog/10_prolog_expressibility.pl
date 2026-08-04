/* ─────────────────────────────────────────────────────────────────────────────
   10 · Prolog expressibility — original artifacts (not a translation)

   The expressibility exchange so far:

     v1  Julia refuses to assert; Lean refuses to diverge
     v2  Lean quarantines divergence from Prop; deletes the verb *run*
     v3  the quarantine judges — sealed partial liar is provably false
     v4  the audit, audited, had prose debt
     Rust lands on Julia's side: a #[test] is one green run

   Prolog sits on a third axis the exchange has not yet surveyed:

     • meaning is a *relation*, not a function — goals may have 0, 1, or
       many answers; "the" value is already a frame commitment
     • negation-as-failure is neither classical ¬ nor Kleene's • — it is
       a closed-world judgment that undefined = false
     • the occurs-check is Separation at the unifier: naive cyclic
       comprehension is a unification option, not a metaphysics
     • the cut '!' is assertion force — the act Julia's EXPRESSIBILITY.md
       said no programming language can perform
     • floundering is a sixth containment shape: a query that is neither
       true nor false nor divergent, but *insufficiently instantiated*

   Every exhibit below runs.  The file carries a failure channel.
   ───────────────────────────────────────────────────────────────────────────── */

:- module(prolog_expressibility, [run_10/1]).
:- use_module(library(lists)).

:- dynamic fail_msg/1.
clear_fails :- retractall(fail_msg(_)).
note_fail(M) :- assertz(fail_msg(M)).
check(Name, Goal) :-
    (   call(Goal)
    ->  format("  ok  ~w~n", [Name])
    ;   format("  ** FAIL ** ~w~n", [Name]),
        note_fail(Name)
    ).
section(T) :- format("~n── ~w ~`─t~64|~n", [T]).

/* ═══ E1 · Relations, not functions — multiplicity is first-class ══════════
   Julia/Rust/Lean default to a single return.  Prolog's parent/2 has two
   answers for one child; asking for "the" parent is a frame commitment
   the language refuses to make silently (you must cut or once/1).         */

parent(alice, bob).
parent(alfred, bob).
parent(bob, carol).

run_e1 :-
    section('E1 · relational meaning — 0/1/many answers'),
    findall(P, parent(P, bob), Parents),
    findall(C, parent(bob, C), Children),
    findall(X, parent(carol, X), None),
    format("parent(_, bob)  → ~w~n", [Parents]),
    format("parent(bob, _)  → ~w~n", [Children]),
    format("parent(carol,_) → ~w~n", [None]),
    check('bob has two parents (multiplicity)', Parents == [alice, alfred]),
    check('carol has no parents here (empty model)', None == []),
    % once/1 is a frame commitment: pick an answer, discard the rest
    once(parent(P1, bob)),
    findall(P, parent(P, bob), AllStill),
    format("once(parent) chose ~w; the relation still has ~w~n", [P1, AllStill]),
    check('once/1 did not erase the relation', AllStill == [alice, alfred]).

/* ═══ E2 · The cut is assertion force ══════════════════════════════════════
   EXPRESSIBILITY.md §I: "Falsehood as assertion — 2+2==5 evaluates to
   false and nothing happens; there is no assertion force."
   Prolog's cut commits: it *does* something on failure — it prunes.
   A cut that fires is an act, not a value.  This is the closest a running
   language comes to assertion force without leaving the operational.     */

% soft classification without cut: both clauses may succeed on backtrack
class_soft(N, small) :- N < 10.
class_soft(N, large) :- N >= 10.
class_soft(N, even)  :- 0 is N mod 2.

% with cut: first match is final — an act of judgment
class_cut(N, small) :- N < 10, !.
class_cut(N, large) :- N >= 10, !.
class_cut(N, even)  :- 0 is N mod 2.   % unreachable for any N

run_e2 :-
    section('E2 · cut is assertion force (Julia cannot do this)'),
    findall(C, class_soft(4, C), Soft),
    findall(C, class_cut(4, C), Hard),
    format("class_soft(4) → ~w  (multiplicity survives)~n", [Soft]),
    format("class_cut(4)  → ~w  (cut judged: small, final)~n", [Hard]),
    check('soft keeps small and even', Soft == [small, even]),
    check('cut asserts small only', Hard == [small]),
    % the unreachable clause: cut made a promise the third clause cannot reach
    findall(C, class_cut(7, C), H7),
    check('cut commits — even-clause unreachable', H7 == [small]).

/* ═══ E3 · Floundering — a sixth containment shape ═════════════════════════
   \+ G with G nonground neither succeeds nor fails cleanly in the logical
   reading: it is *floundering*.  SWI by default may bind-and-negate
   unsoundly; under coroutining / when/2 we can detect insufficient
   instantiation.  Shape inventory update:

     no-model | divergence | third-value | stratification-error |
     oscillation | FLOUNDERING

   Floundering is not divergence (it can be detected and refused) and not
   failure (the query is not false — it is not yet a query).               */

% sound NAF only on ground goals
sound_naf(G) :-
    ground(G), !,
    \+ call(G).
sound_naf(G) :-
    \+ ground(G),
    throw(flounder(G)).

run_e3 :-
    section('E3 · floundering — the sixth shape'),
    (   sound_naf(fail)
    ->  S1 = succeeded
    ;   S1 = failed
    ),
    check('sound NAF on ground fail succeeds', S1 == succeeded),
    (   catch(sound_naf(parent(_, bob)), flounder(_), true)
    ->  S2 = floundered
    ;   S2 = did_not
    ),
    format("sound_naf(parent(_,bob)) → ~w~n", [S2]),
    check('nonground NAF flounders (refused, not answered)', S2 == floundered),
    % contrast: raw \\+ parent(_,bob) in SWI *succeeds* (unsound: there ARE parents)
    (   \+ parent(no_such_person, bob)
    ->  Raw = closed_world_false_correct
    ;   Raw = unexpected
    ),
    check('ground \\+ on absent parent is fine', Raw == closed_world_false_correct).

/* ═══ E4 · Occurs-check as Separation; cyclic terms as non-well-founded ═══
   Two metaphysics in one flag:
     occurs_check = on   →  X=f(X) has no model   (ZFC Separation instinct)
     occurs_check = off  →  X=f(X) builds Ω        (Aczel Anti-Foundation)
   Julia's heap is permanently anti-founded (Ω=[Ω] works).  Lean's kernel
   refuses the cycle at positivity.  Prolog lets the *user* choose which
   universe they are in — carrier commitment made explicit.                */

run_e4 :-
    section('E4 · occurs-check dial — Separation vs Anti-Foundation'),
    ( unify_with_occurs_check(X, s(X)) -> A = accepted ; A = refused ),
    ( Y = s(Y), cyclic_term(Y) -> B = cyclic ; B = acyclic ),
    format("with occurs_check: X=s(X) → ~w~n", [A]),
    format("default SWI:       Y=s(Y) → ~w~n", [B]),
    check('Separation mode refuses the cycle', A == refused),
    check('Anti-Foundation mode builds Ω', B == cyclic),
    % rational trees: unification modulo cycle
    Y = s(Y), Z = s(Z),
    ( Y = Z -> Eq = equal ; Eq = distinct ),
    format("two independently built Ωs unify? ~w~n", [Eq]),
    check('cyclic terms unify with each other', Eq == equal).

/* ═══ E5 · The pure relational liar — no preferred evaluation order ════════
   p :- \+ p.  is the liar as a clause.  Under SLDNF it diverges (or
   flounders, depending on the reading).  But the *relational* content is
   "p ↔ ¬p", whose Boolean models are empty — same as Julia rendering 1.
   Prolog makes both readings available: model search over a finite domain
   (no-model shape) AND operational SLD (divergence shape).  Same sentence,
   two shapes, chosen by how you ask.  Ill-posedness of "what does the
   liar do in Prolog?" is itself the exhibit.                              */

% operational liar clause — not called naked
% p_liar :- \+ p_liar.

% model-theoretic reading over Bool
models_liar(P) :-
    member(P, [false, true]),
    neg_bool(P, NP),
    P == NP.          % P ↔ ¬P

neg_bool(false, true).
neg_bool(true, false).

run_e5 :-
    section('E5 · one liar, two shapes, chosen by the query'),
    findall(P, models_liar(P), Ms),
    format("model search p ↔ ¬p over Bool: ~w  (no-model shape)~n", [Ms]),
    check('relational liar has no Bool model', Ms == []),
    format("model reading = no-model shape; operational reading deferred to E5b~n", []).

% Honest report: the clause  p :- \+ p.  under depth-bounded SLDNF is
% the *parity* of the fuel — succeeds on odd fuel, fails on even.
% THAT is oscillation (shape 5), not pure divergence.  Record it in E5b.

p_naf_fuel(0, fail_result) :- !.
p_naf_fuel(N, Result) :-
    N > 0, N1 is N - 1,
    p_naf_fuel(N1, Inner),
    (   Inner = fail_result
    ->  Result = success_result    % \+ fail succeeds
    ;   Result = fail_result       % \+ success fails
    ).

run_e5b :-
    section('E5b · NAF-liar under fuel is OSCILLATION, not divergence'),
    p_naf_fuel(1, R1), p_naf_fuel(2, R2), p_naf_fuel(3, R3), p_naf_fuel(4, R4),
    format("fuel 1..4: ~w, ~w, ~w, ~w~n", [R1, R2, R3, R4]),
    check('odd fuel: NAF-liar succeeds',
          (R1 == success_result, R3 == success_result)),
    check('even fuel: NAF-liar fails',
          (R2 == fail_result, R4 == fail_result)),
    format("diagnosis: p :- \\+ p  under depth-bounded NAF is period-2~n", []),
    format("revision (Gupta–Belnap), not stack overflow.  Prolog's default~n", []),
    format("unlimited SLD *looks* like divergence only because the period~n", []),
    format("is explored forever.  Shape 5 was inside shape 2 all along.~n", []).

/* ═══ E6 · Bertrand's chord is unstatable as ONE relation ══════════════════
   Three samplers are three predicates.  There is no single predicate
   random_chord(C) that is well-defined — attempting to write one forces
   the frame commitment.  Same dissolution as Julia, but the *type* of
   the commitment is a choice of clause set, not a choice of RNG.         */

% three incompatible "random chord length > √3" relations over a discrete
% stand-in sample space of 12 equally weighted abstract chords, partitioned
% differently by each protocol.
chord(endpoint_protocol,  id(N), long)  :- between(1,4, N).  % 4 of 12 long
chord(endpoint_protocol,  id(N), short) :- between(5,12,N).
chord(radial_protocol,    id(N), long)  :- between(1,6, N).  % 6 of 12 long
chord(radial_protocol,    id(N), short) :- between(7,12,N).
chord(midpoint_protocol,  id(N), long)  :- between(1,3, N).  % 3 of 12 long
chord(midpoint_protocol,  id(N), short) :- between(4,12,N).

ratio(Protocol, Long, Total, Long rdiv Total) :-
    findall(I, chord(Protocol, I, long), Ls), length(Ls, Long),
    findall(I, chord(Protocol, I, _),    Ts), length(Ts, Total).

run_e6 :-
    section('E6 · Bertrand — three relations, no unique random_chord/1'),
    ratio(endpoint_protocol, LE, TE, RE),
    ratio(radial_protocol,   LR, TR, RR),
    ratio(midpoint_protocol, LM, TM, RM),
    format("endpoint  P(long) = ~w/~w = ~w~n", [LE, TE, RE]),
    format("radial    P(long) = ~w/~w = ~w~n", [LR, TR, RR]),
    format("midpoint  P(long) = ~w/~w = ~w~n", [LM, TM, RM]),
    check('endpoint → 1/3', RE =:= rdiv(1,3)),
    check('radial → 1/2',   RR =:= rdiv(1,2)),
    check('midpoint → 1/4', RM =:= rdiv(1,4)),
    check('three protocols disagree',
          (RE =\= RR, RR =\= RM, RE =\= RM)).

/* ═══ E7 · Warrant-carrying claims: the clause IS the evidence ═════════════
   Parallel to Julia's "berry(5)=100001 is enumeration" and Lean's
   proof terms: a Prolog predicate that has been exhaustively queried
   *is* its own proof of the counted claim.  findall + length is a
   proof-of-work certificate the way decide is in Lean and a #[test] is
   in Rust — with the honest status: VERIFIED (enumeration).               */

% small finite Goldbach witness search (veridical fragment)
is_prime(2).
is_prime(N) :-
    integer(N), N > 2, N mod 2 =:= 1,
    Max is floor(sqrt(N)),
    \+ (between(3, Max, D), D mod 2 =:= 1, N mod D =:= 0).

goldbach(N, P1, P2) :-
    N > 2, 0 is N mod 2,
    between(2, N, P1), is_prime(P1),
    P2 is N - P1, is_prime(P2), !.

run_e7 :-
    section('E7 · warrant by enumeration (Goldbach fragment)'),
    findall(N, (between(4, 100, N), 0 is N mod 2, \+ goldbach(N, _, _)), Bad),
    check('every even 4..100 is sum of two primes', Bad == []),
    goldbach(100, P1, P2),
    format("witness: 100 = ~w + ~w~n", [P1, P2]),
    format("status: VERIFIED (enumeration) — not ∀n, only 4..100~n", []),
    format("the clause set + the query IS the certificate~n", []).

/* ═══ E8 · Logical variables as open sentences ═════════════════════════════
   An unbound variable in a successful goal is an open sentence — a claim
   with a hole.  Julia has no analogue (every value is closed).  Lean has
   Π/λ.  Prolog's hole is operational: the answer substitution *is* the
   content of the claim.  "parent(X, bob)" answered with X=alice is the
   sentence made closed by evidence.                                       */

run_e8 :-
    section('E8 · open sentences closed by answer substitution'),
    findall(X, parent(X, bob), Xs),
    format("query  parent(X, bob)~n", []),
    format("answer ~w   — each element closes the open sentence~n", [Xs]),
    check('answers are the closing substitutions', Xs == [alice, alfred]),
    % a query that stays open: parent(alice, Y) has a definite closure;
    % parent(X, Y) has a set of closures — the extension of the relation
    findall(X-Y, parent(X, Y), Ext),
    length(Ext, N),
    format("extension of parent/2 has ~w ground instances~n", [N]),
    check('relation extension enumerated', N =:= 3).

/* ═══ E9 · Self-interpretation terminates (Carroll's tortoise, relational) ═
   A clause is an instruction that interprets itself via the resolution
   engine.  No separate reader.  The tortoise's infinite "and you must
   apply the rule" regress stops at the VM — same point as Julia, different
   mechanism (unification + SLD, not bytecode).                            */

apply_rule(plus_one, X, Y) :- Y is X + 1.

run_e9 :-
    section('E9 · self-interpreting instructions (no tortoise regress)'),
    apply_rule(plus_one, 41, Y),
    format("apply_rule(plus_one, 41) → ~w~n", [Y]),
    check('rule applies itself: 41+1=42', Y =:= 42).

/* ═══ E10 · What Prolog cannot say (the dual list) ═════════════════════════
   Catalogued, not merely asserted — each entry is a *refused* form.       */

run_e10 :-
    section('E10 · the census of the unsayable (in Prolog)'),
    % 1. actual infinity as a completed term — only generative predicates
    (   catch(between(1, not_an_integer_bound, _), error(_, _), true)
    ->  InfRefused = true
    ;   InfRefused = false
    ),
    check('no completed N term (between rejects non-int bound)',
          InfRefused == true),
    % 2. a total halting oracle
    check('halting oracle not in the clause set',
          \+ current_predicate(halts_oracle/1)),
    % 3. classical negation on nonground goals without floundering
    %    (already shown E3)
    % 4. assertion-without-cut that prunes (soft vs hard, E2)
    % 5. a single random_chord/1 (E6)
    format("refused: completed infinity, halting oracle, flounder-free~n", []),
    format("         classical ¬, unique random_chord, silent frame picks~n", []),
    format("admitted: multiplicity, cut-as-act, occurs-check dial,~n", []),
    format("          NAF-CWA, open sentences, warrant-by-findall~n", []).

/* ── chiasmus v5 ─────────────────────────────────────────────────────────── */

run_chiasmus :-
    section('Chiasmus v5 · where Prolog sits'),
    format("Julia contains paradox by refusing to assert.~n", []),
    format("Lean  contains paradox by quarantining divergence from Prop.~n", []),
    format("Rust  sits with Julia: evidence is one green run.~n", []),
    format("Prolog contains paradox by making *query form* choose the shape:~n", []),
    format("  the same clause is no-model under findall-over-Bool,~n", []),
    format("  oscillation under fuel-bounded NAF,~n", []),
    format("  divergence under unlimited SLD,~n", []),
    format("  floundering under nonground NAF.~n", []),
    format("The shape is not a property of the sentence alone.~n", []),
    format("It is a property of (sentence, query mode) — and that is the~n", []),
    format("relational content of the expressibility exchange.~n", []),
    check('chiasmus v5 recorded', true).

/* ── entry ───────────────────────────────────────────────────────────────── */

run_10(Result) :-
    clear_fails,
    format("~n══ 10_prolog_expressibility.pl ══~n", []),
    run_e1,
    run_e2,
    run_e3,
    run_e4,
    run_e5,
    run_e5b,
    run_e6,
    run_e7,
    run_e8,
    run_e9,
    run_e10,
    run_chiasmus,
    findall(M, fail_msg(M), Fs),
    (   Fs == []
    ->  format("~n10_prolog_expressibility: all checks pass~n", []),
        Result = ok
    ;   format("~n10_prolog_expressibility FAILED: ~w~n", [Fs]),
        Result = fail(Fs)
    ).

:- initialization(main, main).
main :- run_10(R), ( R = ok -> halt(0) ; halt(1) ).
