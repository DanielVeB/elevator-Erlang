%%%-------------------------------------------------------------------
%%% @author daniel
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. sty 2020 01:26
%%%-------------------------------------------------------------------
-module(elevator).
-author("daniel").

%% API

-export([setElevator/0]).

setElevator() ->
  spawn(fun() -> elevator(1, {1, 6}, 3, 1, [], []) end).

elevator(ID, {Low, High}, Current_floor, Moving, On_board, Waiting) ->

  receive

    {call_elevator, Pedestrian_ID, Pedestrian_floor} ->
      elevator(ID, {Low, High}, Current_floor, Moving, On_board, Waiting ++ [{Pedestrian_ID, Pedestrian_floor}]);

    {status} ->
      io:format("==================STATUS==================== ~n"),
      io:format("Elevator number: ~p, Current position: ~p ~n", [ID, Current_floor]),
      io:format("Passengers on board: ~p ~n ", [On_board]),
      io:format("============================================ ~n"),
      elevator(ID, {Low, High}, Current_floor, Moving, On_board, Waiting);

    {choose_floor, Pedestrian_ID, Desired_floor} ->
      if
        Current_floor == Desired_floor ->
          Pedestrian_ID ! {exit},
          elevator(ID, {Low, High}, Current_floor, Moving, On_board, Waiting);
        true ->
          io:format("Elevator ~p, get new passenger on board ~n", [ID]),
          elevator(ID, {Low, High}, Current_floor, Moving, On_board ++ [{Pedestrian_ID, Desired_floor}], Waiting)
      end;
    {move} ->
      if (Current_floor + Moving) > High ->
        io:format("Elevator ~p stopped, top floor : ~p ~n", [ID, High]),
        elevator(ID, {Low, High}, Current_floor, 0, On_board, Waiting);
        (Current_floor + Moving) < Low ->
          io:format("Elevator ~p stopped, lowest floor : ~p ~n", [ID, Low]),
          elevator(ID, {Low, High}, Low, 0, On_board, Waiting);
        true ->
          if Moving == 0 ->
            io:format("Elevator ~p stopped, lowest floor : ~p ~n", [ID, Low]);
            true ->
              io:format("Elevator ~p moving ~n", [ID]),
              Pedestrians_On_Floor = onFloor(On_board, Current_floor),
              Length = length(Pedestrians_On_Floor),
              if
                Length > 0 ->
                  call_passangers_exit(Pedestrians_On_Floor),
                  P = delete_passangers(Pedestrians_On_Floor, Current_floor, On_board),
                  elevator(ID, {Low, High}, Current_floor + Moving, Moving, P, Waiting);
                Length == 0 ->
                  elevator(ID, {Low, High}, Current_floor + Moving, Moving, On_board, Waiting)
              end
          end

      end

  end.


onFloor([], CurrentFloor) ->
  [];

onFloor([{PassangerPID, Floor} | T], CurrentFloor) ->
  if Floor == CurrentFloor ->
    P = onFloor(T, CurrentFloor),
    [PassangerPID] ++ P;
    true ->
      [] ++ onFloor(T, CurrentFloor)
  end.


call_passanger_to_exit(PID) ->
  PID ! {exit}.

call_passangers_exit([Pid]) ->
  io:format("Passanger with ~p called to leave ~n", [Pid]),
  call_passanger_to_exit(Pid);

call_passangers_exit([Pid | T]) ->
  io:format("Passanger with ~p called to leave ~n", [Pid]),
  call_passanger_to_exit(Pid),
  call_passangers_exit(T).

delete_passangers([PID], Floor, PIDS) ->
  PIDS -- [{PID, Floor}];

delete_passangers([PID | T], Floor, PIDS) ->
  NewPids = PIDS -- [{PID, Floor}],
  delete_passangers(T, Floor, NewPids).