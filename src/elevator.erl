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

-compile(export_all).

setElevator() ->
  spawn(fun() -> elevator(1, {1, 6}, 3, 1, [], []) end).

elevator(ID, {Low, High}, Current_floor, Moving, On_board, Waiting) ->

  receive

    {call_elevator, Pedestrian_ID, Pedestrian_floor} ->
      io:format("Passenger with id ~p has called the elevator ~n", [Pedestrian_ID]),
      W = Waiting ++ [{Pedestrian_ID, Pedestrian_floor}],
      elevator(ID, {Low, High}, Current_floor, Moving, On_board, W);

    {status} ->
      io:format(
        "==================STATUS====================
  Elevator number: ~p, Current position: ~p
  Passengers on board: ~p
  ============================================ ~n", [ID, Current_floor, On_board]),
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

    {next_turn} ->
      io:format("Elevator ~p moving ~p, current floor ~p
      On board: ~p Waiting: ~p ~n", [ID, if Moving == 1 -> "TOP"; Moving == -1 -> "DOWN"; true -> "STOP"
                                                         end, Current_floor, On_board, Waiting]),
      {LeftOnBoard, LeftWaiting} = update_passangers(self(), Current_floor, On_board, Waiting, {Low, High}),
      OnBoardLength = length(LeftOnBoard),
      Waiting_Length = length(LeftWaiting),
      if
        OnBoardLength > 0 ->
          ArePeople = are_people_who_want_to_next_floors(On_board, Current_floor, Moving),
          if
            ArePeople == 1 ->
              elevator(ID, {Low, High}, Current_floor + Moving, Moving, LeftOnBoard, LeftWaiting);
            ArePeople == 0 ->
              elevator(ID, {Low, High}, Current_floor - Moving, - Moving, LeftOnBoard, LeftWaiting)
          end;
        OnBoardLength == 0 ->
          if
            Waiting_Length > 0 ->
              Direction = setDirection(lists:nth(1, LeftWaiting), Current_floor),
              elevator(ID, {Low, High}, Current_floor + Direction, Direction, LeftOnBoard, LeftWaiting);
            Waiting_Length == 0 ->
              elevator(ID, {Low, High}, Current_floor, 0, LeftOnBoard, LeftWaiting)
          end
      end
  end.


setDirection({Passanger, Floor}, CurrentFloor) ->
  if
    Floor > CurrentFloor ->
      1;
    Floor < CurrentFloor ->
      -1
  end.

%%  Return 1 if there are people on board who want to next floor
%%  Return 0 if there is empty elevator, or every passanger wants to floor in other direction
%%
%%
are_people_who_want_to_next_floors([{PassangerId, Floor}], CurrentFloor, Moving) ->
  if
    Moving == 1 ->
      if
        Floor > CurrentFloor -> 1;
        true -> 0
      end;
    Moving == -1 ->
      if
        Floor < CurrentFloor -> 1;
        true -> 0
      end;
    Moving == 0 ->
      1
  end;

are_people_who_want_to_next_floors([{PassangerId, Floor} | T], CurrentFloor, Moving) ->
  if
    Moving == 1 ->
      if
        Floor > CurrentFloor -> 1;
        true -> are_people_who_want_to_next_floors(T, CurrentFloor, Moving)
      end;
    Moving == -1 ->
      if
        Floor < CurrentFloor -> 1;
        true -> are_people_who_want_to_next_floors(T, CurrentFloor, Moving)
      end;
    Moving == 0 ->
      1
  end.


get_passengers_on_this_floor(ElevatorPID, [], Floor, {Min, Max}) ->
  [];

get_passengers_on_this_floor(ElevatorPID, Waiting, Floor, {Min, Max}) ->
  PIDS = onFloor(Waiting, Floor),
  call_passengers(ElevatorPID, PIDS, {Min, Max}),
  delete_passangers(PIDS, Floor, Waiting).

call_passengers(ElevatorPID, [], {Min, Max}) ->
  [];

call_passengers(ElevatorPID, [WaitingPid | T], {Min, Max}) ->
  WaitingPid ! {enter, ElevatorPID, {Min, Max}},
  call_passengers(ElevatorPID, T, {Min, Max}).

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

call_passangers_exit([]) ->
  ok;

call_passangers_exit([Pid | T]) ->
  io:format("Passanger with ~p called to leave ~n", [Pid]),
  call_passanger_to_exit(Pid),
  call_passangers_exit(T).

enter_waiting_passengers(ElevatorPid, [], {Min, Max}) ->
  [];

enter_waiting_passengers(ElevatorPid, [PID | T], {Min, Max}) ->
  PID ! {enter, ElevatorPid, {Min, Max}},
  enter_waiting_passengers(ElevatorPid, T, {Min, Max}).

delete_passangers([], Floor, PIDS) ->
  PIDS;

delete_passangers([PID | T], Floor, PIDS) ->
  NewPids = PIDS -- [{PID, Floor}],
  delete_passangers(T, Floor, NewPids).

update_passangers(ElevatorPID, CurrentFloor, OnBoard, Waiting, {Min, Max}) ->
  WaitingOnThisFloor = onFloor(Waiting, CurrentFloor),
  enter_waiting_passengers(ElevatorPID, WaitingOnThisFloor, {Min, Max}),
  LeftWaiting = delete_passangers(WaitingOnThisFloor, CurrentFloor, Waiting),

  PeopleWhoWantToLeave = onFloor(OnBoard, CurrentFloor),
  call_passangers_exit(PeopleWhoWantToLeave),
  LeftOnBoard = delete_passangers(PeopleWhoWantToLeave, CurrentFloor, OnBoard),
  {LeftOnBoard, LeftWaiting}.