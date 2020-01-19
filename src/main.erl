%%%-------------------------------------------------------------------
%%% @author daniel
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. gru 2019 23:26
%%%-------------------------------------------------------------------
-module(main).
-author("daniel").

%% API
-import(elevator,[setElevator/0, elevator/6]).
-compile(export_all).

setPassanger() ->
  spawn(fun() -> pedestrian() end).

pedestrian() ->
  receive
    {enter, ElevatorPID, {Min, Max}} ->
      io:format("Passenger with id: ~p has entered to elevator ~n", [self()]),
      ElevatorPID ! {choose_floor, self(), rand:uniform(Max - Min) + Min},
      pedestrian();
    {exit} ->
      io:format("Passenger with id: ~p has left the elevator ~n", [self()])
  end.


getPID(PIDS, Number) ->
  list_to_pid(lists:flatten(io_lib:format("~p", [lists:nth(Number, PIDS)]))).

getPID(PID) ->
  io_lib:format("~p", PID).

getStatus([]) ->
  ok;

getStatus([PID | T]) ->
%%  PID ! {status},
  PID ! {next_turn},
  getStatus(T).

status(PIDs) ->
  getStatus(PIDs).


new_elevator({Min_Floor, Max_Floor}, N) ->
  Init_Floor = rand:uniform(Max_Floor - Min_Floor) + Min_Floor,
  spawn(fun() -> elevator(N, {Min_Floor, Max_Floor}, Init_Floor, 0, [], []) end).

setElevator({Min_Floor, Max_Floor}, 0) ->
  [];

setElevator({Min_Floor, Max_Floor}, N) ->
  PID = new_elevator({Min_Floor, Max_Floor}, N),
  [PID] ++ setElevator({Min_Floor, Max_Floor}, N - 1).

sim({Min, Max}, N) ->
  PIDS = setElevator({Min,Max}, N),
  register_passengers(PIDS, {Min, Max}, N).

sim1() ->
  sim({0,10},1).


register_passengers(PIDS, {Min, Max}, N) ->
  ElPID = lists:nth(rand:uniform(N), PIDS),
  Passenger = setPassanger(),
  ElPID ! {call_elevator, Passenger, rand:uniform(Max - Min) + Min},
  timer:sleep(5000),
  getStatus(PIDS),
  register_passengers(PIDS, {Min, Max}, N ).



