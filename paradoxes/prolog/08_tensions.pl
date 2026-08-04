/* ─────────────────────────────────────────────────────────────────────────────
   08 · Tensions — what contact broke, re-carried into Prolog

   Runnable counterparts of TENSIONS.md concessions that have a Prolog
   footprint, plus observations that only appear once the carrier is a
   logic language (NAF, occurs-check, cut).
   ───────────────────────────────────────────────────────────────────────────── */

:- module(tensions, [run_08/1]).
:- use_module(library(lists)).
:- use_module(library(clpfd)).
:- dynamic absent_fact/1.   % deliberately clause-free — CWA exhibit

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

/* ── K3 tables (shared with 01) ──────────────────────────────────────────── */

k3(false). k3(u). k3(true).
k3_neg(false, true).
k3_neg(true, false).
k3_neg(u, u).

is_false_or_gap(false, true).
is_false_or_gap(u,     true).
is_false_or_gap(true,  false).

/* ═══ C1: strengthened Liar empties K3 ═════════════════════════════════════ */

run_c1 :-
    section('C1 · strengthened Liar — K3 was a waystation'),
    findall(X, (k3(X), k3_neg(X,X)), Plain),
    findall(X, (k3(X), is_false_or_gap(X,Y), X==Y), Str),
    format("plain liar K3 fixpoints:         ~w~n", [Plain]),
    format("strengthened liar K3 fixpoints:  ~w~n", [Str]),
    check('plain liar settles at u', Plain == [u]),
    check('strengthened liar empties K3', Str == []).

/* ═══ C2: + as quus — Prolog's is/2 is mathematical on unbounded ints ══════
   Julia's typemax(Int)+1 wraps.  SWI integers never wrap.  The skeptic's
   bite relocates: not to overflow, but to the question of whether is/2
   implements the *intended* plus — and to clpfd's finite-domain + which
   CAN be modular.  Carrier commitment (Round 6): the substrate has
   opinions.  Prolog has two substrates.                                    */

run_c2 :-
    section('C2 · plus, quus, and two Prolog substrates'),
    Max64 is 2^63 - 1,
    JuliaWrap is Max64 + 1,                    % mathematical; SWI does not wrap
    format("SWI: (2^63-1)+1 = ~w  (Julia Int64 wraps to ~w)~n",
           [JuliaWrap, -9223372036854775808]),
    check('SWI unbounded + agrees with math at 2^63', JuliaWrap =:= 2^63),
    quus(68, 57, Q), Sum is 68+57,
    format("68+57=~w   quus(68,57)=~w~n", [Sum, Q]),
    check('quus deviates from + on the untried case', (Sum =:= 125, Q =:= 5)),
    % clpfd modular domain — a second carrier with opinions
    clpfd_mod_demo(R),
    format("clpfd (3+1) mod 4 = ~w  (modular carrier)~n", [R]),
    check('clpfd finite domain is modular', R =:= 0).

quus(X, Y, Z) :-
    ( X < 57, Y < 57 -> Z is X + Y ; Z = 5 ).

clpfd_mod_demo(R) :-
    R in 0..3,
    R #= (3 + 1) mod 4,
    label([R]).

/* ═══ C5: oscillation / revision sequences ═════════════════════════════════
   Gupta–Belnap revision: iterate f from a seed.  Liar = neg has period 2;
   truth-teller = id has period 1.                                          */

revise(0, _, X, [X]).
revise(N, F, X, [X|Rest]) :-
    N > 0, N1 is N - 1,
    call(F, X, Y),
    revise(N1, F, Y, Rest).

run_c5 :-
    section('C5 · revision sequences — oscillation as fifth shape'),
    revise(6, k3_neg, false, LiarSeq),
    revise(6, =,      false, TTSeq),
    format("liar revision:        ~w~n", [LiarSeq]),
    format("truth-teller revision:~w~n", [TTSeq]),
    check('liar period 2 from false',
          LiarSeq == [false,true,false,true,false,true,false]),
    check('truth-teller period 1',
          TTSeq == [false,false,false,false,false,false,false]).

/* ═══ Prolog-native tension: NAF is not classical negation ═════════════════
   \+ G succeeds when G fails.  It is not ¬.  The difference is the
   strengthened-liar-shaped gap:  \+ \+ G  is not G (floundering /
   insufficient instantiation, and even classically only on ground goals
   under closed-world).  This is Prolog's own K3-adjacent surface.         */

run_naf :-
    section('NAF · Prolog\'s native gap is not a third truth value'),
    ( \+ fail -> N1 = true ; N1 = false ),
    ( \+ true -> N2 = true ; N2 = false ),
    check('\\+ fail succeeds', N1 == true),
    check('\\+ true fails', N2 == false),
    % double NAF on ground: \+ \+ true succeeds; \+ \+ fail fails
    ( \+ \+ true -> D1 = true ; D1 = false ),
    ( \+ \+ fail -> D2 = true ; D2 = false ),
    check('~~true = true (ground)', D1 == true),
    check('~~fail = fail (ground)', D2 == false),
    % the open-world residual: a dynamic predicate with no clauses is "false"
    % under NAF (closed world), whereas classical logic would say "unknown".
    % (SWI modules error on truly undefined predicates — existence_error —
    %  which is itself a containment shape: stratification-by-namespace.)
    ( \+ absent_fact(0) -> U = closed_world_false ; U = open_world_gap ),
    format("\\+ absent_fact(0) (dynamic, 0 clauses) → ~w~n", [U]),
    check('NAF treats empty dynamic as false (CWA)', U == closed_world_false),
    (   catch(totally_undefined_pred_xyzzy(0), error(existence_error(_,_),_), true)
    ->  E = existence_error_refused
    ;   E = unexpected
    ),
    format("bare undefined predicate → ~w (module namespace guard)~n", [E]),
    check('undefined predicate is existence_error not silent fail',
          E == existence_error_refused).

/* ═══ Broome two-envelope proper prior: positive gain everywhere ═══════════
   p(n) = (1/3)*(2/3)^n for pair (2^n, 2^{n+1}).
   Exact rationals via SWI rationals (rdiv).                                 */

p_broome(N, P) :-
    P is rdiv(1,3) * rdiv(2,3)^N.

% observed amount A = 2^N.  Could be the small of pair n=N (prob p(N))
% or the large of pair n=N-1 (prob p(N-1)).
e_gain_switch(0, Gain) :-
    % N=0: A=1 must be small; switch gets +1
    Gain is rdiv(1,1).
e_gain_switch(N, Gain) :-
    N > 0,
    p_broome(N, PN),
    N1 is N - 1, p_broome(N1, PN1),
    Mass is PN + PN1,
    PS is PN / Mass,               % P(small|A)
    A is 2^N,
    % E[gain] = PS * A + (1-PS) * (-A/2)
    Gain is PS * A - (1 - PS) * (A rdiv 2).

run_broome :-
    section('C4 · Broome proper prior — positive gain at every A'),
    findall(N-G, (between(0,4,N), e_gain_switch(N,G)), Rows),
    format("n → E[gain|switch]: ~w~n", [Rows]),
    findall(N, (between(0,4,N), e_gain_switch(N,G), G =< 0), Bad),
    check('E[gain]>0 for n=0..4 under Broome prior', Bad == []).

/* ── entry ───────────────────────────────────────────────────────────────── */

run_08(Result) :-
    clear_fails,
    format("~n══ 08_tensions.pl ══~n", []),
    run_c1,
    run_c2,
    run_c5,
    run_naf,
    run_broome,
    findall(M, fail_msg(M), Fs),
    (   Fs == []
    ->  format("~n08_tensions: all checks pass~n", []),
        Result = ok
    ;   format("~n08_tensions FAILED: ~w~n", [Fs]),
        Result = fail(Fs)
    ).

:- initialization(main, main).
main :- run_08(R), ( R = ok -> halt(0) ; halt(1) ).
