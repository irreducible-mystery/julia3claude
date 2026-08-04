/* ─────────────────────────────────────────────────────────────────────────────
   04 · Probability and statistics (Prolog)

   Translation of the *exact finite* core of paradoxes/04_probability.jl and
   the Rust/Lean probability module — exhaustive enumeration, not Monte Carlo.
   Where Julia samples 10⁶ trials, Prolog counts the sample space.  Where Rust
   uses BigNat for the birthday crossing, we use SWI's unbounded integers.

   Failure channel throughout.
   ───────────────────────────────────────────────────────────────────────────── */

:- module(probability, [run_04/1]).
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

/* ═══ Monty Hall — all 9 (prize,pick) pairs; switch wins iff pick ≠ prize ══ */

door(0). door(1). door(2).

monty_pair(Prize, Pick) :- door(Prize), door(Pick).

run_monty :-
    section('Monty Hall — exhaustive 9-world enumeration'),
    findall(P-K, monty_pair(P,K), Pairs),
    length(Pairs, N),
    include(switch_win, Pairs, SW), length(SW, NSW),
    include(stay_win,   Pairs, ST), length(ST, NST),
    format("worlds: ~w   stay wins: ~w/~w   switch wins: ~w/~w~n",
           [N, NST, N, NSW, N]),
    check('9 equally likely worlds', N =:= 9),
    check('stay wins 3/9',  NST =:= 3),
    check('switch wins 6/9', NSW =:= 6).

switch_win(P-K) :- P =\= K.
stay_win(P-K)   :- P =:= K.

/* ═══ Bertrand's box ═══════════════════════════════════════════════════════
   Three boxes: GG, GS, SS.  Draw a gold coin; P(other is gold) = 2/3.
   Three equally likely gold-coin draws: GG₁, GG₂, GS.                      */

box_gold_coin(gg).
box_gold_coin(gg).
box_gold_coin(gs).

partner_gold(gg).

run_bertrand_box :-
    section('Bertrand\'s box — three gold coins'),
    findall(B, box_gold_coin(B), Coins),
    length(Coins, N),
    include(partner_gold, Coins, PG), length(PG, NPG),
    format("gold coins: ~w   partner gold: ~w/~w~n", [Coins, NPG, N]),
    check('3 gold-coin draws', N =:= 3),
    check('2 of 3 have gold partner', NPG =:= 2).

/* ═══ Boy or girl — three protocols, exact ═════════════════════════════════ */

child(boy). child(girl).
family(B,G) :- child(B), child(G).   % unordered-as-ordered (elder, younger)
                                     % actually: first, second child

run_boy_girl :-
    section('two children — the answer lives in the protocol'),
    findall(A-B, family(A,B), All), length(All, NAll),
    % protocol A: ≥1 boy → P(two boys)
    include(has_boy, All, AFam), length(AFam, NA),
    include(both_boys, AFam, ABB), length(ABB, NABB),
    % protocol B: a distinguished child (first) is a boy → P(two boys)
    include(first_boy, All, BFam), length(BFam, NB),
    include(both_boys, BFam, BBB), length(BBB, NBBB),
    % protocol C: ≥1 Tuesday-boy.  Day ∈ 1..7, Tuesday = 2.
    findall(f(A,B,DA,DB),
            (family(A,B), between(1,7,DA), between(1,7,DB)),
            AllD),
    include(has_tue_boy, AllD, CFam), length(CFam, NC),
    include(both_boys_d, CFam, CBB), length(CBB, NCBB),
    format("P(BB | ≥1 boy)           = ~w/~w~n", [NABB, NA]),
    format("P(BB | first is boy)     = ~w/~w~n", [NBBB, NB]),
    format("P(BB | ≥1 Tuesday-boy)   = ~w/~w~n", [NCBB, NC]),
    check('4 families', NAll =:= 4),
    check('P(BB|≥1 boy) = 1/3', NABB =:= 1, NA =:= 3),
    check('P(BB|first boy) = 1/2', NBBB =:= 1, NB =:= 2),
    check('P(BB|Tue-boy) = 13/27', NCBB =:= 13, NC =:= 27).

% check/3 helper
check(Name, G1, G2) :-
    (   call(G1), call(G2)
    ->  format("  ok  ~w~n", [Name])
    ;   format("  ** FAIL ** ~w~n", [Name]),
        note_fail(Name)
    ).

has_boy(boy-_).
has_boy(_-boy).
both_boys(boy-boy).
first_boy(boy-_).
has_tue_boy(f(boy,_,2,_)).
has_tue_boy(f(_,boy,_,2)).
both_boys_d(f(boy,boy,_,_)).

/* ═══ Sleeping Beauty — two reference classes, exact small-N identity ══════
   For N fair coin experiments:
     heads-awakenings = N/2 (approx; exact: heads runs)
     total awakenings = heads + 2*tails = heads + 2*(N-heads) = 2N - heads
   Halfer:  P = heads_runs / N           = 1/2
   Thirder: P = heads_awakenings / wakes = heads / (2N - heads) → 1/3 as N even
   Exact identities checked: 2 * heads_runs = N (for even accounting via
   full sample {H,T}); 3 * heads_awakenings = total_awakenings on {H,T,T}.
*/

run_sleeping_beauty :-
    section('Sleeping Beauty — halfer and thirder identities'),
    % sample space of awakenings with equal weight 1:
    % H contributes one awakening labeled heads; T contributes two labeled tails
    Awakenings = [heads, tails, tails],
    include(=(heads), Awakenings, H), length(H, NH),
    length(Awakenings, NW),
    Experiments = [heads, tails],
    include(=(heads), Experiments, HE), length(HE, NHE),
    length(Experiments, NE),
    format("per-awakening P(heads) = ~w/~w~n", [NH, NW]),
    format("per-experiment P(heads) = ~w/~w~n", [NHE, NE]),
    check('thirder ratio 1/3', NH =:= 1, NW =:= 3),
    check('halfer ratio 1/2', NHE =:= 1, NE =:= 2),
    % identity form matching Rust/Lean spot-check schema
    check('3·heads-awakenings = total awakenings', 3*NH =:= NW),
    check('2·heads-runs = total runs', 2*NHE =:= NE).

/* ═══ Birthday paradox — exact unbounded integer crossing at n=23 ══════════
   P(shared) > 1/2  ⇔  2 · (365 falling n) < 365^n
   SWI integers are unbounded — same evidence Lean kernel / Rust BigNat carry.
*/

falling(N, K, F) :- falling_(N, K, 1, F).
falling_(_, 0, Acc, Acc) :- !.
falling_(N, K, Acc, F) :-
    K > 0, Acc1 is Acc * N, N1 is N - 1, K1 is K - 1,
    falling_(N1, K1, Acc1, F).

pow_int(_, 0, 1) :- !.
pow_int(B, E, P) :-
    E > 0, E1 is E - 1, pow_int(B, E1, P1), P is B * P1.

birthday_crosses(N) :-
    falling(365, N, Fall),
    pow_int(365, N, Pow),
    2 * Fall < Pow.

run_birthday :-
    section('Birthday — exact crossing at n=23 (unbounded ints)'),
    ( birthday_crosses(22) -> C22 = true ; C22 = false ),
    ( birthday_crosses(23) -> C23 = true ; C23 = false ),
    falling(365, 23, F23), pow_int(365, 23, P23),
    format("2·(365↓22) < 365^22 ?  ~w~n", [C22]),
    format("2·(365↓23) < 365^23 ?  ~w~n", [C23]),
    format(codes(DigCodes), "~d", [P23]),
    length(DigCodes, Digs),
    format("365^23 has ~w decimal digits~n", [Digs]),
    check('n=22 does not yet cross 1/2', C22 == false),
    check('n=23 crosses 1/2', C23 == true),
    % quantifier-swap: P(someone shares YOUR day) crosses at 253, not 183
    % 1 - (364/365)^n > 1/2  ⇔  2·364^n < 365^n
    ( self_crosses(252) -> S252 = true ; S252 = false ),
    ( self_crosses(253) -> S253 = true ; S253 = false ),
    format("self-centered cross at 252? ~w  253? ~w~n", [S252, S253]),
    check('self-centered crossing at 253', S252 == false, S253 == true),
    % mutant control: claim "crosses at 22" must be rejected
    check('mutant law (cross at 22) rejected', C22 == false),
    % silence unused
    F23 = F23.

self_crosses(N) :-
    pow_int(364, N, A),
    pow_int(365, N, B),
    2 * A < B.

/* ═══ Simpson — Charig kidney-stone data (exact cross-multiply) ════════════ */

run_simpson :-
    section('Simpson — better in every subgroup, worse overall'),
    % small: A 81/87, B 234/270; large: A 192/263, B 55/80
    check('small: A beats B',  81*270 > 234*87),
    check('large: A beats B',  192*80 > 55*263),
    ATot is 81+192, ADen is 87+263,
    BTot is 234+55, BDen is 270+80,
    check('overall: B beats A', ATot*BDen < BTot*ADen),
    format("small A ~w/~w  B ~w/~w; large A ~w/~w B ~w/~w; ALL A ~w/~w B ~w/~w~n",
           [81,87,234,270,192,263,55,80,ATot,ADen,BTot,BDen]).

/* ═══ Two envelopes — gain-if-smaller + gain-if-larger = 0 (∀ a schema) ═══ */

% If smaller is a and larger 2a: gain-if-you-hold-smaller = +a;
% gain-if-you-hold-larger = -a; sum 0.  Spot-check a range.
envelope_identity(A) :-
    GainSmall is A,          % switch from a to 2a
    GainLarge is A - 2*A,    % switch from 2a to a
    GainSmall + GainLarge =:= 0.

run_envelopes :-
    section('two envelopes — gain identity (spot-checked schema)'),
    findall(A, (between(-1000,1000,A), \+ envelope_identity(A)), Bad),
    check('gain-small + gain-large = 0 on [-1000,1000]', Bad == []),
    format("spot-checked envelope identity on 2001 integers~n", []).

/* ═══ Base-rate ════════════════════════════════════════════════════════════ */

run_base_rate :-
    section('Base-rate fallacy — exact counts per 100_000'),
    % prevalence 1/1000, sens 99%, spec 95% → FP rate 5%
    % per 100000: sick 100, well 99900
    % TP=99, FN=1, FP=4995, TN=94905
    TP=99, FP=4995, Pos is TP+FP,
    check('P(sick|pos) = 99/5094 < 1/50', TP*50 < Pos),
    format("P(sick|positive) = ~w/~w~n", [TP, Pos]).

/* ── entry ───────────────────────────────────────────────────────────────── */

run_04(Result) :-
    clear_fails,
    format("~n══ 04_probability.pl ══~n", []),
    run_monty,
    run_bertrand_box,
    run_boy_girl,
    run_sleeping_beauty,
    run_birthday,
    run_simpson,
    run_envelopes,
    run_base_rate,
    findall(M, fail_msg(M), Fs),
    (   Fs == []
    ->  format("~n04_probability: all checks pass~n", []),
        Result = ok
    ;   format("~n04_probability FAILED: ~w~n", [Fs]),
        Result = fail(Fs)
    ).

:- initialization(main, main).
main :- run_04(R), ( R = ok -> halt(0) ; halt(1) ).
