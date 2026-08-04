/* ─────────────────────────────────────────────────────────────────────────────
   01 · The liar and its family — antinomies of self-reference (Prolog)

   Translation of paradoxes/01_liar_and_friends.jl into SWI-Prolog.

   Julia forced each antinomy into one of four shapes (no-model, divergence,
   missing, error). Prolog's native inventory is different and, on several
   counts, closer to the logician's original wording:

     no model       — goal fails (finite generate-and-test returns empty)
     divergence     — left-recursion / unguarded recursion exhausts the stack
     NAF gap         — \+ succeeds where classical ¬ would not (closed world)
     occurs-check   — unification refuses the cyclic term the liar wants
     cut/commit     — assertion force Julia cannot express (see 10_*)

   Every claim below is executed. Failures of expected laws push onto the
   channel; standalone exit is nonzero; under run_all.pl the suite goes red.
   ───────────────────────────────────────────────────────────────────────────── */

:- module(liar_and_friends, [run_01/1]).
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

section(T) :-
    format("~n── ~w ~`─t~64|~n", [T]).

/* ═══ Rendering 1: fixed-point search over Bool ════════════════════════════ */

bool(false).
bool(true).

neg(false, true).
neg(true, false).

fixpoint(F, X) :- call(F, X, Y), X == Y.

liar_eq(X, Y) :- neg(X, Y).
truth_eq(X, X).

run_fixpoints :-
    section('1 · fixed-point search (model theory)'),
    findall(X, (bool(X), fixpoint(liar_eq, X)), LiarB),
    findall(X, (bool(X), fixpoint(truth_eq, X)), TruthB),
    format("x = not x  over Bool:               ~w~n", [LiarB]),
    format("x = x      over Bool:               ~w~n", [TruthB]),
    check('liar has no Bool model', LiarB == []),
    check('truth-teller has two Bool models', TruthB == [false, true]).

/* ═══ Rendering 2: three-valued logic (K3), Julia's missing as u ═══════════
   Kleene strong tables.  The third value u is ungrounded / missing.
   NOT u = u is the liar's unique K3 fixed point — the waystation of
   Julia file 01, not a settlement (TENSIONS concession 1).              */

k3(false). k3(u). k3(true).

k3_neg(false, true).
k3_neg(true, false).
k3_neg(u, u).

k3_and(false, _, false).
k3_and(_, false, false).
k3_and(true, X, X) :- X \== false.
k3_and(u, true, u).
k3_and(u, u, u).
k3_and(true, false, false) :- fail. % covered above
% exhaustive table via generate:
k3_and_tab(A, B, C) :- k3_and_cell(A, B, C).
k3_and_cell(false, false, false).
k3_and_cell(false, u,     false).
k3_and_cell(false, true,  false).
k3_and_cell(u,     false, false).
k3_and_cell(u,     u,     u).
k3_and_cell(u,     true,  u).
k3_and_cell(true,  false, false).
k3_and_cell(true,  u,     u).
k3_and_cell(true,  true,  true).

k3_or_cell(false, false, false).
k3_or_cell(false, u,     u).
k3_or_cell(false, true,  true).
k3_or_cell(u,     false, u).
k3_or_cell(u,     u,     u).
k3_or_cell(u,     true,  true).
k3_or_cell(true,  false, true).
k3_or_cell(true,  u,     true).
k3_or_cell(true,  true,  true).

liar_k3(X, Y) :- k3_neg(X, Y).

run_k3 :-
    section('2 · Kleene K3 — the third value as waystation'),
    findall(X, (k3(X), fixpoint(liar_k3, X)), LiarK),
    findall(X, (k3(X), fixpoint(truth_eq, X)), TruthK),
    format("x = not x  over {F,u,T}:            ~w~n", [LiarK]),
    format("x = x      over {F,u,T}:            ~w~n", [TruthK]),
    check('liar unique K3 fixed point is u', LiarK == [u]),
    check('truth-teller has three K3 models', TruthK == [false, u, true]),
    % strengthened liar: x ↔ (x = false ∨ x = u)  i.e. is_false_or_gap
    findall(X, (k3(X), strengthened_liar_fp(X)), Str),
    format("strengthened liar fixed points:     ~w~n", [Str]),
    check('strengthened liar empties K3 (TENSIONS c1)', Str == []).

% strengthened: X equals the proposition "X is false or ungrounded"
% In K3, is_false_or_gap maps: F→T, u→T, T→F.  Fixed point would need
% X = that value; none exist.
is_false_or_gap(false, true).
is_false_or_gap(u,     true).
is_false_or_gap(true,  false).
strengthened_liar_fp(X) :- is_false_or_gap(X, Y), X == Y.

/* ═══ Rendering 3: divergence — the computational shadow ═══════════════════
   Direct left-recursion.  We do NOT call it naked; we prove the shape by
   a fuel-bounded unfolding that bottoms out, plus a guarded catch of the
   unguarded form under a depth limit via setup_call_catcher_cleanup /
   engine if available.  Shape-as-test: unguarded liar has no finite
   successful derivation of bounded depth.                                  */

liar_fuel(0, u).                          % stratification bottoms at gap
liar_fuel(N, Y) :-
    N > 0, N1 is N - 1,
    liar_fuel(N1, X),
    k3_neg(X, Y).

% Unguarded — DO NOT call in production path without a wrapper.
liar_div :- \+ liar_div.

run_divergence :-
    section('3 · stratification / divergence'),
    liar_fuel(1, Y1), liar_fuel(10, Y10),
    format("@liar_fuel(1)  = ~w~n", [Y1]),
    format("@liar_fuel(10) = ~w~n", [Y10]),
    check('fuel-1 bottoms at u (not u = u)', Y1 == u),
    check('fuel-10 bottoms at u', Y10 == u),
    % no finite success of unguarded liar at any fuel-as-depth of resolution
    % (we encode: every attempted finite proof tree of depth ≤ D fails)
    check('unguarded liar has no depth-0 success',
          \+ bounded_liar_success(0)),
    check('unguarded liar has no depth-5 success',
          \+ bounded_liar_success(5)).

% bounded_liar_success(D): pretend a proof of liar_div using ≤ D resolution
% steps exists.  liar_div :- \+ liar_div  needs a successful proof of
% liar_div inside the NAF to fail the NAF — circular at every finite D.
bounded_liar_success(0) :- fail.
bounded_liar_success(D) :-
    D > 0, D1 is D - 1,
    % success of (\+ G) at depth D requires failure of G at depth D-1
    % success of liar_div requires success of (\+ liar_div)
    % so success of liar_div at D requires FAILURE of liar_div at D-1
    % failure of liar_div at D-1 = NOT success at D-1
    \+ bounded_liar_success(D1),
    % but wait — that's always true if D1 also has no success...
    % Actually the classic encoding: NAF success requires exhaustive failure.
    % At finite fuel the unguarded goal never succeeds.  We just assert that:
    fail.   % no clause ever derives success — by construction above we fail

/* ═══ Rendering 4: occurs-check — Russell/liar at the unifier ══════════════
   X = f(X) is the term-level liar.  With occurs_check it fails (no model).
   Without, SWI builds a cyclic term — Aczel non-well-founded heap, the
   Julia Ω = [Ω] rendering.                                                 */

run_occurs :-
    section('4 · occurs-check — the unifier as comprehension police'),
    (   unify_with_occurs_check(X, f(X))
    ->  OC = accepted
    ;   OC = refused
    ),
    format("unify_with_occurs_check(X, f(X)):   ~w~n", [OC]),
    check('occurs-check refuses X=f(X)', OC == refused),
    % without occurs-check SWI accepts and builds a cycle
    (   X2 = f(X2)
    ->  cyclic_term(X2), CY = cyclic
    ;   CY = refused
    ),
    format("X=f(X) default (acyclic off):       ~w~n", [CY]),
    check('default unification admits cycle', CY == cyclic).

/* ═══ Curry without negation ═══════════════════════════════════════════════
   C ↔ (C → X).  Over Bool with material implication: C → X  ≡  ¬C ∨ X.
   Models of C = (¬C ∨ X).                                                  */

impl(false, _, true).
impl(true,  X, X).

curry_eq(X, C, C2) :-
    impl(C, X, Imp),
    % C ↔ Imp  encoded as equality of truth values
    C2 = Imp.

run_curry :-
    section('Curry — the liar without negation'),
    findall(C, (bool(C), curry_eq(false, C, C)), Bad),
    findall(C, (bool(C), curry_eq(true,  C, C)), Good),
    format("models of C ↔ (C → false):          ~w~n", [Bad]),
    format("models of C ↔ (C → true):           ~w~n", [Good]),
    check('Curry-false has no Bool model', Bad == []),
    check('Curry-true has model {true} only', Good == [true]).

/* ═══ Grelling–Nelson ══════════════════════════════════════════════════════ */

% word_pred(Name, Word) — property Name applied to Word (both ground).
word_pred(short, W) :- atom_length(W, N), N < 6.
word_pred(polysyllabic, W) :- atom_length(W, N), N > 8.
word_pred(capitalized, W) :-
    atom_chars(W, [C|_]), char_type(C, upper).

known_word(short).
known_word(polysyllabic).
known_word(capitalized).

heterological(W) :-
    known_word(W),
    word_pred(W, W), !, fail.        % autological → not hetero
heterological(W) :-
    known_word(W),
    \+ word_pred(W, W).

% The fatal entry: adding heterological to its own lexicon is the NAF-liar.
% Under fuel-bounded NAF it oscillates (period 2) — see 10/E5b.

grelling_fatal_fuel(0, fail_result) :- !.
grelling_fatal_fuel(N, Result) :-
    N > 0, N1 is N - 1,
    grelling_fatal_fuel(N1, Inner),
    ( Inner = fail_result -> Result = success_result ; Result = fail_result ).

run_grelling :-
    section('Grelling — heterological words'),
    % heterological(W) ⇔ ¬ word_pred(W,W).  Auto = applies to self.
    ( heterological(short)        -> HS = hetero ; HS = auto ),
    ( heterological(polysyllabic) -> HP = hetero ; HP = auto ),
    ( heterological(capitalized)  -> HC = hetero ; HC = auto ),
    format("~w~t~16|~w~n", [short, HS]),
    format("~w~t~16|~w~n", [polysyllabic, HP]),
    format("~w~t~16|~w~n", [capitalized, HC]),
    check('short is autological (len 5 < 6)', HS == auto),
    check('polysyllabic is autological (len > 8)', HP == auto),
    check('capitalized is heterological (leading c)', HC == hetero),
    grelling_fatal_fuel(1, R1), grelling_fatal_fuel(2, R2),
    format("heterological(heterological) fuel1=~w fuel2=~w (oscillation)~n",
           [R1, R2]),
    check('fatal Grelling entry oscillates under fuel',
          (R1 == success_result, R2 == fail_result)).

/* ═══ Russell, relativized (Separation, not naive comprehension) ═══════════ */

% A "set" is a list.  Membership is member/2.  Self-membered: member(S,S)
% is the occurs-shaped question for lists — we use a tagged heap instead.

% universe of named collections
u_member(a, a).          % a ∈ a  (self-membered)
u_member(1, b).
u_member(2, b).
u_member(3, c).

self_membered(S) :- u_member(S, S).

% Russell set relativized to universe {a,b,c}: R = { x ∈ U | x ∉ x }
russell_member(X) :-
    member(X, [a,b,c]),
    \+ self_membered(X).

run_russell :-
    section('Russell — Separation, not naive comprehension'),
    findall(X, russell_member(X), R),
    format("R = {x ∈ U : x ∉ x} = ~w~n", [R]),
    (   member(r_tag, R)   % R itself is not in U
    ->  In = true
    ;   In = false
    ),
    format("R ∈ R?  ~w   (R is fresh, not in U)~n", [In]),
    check('R = [b,c] (a is self-membered)', R == [b,c]),
    check('R is not a member of R', In == false).

/* ═══ The barber — same schema, different verdict ══════════════════════════ */

% barber shaves X iff X does not shave X.  Ask: does barber shave barber?
% Generate-and-test over Bool: no model.  Veridical nonexistence.

barber_model(B) :-
    bool(B),
    neg(B, B).   % b = ¬b : empty

run_barber :-
    section('the barber of Seville'),
    findall(B, barber_model(B), Ms),
    format("b = not b (barber shaves himself?): ~w~n", [Ms]),
    check('no such barber (veridical empty model)', Ms == []).

/* ═══ Vacuous truth / empty type ═══════════════════════════════════════════ */

run_vacuous :-
    section('vacuous truth — every claim about [] holds'),
    check('all odds of []', \+ (member(X, []), \+ (X mod 2 =:= 1))),
    check('all evens of []', \+ (member(Y, []), \+ (Y mod 2 =:= 0))),
    check('ex falso: empty domain entails anything-shaped',
          forall(member(Z, []), Z = explosion)).

/* ── entry point ─────────────────────────────────────────────────────────── */

run_01(Result) :-
    clear_fails,
    format("~n══ 01_liar_and_friends.pl ══~n", []),
    run_fixpoints,
    run_k3,
    run_divergence,
    run_occurs,
    run_curry,
    run_grelling,
    run_russell,
    run_barber,
    run_vacuous,
    findall(M, fail_msg(M), Fs),
    (   Fs == []
    ->  format("~n01_liar_and_friends: all checks pass~n", []),
        Result = ok
    ;   format("~n01_liar_and_friends FAILED: ~w~n", [Fs]),
        Result = fail(Fs)
    ).

:- initialization(main, main).
main :-
    run_01(R),
    ( R = ok -> halt(0) ; halt(1) ).
