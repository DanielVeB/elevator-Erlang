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
-compile(export_all).

%%call_elevator(ElevatorPID, {CurrentFloor, DesiredFloor}, {MinFloor, MaxFloor}) ->
%%  if CurrentFloor =< MaxFloor and CurrentFloor >= MinFloor and DesiredFloor =< MaxFloor and DesiredFloor >= MinFloor ->
%%    ElevatorPID ! {pedestrian, CurrentFloor, DesiredFloor}
%%  end.



setElevator() ->
  spawn(fun() -> elevator(1, {1, 6}, 3, 1, [], []) end).

setPassanger() ->
  spawn(fun() -> pedestrian() end).


elevator(ID, {Low, High}, Current_floor, Moving, On_board, Waiting) ->

  receive

    {call_elevator, Pedestrian_ID, Pedestrian_floor} ->
      elevator(ID,{Low, High}, Current_floor, Moving, On_board, Waiting ++ [{Pedestrian_ID, Pedestrian_floor}]);

    {status} ->
      io:format("Elevator number: ~p, Current position: ~p ~n",[ID, Current_floor]),
      io:format("Passengers on board: ~p ~n ", [On_board] ),
      elevator(ID,{Low, High}, Current_floor, Moving, On_board, Waiting);

    {choose_floor, Pedestrian_ID, Desired_floor} ->
      if
        Current_floor == Desired_floor ->
            Pedestrian_ID ! {exit};
        true ->
            io:format("Elevator ~p, get new passenger on board ~n", [ID]),
            elevator(ID,{Low, High}, Current_floor, Moving, On_board ++ [{Pedestrian_ID, Desired_floor}], Waiting)
      end;
    {move} ->
      if (Current_floor + Moving) > High ->
          io:format("Elevator ~p stopped, top floor : ~p ~n", [ID, High]),
          elevator(ID,{Low, High}, Current_floor , 0, On_board, Waiting);
        (Current_floor + Moving) < Low ->
          io:format("Elevator ~p stopped, lowest floor : ~p ~n", [ID, Low]),
          elevator(ID,{Low, High}, Low , 0, On_board, Waiting);
        true ->
          if Moving == 0 ->
            io:format("Elevator ~p stopped, lowest floor : ~p ~n", [ID, Low]);
            true ->
              Pedestrians_On_Floor = isOnFloor(On_board, Current_floor),
              if length(Pedestrians_On_Floor) > 0 ->
                call_passangers_exit(Pedestrians_On_Floor),
                delete_passangers(Pedestrians_On_Floor, Current_floor, On_board)
              end
          end

      end

  end.


call_passanger_to_exit(PID) ->
  PID ! {exit}.

call_passangers_exit([Pid]) ->
  call_passanger_to_exit(Pid);

call_passangers_exit([Pid | T]) ->
  call_passanger_to_exit(Pid),
  call_passangers_exit(T).

delete_passangers([PID], Floor, PIDS) ->
  PIDS -- [{PID, Floor}];

delete_passangers([PID|T],Floor, PIDS) ->
  NewPids = PIDS -- [{PID, Floor}],
  delete_passangers(T, Floor, NewPids).

isOnFloor([], CurrentFloor) ->
  [];

isOnFloor([{PassangerPID, Floor} | T], CurrentFloor) ->

  if Floor == CurrentFloor ->
    [PassangerPID] ++ isOnFloor(T, CurrentFloor);
    true ->
      [] ++ isOnFloor(T, CurrentFloor)
  end.

pedestrian() ->
  receive
    {enter, ElevatorPID} ->
      io:format("Pedestrian with id: ~p enter to elevator with id: ~p", [self(),ElevatorPID]),
      ElevatorPID ! {choose_floor, self(), 7};
    {exit} ->
      io:format("Pedestrian with id: ~p has left the elevator ~n", [self()])
  end.

elevator1({Low,High}, Current_floor, ID, Moving, Direction) ->
  receive
    {pedestrian, PCurrent_Floor, PDesired_Floor} ->
      io:fwrite("Elevator ~p Current floor ~p ~n", [ID, Current_floor]),
      io:fwrite("Pedestrian on flooor ~p wants to floor ~p ~n", [PCurrent_Floor, PDesired_Floor]),
      elevator1({Low,High}, Current_floor,ID, Moving,Direction);
    {status} ->
      io:format("Elevator number: ~p, Current position: ~p ~n",[ID, Current_floor]),
      elevator1({Low,High}, Current_floor,ID, Moving,Direction);
    {move} ->
      if Moving == 1 ->
        io:format("Elevator number: ~p, Moving~n",[ID]),
        elevator1({Low,High}, Current_floor + Direction,ID, Moving,Direction)
      end;
    Other ->
      elevator1({Low,High}, Current_floor,ID, Moving,Direction)
  end.


%%elevator(Moving, Direction, Current_Floor, Next_Floor)

new_elevator({Low, High}, ID) ->
  spawn(fun() -> elevator1({Low, High}, 0, ID, 1 ,1 ) end).

getPID(PIDS, Number) ->
  list_to_pid(lists:flatten(io_lib:format("~p",[lists:nth(Number, PIDS)]))).

setElevator({Min_Floor, Max_Floor}, 0) ->
  [];

setElevator({Min_Floor, Max_Floor}, N) ->
  PID = new_elevator({Min_Floor, Max_Floor}, N),
  [PID] ++ setElevator({Min_Floor, Max_Floor}, N -1 ).

start({MinFloor, MaxFloor}, Number_of_elevators) ->
  setElevator({MinFloor, MaxFloor}, Number_of_elevators).

getStatus([]) ->
  io:write("Status end ~n");

getStatus([PID|T]) ->
  PID! {status},
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
  El ! {status}.
