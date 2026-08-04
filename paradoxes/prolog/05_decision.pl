/* ─────────────────────────────────────────────────────────────────────────────
   05 · Decision, games, and the social (Prolog)

   Exact finite cores from paradoxes/05_decision_social.jl and the Rust
   decision_games module: Prisoner's dilemma dominance, Condorcet cycle,
   Newcomb EV comparison (scaled integers), Braess equilibrium arithmetic.
   ───────────────────────────────────────────────────────────────────────────── */

:- module(decision, [run_05/1]).
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

/* ═══ Prisoner's dilemma ═══════════════════════════════════════════════════
   true = cooperate.  Payoff to row player.  Defect strictly dominates;
   mutual coop Pareto-dominates mutual defect.                              */

pd_payoff(c, c, 3).
pd_payoff(c, d, 0).
pd_payoff(d, c, 5).
pd_payoff(d, d, 1).

run_pd :-
    section('Prisoner\'s dilemma — dominance vs Pareto'),
    pd_payoff(d, c, T), pd_payoff(c, c, Cc),
    pd_payoff(d, d, Dd), pd_payoff(c, d, S),
    check('defect vs coop beats coop vs coop', T > Cc),
    check('defect vs defect beats sucker', Dd > S),
    check('mutual coop Pareto-beats mutual defect', Cc > Dd),
    check('temptation > reward > punishment > sucker',
          (T > Cc, Cc > Dd, Dd > S)),
    format("payoffs C/C=~w C/D=~w D/C=~w D/D=~w~n", [Cc, S, T, Dd]).

/* ═══ Condorcet cycle ══════════════════════════════════════════════════════ */

% rank(Voter, Cand, Pos)  — 0 = top
rank(0, a, 0). rank(0, b, 1). rank(0, c, 2).   % A>B>C
rank(1, b, 0). rank(1, c, 1). rank(1, a, 2).   % B>C>A
rank(2, c, 0). rank(2, a, 1). rank(2, b, 2).   % C>A>B

prefers(V, X, Y) :- rank(V, X, RX), rank(V, Y, RY), RX < RY.

votes_for(X, Y, N) :-
    findall(V, (between(0,2,V), prefers(V, X, Y)), Vs),
    length(Vs, N).

maj_prefers(X, Y) :- votes_for(X, Y, N), N >= 2.

run_condorcet :-
    section('Condorcet — transitive voters, cyclic electorate'),
    votes_for(a, b, AB), votes_for(b, c, BC), votes_for(c, a, CA),
    ABl is 3 - AB, BCl is 3 - BC, CAl is 3 - CA,
    format("A beats B ~w-~w; B beats C ~w-~w; C beats A ~w-~w~n",
           [AB, ABl, BC, BCl, CA, CAl]),
    check('majority A>B', maj_prefers(a,b)),
    check('majority B>C', maj_prefers(b,c)),
    check('majority C>A', maj_prefers(c,a)),
    check('cycle: not transitive',
          (maj_prefers(a,b), maj_prefers(b,c), maj_prefers(c,a))).

/* ═══ Newcomb — dominance vs EV (scaled integers, accuracy 90/100) ═════════
   One-box EV: 0.90 * 1_000_000 + 0.10 * 0           = 900_000
   Two-box EV: 0.90 * 1_000     + 0.10 * 1_001_000   = 100_900
   Dominance: two-box gets +1000 in each box-state.
   Scaled ×100 to stay in integers: accuracy 90.                            */

run_newcomb :-
    section('Newcomb — CDT dominance vs EDT expected value'),
    % Predictor accuracy Acc/100; predicts your actual choice with that rate.
    % One-box:  Acc → $1_000_000; Miss → $0
    % Two-box:  Acc → predicted two-box → left empty → $1_000
    %           Miss → predicted one-box → left full  → $1_001_000
    Acc = 90, Miss is 100 - Acc,
    EV1 is Acc * 1000000 + Miss * 0,
    EV2 is Acc * 1000    + Miss * 1001000,
    DomOpen  is 1001000 - 1000000,
    DomEmpty is 1000 - 0,
    format("EV one-box (×100 trials) = ~w~n", [EV1]),
    format("EV two-box (×100 trials) = ~w~n", [EV2]),
    format("dominance margin open/empty = ~w/~w~n", [DomOpen, DomEmpty]),
    check('one-box EV beats two-box EV at 90%', EV1 > EV2),
    check('two-box dominates by 1000 in each state',
          (DomOpen =:= 1000, DomEmpty =:= 1000)).

/* ═══ Braess — integer equilibrium from the Rust/Lean formalization ════════
   Two routes, 4000 drivers.  Cost top = n_top/100 + 45; bottom = 45 + n_bot/100.
   Equal split 2000/2000 → cost 65 each.
   With free bridge: all-on-bridge costs 80; the 2000/2000 split is destroyed
   because unilateral deviation onto bridge pays less than 65.
   Numbers from rust decision_games: 2000/2000 @ 6500 (in 0.01-min units?);
   actually Rust uses: cost units where 6500 means 65.00.
   We mirror the Julia float version with exact rationals via integers ×100.
*/

% cost in hundredths of a minute
cost2(Top, Bot, CTop, CBot) :-
    CTop is Top + 4500,          % Top/100 + 45  →  Top + 4500 in hundredths
    CBot is 4500 + Bot.

% with bridge: routes top, bottom, bridge
% bridge uses both thin roads
cost3(Top, Bot, Br, CT, CB, CBr) :-
    Up is Top + Br,
    Down is Bot + Br,
    CT is Up + 4500,
    CB is 4500 + Down,
    CBr is Up + Down.

run_braess :-
    section('Braess — a free road that slows everyone'),
    cost2(2000, 2000, CT0, CB0),
    format("without bridge, 2000/2000: costs ~w / ~w (hundredths)~n", [CT0, CB0]),
    check('equal split costs 6500 each', (CT0 =:= 6500, CB0 =:= 6500)),
    % unilateral deviation from 2000/2000 onto bridge:
    % Top=1999, Bot=2000, Br=1 → CBr = (1999+1)+(2000+1) = 4001 < 6500
    cost3(1999, 2000, 1, _, _, CBrDev),
    format("deviate one driver onto bridge: cost ~w < 6500~n", [CBrDev]),
    check('bridge destroys the 2000/2000 equilibrium', CBrDev < 6500),
    % all 4000 on bridge
    cost3(0, 0, 4000, _, _, CAll),
    format("all on bridge: cost ~w~n", [CAll]),
    check('all-on-bridge costs 8000 > 6500', CAll =:= 8000),
    check('free road hurt everyone (8000>6500)', CAll > 6500).

/* ═══ Unexpected hanging — backward induction as list elimination ══════════ */

eliminate([], []).
eliminate([_D|Ds], Ds).          % last remaining day is "predictable"

run_hanging :-
    section('unexpected hanging — backward induction eats itself'),
    Days0 = [mon,tue,wed,thu,fri],
    eliminate_all(Days0, Final),
    format("days after full elimination: ~w~n", [Final]),
    check('elimination empties the week', Final == []).

eliminate_all([], []).
eliminate_all(Ds, Final) :-
    Ds = [_|_],
    eliminate(Ds, Ds1),
    format("  eliminated a day; remaining ~w~n", [Ds1]),
    eliminate_all(Ds1, Final).

/* ── entry ───────────────────────────────────────────────────────────────── */

run_05(Result) :-
    clear_fails,
    format("~n══ 05_decision.pl ══~n", []),
    run_pd,
    run_condorcet,
    run_newcomb,
    run_braess,
    run_hanging,
    findall(M, fail_msg(M), Fs),
    (   Fs == []
    ->  format("~n05_decision: all checks pass~n", []),
        Result = ok
    ;   format("~n05_decision FAILED: ~w~n", [Fs]),
        Result = fail(Fs)
    ).

:- initialization(main, main).
main :- run_05(R), ( R = ok -> halt(0) ; halt(1) ).
