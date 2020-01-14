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
-import(elevator,[setElevator/0]).
-compile(export_all).

%%call_elevator(ElevatorPID, {CurrentFloor, DesiredFloor}, {MinFloor, MaxFloor}) ->
%%  if CurrentFloor =< MaxFloor and CurrentFloor >= MinFloor and DesiredFloor =< MaxFloor and DesiredFloor >= MinFloor ->
%%    ElevatorPID ! {pedestrian, CurrentFloor, DesiredFloor}
%%  end.





setPassanger() ->
  spawn(fun() -> pedestrian() end).

pedestrian() ->
  receive
    {enter, ElevatorPID} ->
      io:format("Pedestrian with id: ~p enter to elevator with id: ~p", [self(), ElevatorPID]),
      ElevatorPID ! {choose_floor, self(), 7};
    {exit} ->
      io:format("Pedestrian with id: ~p has left the elevator ~n", [self()])
  end.

elevator1({Low, High}, Current_floor, ID, Moving, Direction) ->
  receive
    {pedestrian, PCurrent_Floor, PDesired_Floor} ->
      io:fwrite("Elevator ~p Current floor ~p ~n", [ID, Current_floor]),
      io:fwrite("Pedestrian on flooor ~p wants to floor ~p ~n", [PCurrent_Floor, PDesired_Floor]),
      elevator1({Low, High}, Current_floor, ID, Moving, Direction);
    {status} ->
      io:format("Elevator number: ~p, Current position: ~p ~n", [ID, Current_floor]),
      elevator1({Low, High}, Current_floor, ID, Moving, Direction);
    {move} ->
      if Moving == 1 ->
        io:format("Elevator number: ~p, Moving~n", [ID]),
        elevator1({Low, High}, Current_floor + Direction, ID, Moving, Direction)
      end;
    Other ->
      elevator1({Low, High}, Current_floor, ID, Moving, Direction)
  end.


%%elevator(Moving, Direction, Current_Floor, Next_Floor)

new_elevator({Low, High}, ID) ->
  spawn(fun() -> elevator1({Low, High}, 0, ID, 1, 1) end).

getPID(PIDS, Number) ->
  list_to_pid(lists:flatten(io_lib:format("~p", [lists:nth(Number, PIDS)]))).

getPID(PID) ->
  io_lib:format("~p", PID).

setElevator({Min_Floor, Max_Floor}, 0) ->
  [];

setElevator({Min_Floor, Max_Floor}, N) ->
  PID = new_elevator({Min_Floor, Max_Floor}, N),
  [PID] ++ setElevator({Min_Floor, Max_Floor}, N - 1).

start({MinFloor, MaxFloor}, Number_of_elevators) ->
  setElevator({MinFloor, MaxFloor}, Number_of_elevators).

getStatus([PID]) ->
  PID ! {status};

getStatus([PID | T]) ->
  PID ! {status},
  getStatus(T).

status(PIDs) ->
  getStatus(PIDs).


simulation() ->
  El = setElevator(),
  P1 = setPassanger(),
  P2 = setPassanger(),
  P3 = setPassanger(),
  P4 = setPassanger(),
  El ! {status},
  El ! {choose_floor, P1, 6},
  El ! {choose_floor, P2, 4},
  El ! {choose_floor, P3, 4},
  El ! {choose_floor, P4, 4},
  El ! {status},
  El ! {move},
  El ! {status},
  El ! {move},
  El ! {status}.
