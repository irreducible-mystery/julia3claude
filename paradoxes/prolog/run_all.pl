/* Run every paradox file in order.
 *
 *   swipl -q -t halt -s paradoxes/prolog/run_all.pl
 *   ./paradoxes/prolog/run_all.sh
 *
 * Exit 0 only if every module's failure channel is clean.
 */
:- use_module(library(process)).
:- use_module(library(lists)).
:- use_module(library(readutil)).
:- set_prolog_flag(verbose, silent).

files([
    '01_liar_and_friends.pl',
    '04_probability.pl',
    '05_decision.pl',
    '08_tensions.pl',
    '10_prolog_expressibility.pl'
]).

here(Dir) :-
    source_file(here(_), File), !,
    file_directory_name(File, Dir).
here(Dir) :-
    prolog_load_context(directory, Dir).

run_file(Dir, File, Exit) :-
    format("~n~`═t~70|~n  ~w~n~`═t~70|~n", [File]),
    atomic_list_concat([Dir, '/', File], Path),
    current_prolog_flag(executable, Exec),
    process_create(Exec,
        ['-q', '-t', 'halt', '-s', Path],
        [process(PID), stdout(pipe(Out)), stderr(pipe(Err)), cwd(Dir)]),
    read_stream_to_codes(Out, OutC),
    read_stream_to_codes(Err, ErrC),
    close(Out), close(Err),
    process_wait(PID, Status),
    ( OutC == [] -> true ; format("~s", [OutC]) ),
    ( ErrC == [] -> true ; format("~s", [ErrC]) ),
    ( Status = exit(E) -> Exit = E ; Exit = 99 ).

main :-
    format("PARADOXES — Prolog suite (SWI-Prolog)~n", []),
    here(Dir),
    files(Fs),
    run_all(Dir, Fs, 0, NFail),
    nl,
    (   NFail =:= 0
    ->  format("══ ALL PROLOG MODULES GREEN ══~n", []),
        halt(0)
    ;   format("══ ~w MODULE(S) RED ══~n", [NFail]),
        halt(1)
    ).

run_all(_, [], N, N).
run_all(Dir, [F|Fs], Acc, N) :-
    run_file(Dir, F, Exit),
    (   Exit =:= 0
    ->  Acc1 = Acc
    ;   Acc1 is Acc + 1,
        format("** module exit ~w **~n", [Exit])
    ),
    run_all(Dir, Fs, Acc1, N).

:- initialization(main, main).
