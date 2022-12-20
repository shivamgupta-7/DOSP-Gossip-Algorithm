



%Module Definition for the project
-module(project2).

%All the functions are exported at once instead of calling them individually
-compile(export_all).

% %-export([
%     start/3, 
%     server/4, 
%     for/11,
%     last/1, 
%     random3d/3,
%     assign/3,
%     setup3d/3,
%     up/2,
%     down/2,
%     setup2d/3,
%     east/3,
%     west/3,
%     north/3,
%     south/3,
%     pish_sym/2, 
%     random_loop/3 
%     gossip/2, 
% ]).

% This function starts the program and takes the dynamic input for the user in umber of Nodes
% Topology and Algorithm
start(Num, Topology, Algorithm) ->


% If the Topology is 2D Grid or Imperfect 3D it sets up the grid which is composed of
% Planesize only for 2d as it takes Square Root of the input to create the Grid
    if
        Topology == twodgrid ->
            PlaneSize = Num,
            RowSize = trunc(math:sqrt(PlaneSize)),
            persistent_term:put(plane, PlaneSize),
            persistent_term:put(row, RowSize);

% The imperfect 3D grid Needs to be setup here since Erlanf Language does not have a 
% Cube Root Function that would have helped in setting up the structure
        Topology == impthreed ->
            PlaneSize = 4,
            RowSize = 2,
            persistent_term:put(plane, PlaneSize),
            persistent_term:put(row, RowSize);
        true ->
            ok
    end,

%     Node_list = Set up a list of nodes to be for nodes that are created with PID and stores in the location
%     Neighbor_Map = Map for the neighbours that are available to a node for sending rumours
%     Node_map = Map of the Nodes with value associated with the Node
%     Rumour_map = Map Data Structure to keep a count of rumours and which node has heard the rumour how many times
%     Fin_List = List of the nodes whose function is finished or have heard the rumour 10 times
%     Weights_map = For Push Sum Algorithm for the Weights associated with particular nodes
%     Index_map = Index of a particular node needed for 2d and imperfect3d grid
%     Int Integer for count for push sum algorithm
%     All the variables go on to make a persistent term which is Erlang's Version 
%     of a global variable accessible across the program 

    Node_list = [],
    Neighbor_Map = #{},
    Node_map = #{},
    Rumour_map = #{},
    Fin_List = [],
    Weights_map = #{},
    Index_map = #{},
    Int =0,
    persistent_term:put(en,Int),
    persistent_term:put(map, Node_map),
    persistent_term:put(list, Node_list),
    persistent_term:put(rmap, Rumour_map),
    persistent_term:put(fin, Fin_List),
    persistent_term:put(neighbor, Neighbor_Map),
    persistent_term:put(weights, Weights_map),
    persistent_term:put(index, Index_map),

%   Actors are spawned according to the requirement s of the project and achieve concurrency
%   and distributed programming.
    register(sid, spawn(project2, send_self, [])),
    register(mid, spawn(project2, server, [Num, Topology, Algorithm, Num])),
    % Full - 10,
    % Line - 10,
    % 2D - 9,
    % 3D - 8 (if you want it quicker)
    register(lastid, spawn(project2, last, [Num])).



%   Server or Master Function for allocation of resources and supervision
server(Num, Topology, Algorithm, Limit) ->

    Node_list = persistent_term:get(list),
    Node_map = persistent_term:get(map),
    Rumour_map = persistent_term:get(map),
    Weights_map = persistent_term:get(weights),
    Neighbor_map = persistent_term:get(neighbor),
    Index_map = persistent_term:get(index),

%   Statistics Function to calculate the runtime and ratio [CPU:Real Time]
    statistics(runtime),
    statistics(wall_clock),


    for(
        Num,
        Node_list,
        Node_map,
        Rumour_map,
        Weights_map,
        Neighbor_map,
        Index_map,
        Algorithm,
        Limit,
        1,
        Topology
    ),

%   Different Topologies require access to different resources and allocated by the master
    if
        Topology == full ->
            receive
                {_Pid, Msg} ->
                    if
                        Msg == finished ->
                            io:format("Wieghts: ~p~n", [persistent_term:get(weights)]),
                            L = persistent_term:get(list),
                            [Head | _Tail] = L,
                            Head ! {self(), initial};
                        true ->
                            ok
                    end
            end;


        Topology == line ->
            receive
                {_Pid, Msg} ->
                    if
                        Msg == finished ->
                            NL = persistent_term:get(list),
                            NM = persistent_term:get(neighbor),
                            create_neighbors(NL, NM, 1),
                            receive
                                {_Message} ->
                                    NM2 = persistent_term:get(neighbor),
                                    io:format("Neighbors: ~p~n", [NM2]),
                                    L = persistent_term:get(list),
                                    [Head | _Tail] = L,
                                    Head ! {self(), initial}
                            end;
                        true ->
                            ok
                    end
            end;


        Topology == twodgrid ->
            receive
                {_Pid, Msg} ->
                    if
                        Msg == finished ->
                            setup2d(Num, 1, Limit),
                            receive
                                {_Message} ->
                                    NM2 = persistent_term:get(neighbor),
                                    io:format("Neighbors: ~p~n", [NM2]),
                                    L = persistent_term:get(list),
                                    [Head | _Tail] = L,
                                    Head ! {self(), initial}
                            end;
                        true ->
                            ok
                    end
            end;


        Topology == impthreed ->
            receive
                {_Pid, Msg} ->
                    if
                        Msg == finished ->
                            setup2d(Num, 1, Limit),
                            receive
                                {_Message} ->
                                    setup3d(Num, 1, Limit),
                                    receive
                                        {_Msg} ->
                                            assign(Num, 1, Limit),
                                            receive
                                                {_Msg2} ->
                                                    NM2 = persistent_term:get(neighbor),
                                                    io:format("Neighbors: ~p~n", [NM2]),
                                                    L = persistent_term:get(list),
                                                    [Head | _Tail] = L,
                                                    Head ! {self(), initial}
                                            end
                                    end
                            end;
                        true ->
                            ok
                    end
            end;
        true ->
            ok
    end.

% For loop for Running the program till all the nodes have hear the rumour multiple times
for(
    0,
    Node_list,
    Node_map,
    Rumour_map,
    Weights_map,
    Neighbor_map,
    Index_map,
    _Algorithm,
    _Limit,
    _Index,
    _Topology
) ->
    persistent_term:put(map, Node_map),
    persistent_term:put(list, Node_list),
    persistent_term:put(rmap, Rumour_map),
    persistent_term:put(weights, Weights_map),
    persistent_term:put(neighbor, Neighbor_map),
    persistent_term:put(index, Index_map),
    mid ! {self(), finished},
    ok;


for(
    N,
    Node_list,
    Node_map,
    Rumour_map,
    Weights_map,
    Neighbor_map,
    Index_map,
    Algorithm,
    Limit,
    Index,
    Topology
) ->
    Pid = spawn(project2, Algorithm, [Topology, Limit]),
    L = [Pid],
    M = #{Pid => 0},
    R = #{Pid => false},
    W = #{Pid => {Index, 1}},
    NM = #{Pid => []},
    I = #{Pid => Index},
    New_list = L ++ Node_list,
    New_map = maps:merge(M, Node_map),
    RNew_map = maps:merge(R, Rumour_map),
    WNew_map = maps:merge(W, Weights_map),
    NNew_map = maps:merge(NM, Neighbor_map),
    INew_map = maps:merge(I, Index_map),
    persistent_term:put(map, New_map),
    persistent_term:put(rmap, RNew_map),
    persistent_term:put(list, New_list),
    persistent_term:put(weights, WNew_map),
    persistent_term:put(index, INew_map),
    persistent_term:put(neighbor, WNew_map),

    for(
        N - 1,
        New_list,
        New_map,
        RNew_map,
        WNew_map,
        NNew_map,
        INew_map,
        Algorithm,
        Limit,
        Index + 1,
        Topology
    ).

% Send Self Function to assure that all the nodes randomly picked remain open to receiving Rumours
send_self() ->
    receive
        {From, _Msg} ->
            From ! {self()}
    end,
    send_self().

%-----Function to determine the statistics at the Program End-----
last(Num) ->
    Int = persistent_term:get(en),
    if Int ==Num ->
        {_, Time1} = statistics(runtime),
    {_, Time2} = statistics(wall_clock),
    U1 = Time1 * 1000,
    U2 = Time2 * 1000,
    io:format(
        "Code time=~p (~p) microseconds~n",
        [U1, U2]
    );
    %io:format("Ratio [CPU Time:Real Time]= ~p ~n",[U1/U2]);
true ->
    ok
end,
    receive
        {programend} ->
            Mega_map = persistent_term:get(map),
            Nint = Int+1,
            persistent_term:put(en,Nint),
            io:format("Map: ~p~n", [Mega_map])
    end,
    last(Num).

% This Function is used for selelcting a random node among the list neighbours in a imperfect 3D grid
random3d(Pid, Node_list, Neighbors) ->
    Random_node = lists:nth(rand:uniform(length(Node_list)), Node_list),
    Bool = lists:member(Random_node, Neighbors),
    if
        Random_node == Pid ->
            random3d(Pid, Node_list, Neighbors);
        Bool == true ->
            random3d(Pid, Node_list, Neighbors);
        true ->
            Random_node
    end.


assign(0, _Idx, _Limit) ->
    mid ! {"done2"},
    ok;


assign(Num, Index, Limit) ->
    Node_list = persistent_term:get(list),
    Pid = lists:nth(Index, Node_list),
    Neighbor_Map = persistent_term:get(neighbor),
    Neighbors = maps:get(Pid, Neighbor_Map),

    Random_node = random3d(Pid, Node_list, Neighbors),
    N = lists:append(Neighbors, [Random_node]),
    Neighbor_map2 = maps:update(Pid, N, Neighbor_Map),
    persistent_term:put(neighbor, Neighbor_map2),
    if
        Index == Limit ->
            Idx = Limit + 1,
            assign(Num - 1, Idx, Limit);
        true ->
            assign(Num - 1, Index + 1, Limit)
    end.

setup3d(0, _Idx, _Limit) ->
    mid ! {"done"},
    ok;

setup3d(Num, Index, Limit) ->
    Node_list = persistent_term:get(list),
    Pid = lists:nth(Index, Node_list),

    Size = length(Node_list),

    PlaneSize = persistent_term:get(plane),
    RowSize = persistent_term:get(row),

    Calc = PlaneSize * (RowSize - 1),

    if
        Index > 0 andalso Index =< PlaneSize ->
            Down = down(Index, PlaneSize),
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbors = maps:get(Pid, Neighbor_Map),
            DownNeighbor = lists:nth(Down, Node_list),
            N = lists:append(Neighbors, [DownNeighbor]),
            Neighbor_map2 = maps:update(Pid, N, Neighbor_Map),
            persistent_term:put(neighbor, Neighbor_map2);
        Index > Calc andalso Index =< Size ->
            Up = up(Index, PlaneSize),
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbors = maps:get(Pid, Neighbor_Map),
            UpNeighbor = lists:nth(Up, Node_list),
            N = lists:append(Neighbors, [UpNeighbor]),
            Neighbor_map2 = maps:update(Pid, N, Neighbor_Map),
            persistent_term:put(neighbor, Neighbor_map2);
        true ->
            Down = down(Index, PlaneSize),
            Up = up(Index, PlaneSize),
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbors = maps:get(Pid, Neighbor_Map),
            UpNeighbor = lists:nth(Up, Node_list),
            DownNeighbor = lists:nth(Down, Node_list),
            N = lists:append(Neighbors, [DownNeighbor]),
            N2 = lists:append(N, [UpNeighbor]),
            Neighbor_map2 = maps:update(Pid, N2, Neighbor_Map),
            persistent_term:put(neighbor, Neighbor_map2)
    end,
    if
        Index == Limit ->
            Idx = Limit + 1,
            setup3d(Num - 1, Idx, Limit);
        true ->
            setup3d(Num - 1, Index + 1, Limit)
    end.

up(Index, PlaneSize) ->
    Val = Index - PlaneSize,
    Val.

down(Index, PlaneSize) ->
    Val = Index + PlaneSize,
    Val.

setup2d(0, _Idx, _Limit) ->
    mid ! {"done"},
    ok;
setup2d(Num, Index, Limit) ->
    Node_list = persistent_term:get(list),
    Pid = lists:nth(Index, Node_list),

    PlaneSize = persistent_term:get(plane),
    RowSize = persistent_term:get(row),

    East = east(Index, RowSize),
    West = west(Index, RowSize),
    North = north(Index, RowSize, PlaneSize),
    South = south(Index, RowSize, PlaneSize),

    if
        East /= -1 ->
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbors = maps:get(Pid, Neighbor_Map),
            EastNeighbor = lists:nth(East, Node_list),
            N = lists:append(Neighbors, [EastNeighbor]),
            Neighbor_map2 = maps:update(Pid, N, Neighbor_Map),
            persistent_term:put(neighbor, Neighbor_map2);
        true ->
            ok
    end,

    if
        West /= -1 ->
            Neighbor_Map5 = persistent_term:get(neighbor),
            Neighbors5 = maps:get(Pid, Neighbor_Map5),
            WestNeighbor = lists:nth(West, Node_list),
            N5 = lists:append(Neighbors5, [WestNeighbor]),
            Neighbor_map25 = maps:update(Pid, N5, Neighbor_Map5),
            persistent_term:put(neighbor, Neighbor_map25);
        true ->
            ok
    end,

    if
        North /= -1 ->
            Neighbor_Map3 = persistent_term:get(neighbor),
            Neighbors3 = maps:get(Pid, Neighbor_Map3),
            NorthNeighbor = lists:nth(North, Node_list),
            N3 = lists:append(Neighbors3, [NorthNeighbor]),
            Neighbor_map23 = maps:update(Pid, N3, Neighbor_Map3),
            persistent_term:put(neighbor, Neighbor_map23);
        true ->
            ok
    end,

    if
        South /= -1 ->
            Neighbor_Map4 = persistent_term:get(neighbor),
            Neighbors4 = maps:get(Pid, Neighbor_Map4),
            SouthNeighbor = lists:nth(South, Node_list),
            N4 = lists:append(Neighbors4, [SouthNeighbor]),
            Neighbor_map24 = maps:update(Pid, N4, Neighbor_Map4),
            persistent_term:put(neighbor, Neighbor_map24);
        true ->
            ok
    end,
   
            setup2d(Num - 1, Index + 1, Limit).
 

east(Index, RowSize) ->
    Mod = math:fmod(Index, RowSize),
    if
        Mod == 0 ->
            -1;
        true ->
            Index + 1
    end.

west(Index, RowSize) ->
    Mod = math:fmod(Index, RowSize),
    if
        Mod == 1 ->
            -1;
        true ->
            Index - 1
    end.

north(Index, RowSize, PlaneSize) ->
    Mod = math:fmod(Index, PlaneSize),
    if
        Mod >= 1 andalso Mod =< RowSize ->
            -1;
        true ->
            Index - RowSize
    end.

south(Index, RowSize, PlaneSize) ->
    Mod = math:fmod(Index, PlaneSize),
    Size = PlaneSize - RowSize + 1,
    if
        Mod >= Size andalso Mod =< PlaneSize ->
            -1;
        Mod == 0 ->
            -1;
        true ->
            Index + RowSize
    end.


create_neighbors(Node_list, Neighbor_Map, 11) ->
    persistent_term:put(neighbor, Neighbor_Map),
    persistent_term:put(list, Node_list),
    mid ! {neighbors_finished},
    ok;

create_neighbors(Node_list, Neighbor_Map, Index) ->
    if
        Index == 1 ->
            Key = lists:nth(Index, Node_list),
            Neighbor_List = maps:get(Key, Neighbor_Map),
            X = lists:nth(Index + 1, Node_list),
            L = [X],
            N_List = Neighbor_List ++ L,
            NM = maps:update(Key, N_List, Neighbor_Map),
            persistent_term:put(neighbor, NM);

        Index == length(Node_list) ->
            Key = lists:nth(Index, Node_list),
            Neighbor_List = maps:get(Key, Neighbor_Map),
            X = lists:nth(Index - 1, Node_list),
            L = [X],
            N_List = Neighbor_List ++ L,
            NM = maps:update(Key, N_List, Neighbor_Map),
            persistent_term:put(neighbor, NM);

        true ->
            Key = lists:nth(Index, Node_list),
            Neighbor_List = maps:get(Key, Neighbor_Map),
            X1 = lists:nth(Index + 1, Node_list),
            X2 = lists:nth(Index - 1, Node_list),
            L = [X1] ++ [X2],
            N_List = Neighbor_List ++ L,
            NM = maps:update(Key, N_List, Neighbor_Map),
            persistent_term:put(neighbor, NM)
    end,

    N_Map = persistent_term:get(neighbor),
    Node_L = persistent_term:get(list),
    create_neighbors(Node_L, N_Map, Index + 1).

random_loop(Node_id, Node_list, Topology) ->

    if
        Topology == full ->
            Random_node = lists:nth(rand:uniform(length(Node_list)), Node_list),
            if
                Random_node == Node_id ->
                    random_loop(Node_id, Node_list, Topology);
                true ->
                    Random_node
            end;

        Topology == line orelse Topology == twodgrid orelse Topology == impthreed ->
            Neighbor_Map = persistent_term:get(neighbor),
            Neighbor_List = maps:get(Node_id, Neighbor_Map),
            Random_node = lists:nth(rand:uniform(length(Neighbor_List)), Neighbor_List),
            if
                Random_node == Node_id ->
                    random_loop(Node_id, Node_list, Topology);
                true ->
                    Random_node
            end;
        true ->
            ok
    end.


gossip(Topology, Limit) ->
    %Checks if finished_list has all the 10 elements
    Fin_List = persistent_term:get(fin),
    L1 = persistent_term:get(list),
    RMap = persistent_term:get(rmap),
    io:fwrite("~p~n", [Fin_List]),
    Bool = maps:find(self(), RMap),
    Check = lists:member(self(), Fin_List),

    if
        Bool == {ok, true} ->
            % io:fwrite("~p",[Check]),
            if
                Check == false ->
                    LL = persistent_term:get(list),
                    Rand = random_loop(self(), LL, Topology),
                    Rand ! {self(), "rumour"};
                true ->
                    ok
            end;
        true ->
            ok
    end,

    sid ! {self(), "self"},
    receive
        {_Mid, _Msg, initial} ->
            Map = persistent_term:get(map),
            {ok, Val} = maps:find(self(), Map),
            NVal = Val + 1,
            M = maps:update(self(), NVal, Map),
            persistent_term:put(map, M),

            RMap2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RMap2),
            persistent_term:put(rmap, R);

        {_Id, _Msg} ->
            Map = persistent_term:get(map),
            {ok, Val} = maps:find(self(), Map),

            NVal = Val + 1,
            M = maps:update(self(), NVal, Map),
            persistent_term:put(map, M),

            RMap2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RMap2),
            persistent_term:put(rmap, R),

            % io:fwrite("received from ~p ~p\n", [_Id, self()]),
            % io:fwrite("~p\n", [M]),

            if
                NVal < 10 ->
                    gossip(Topology, Limit);
                NVal == 10 ->
                    F_List = persistent_term:get(fin),
                    Boolean = lists:member(self(), F_List),
                    if
                        Boolean == false ->
                            FL = [self()],
                            F = F_List ++ FL,
                            persistent_term:put(fin, F);
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            if Topology == full andalso NVal ==10 ->
                
                L2 = lists:delete(self(),L1),
                persistent_term:put(list,L2);
            true ->
                ok
            end;


        {_Pid} ->

            %  Map = persistent_term:get(map),
            % {ok, Val} = maps:find(self(), Map),
            % NVal = Val + 1,
            % M = maps:update(self(), NVal, Map),
            % persistent_term:put(map, M),

            % RMap2 = persistent_term:get(rmap),
            % R = maps:update(self(), true, RMap2),
            % persistent_term:put(rmap, R),






            F_List = persistent_term:get(fin),
            X = length(F_List),
            if
                Topology == line orelse Topology == twodgrid orelse Topology == impthreed ->
                    Neighbor = persistent_term:get(neighbor),
                    Is_key = maps:is_key(self(), Neighbor),

                    Finlen = length(F_List),

                    if
                        Is_key == true ->
                            if
                                Finlen =/= 0 ->
                                    N_list = maps:get(self(), Neighbor),
                                    Y = length(N_list),
                                    converge(N_list, self(), Y);
                                % io:fwrite("~p\n",[K]);
                                true ->
                                    d
                            end;
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            if
                X == Limit ->
                    io:format("Finished List: ~p~n", [F_List]),
                    % Mega_map = persistent_term:get(map),
                    % io:format("Map: ~p~n", [Mega_map]),
                    lastid ! {programend},
                    exit(bas);
                true ->
                    gossip(Topology, Limit)
            end
    end,
    gossip(Topology, Limit).



push_sum(Topology, Limit) ->
    Fin_List = persistent_term:get(fin),

    RMap = persistent_term:get(rmap),
    io:fwrite("~p~n", [Fin_List]),
    Bool = maps:find(self(), RMap),
    Check = lists:member(self(), Fin_List),

    if
        Bool == {ok, true} ->
            % io:fwrite("~p",[Check]),
            if
                Check == false ->
                    LL = persistent_term:get(list),
                    Weights_map = persistent_term:get(weights),
                    {Sum, Weight} = maps:get(self(), Weights_map),
                    Rand = random_loop(self(), LL, Topology),
                    Rand ! {self(), Sum, Weight};
                true ->
                    ok
            end;
        true ->
            ok
    end,

    sid ! {self(), "self"},
    receive
        {_Id, initial} ->
            Weights_map3 = persistent_term:get(weights),
            {S2, W2} = maps:get(self(), Weights_map3),
            NewS = S2 / 2,
            NewW = W2 / 2,
            Weights_map2 = maps:update(self(), {NewS, NewW}, Weights_map3),
            persistent_term:put(weights, Weights_map2),
            RMap2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RMap2),
            persistent_term:put(rmap, R),

            Random_node = random_loop(self(), persistent_term:get(list), Topology),
            Random_node ! {self(), NewS, NewW};

        {_Pid, S, W} ->
            Weights_map3 = persistent_term:get(weights),
            {Pid_Sum, Pid_Weight} = maps:get(self(), Weights_map3),
            % io:fwrite("sum: ~p~n, Weight: ~p~n", [Pid_Sum, Pid_Weight]),
            NewSum = Pid_Sum + S,
            NewWeight = Pid_Weight + W,

            if
                W /= 0.0 ->
                    Change = abs(NewSum / NewWeight - S / W),
                    Delta = math:pow(10, -10),
                    if
                        Change < Delta ->
                            Node_map = persistent_term:get(map),
                            TermRound = maps:get(self(), Node_map),
                            Node_map2 = maps:update(self(), TermRound + 1, Node_map),
                            persistent_term:put(map, Node_map2);
                        true ->
                            Node_map = persistent_term:get(map),
                            Node_map2 = maps:update(self(), 0, Node_map),
                            persistent_term:put(map, Node_map2)
                    end,
                    Node_map3 = persistent_term:get(map),
                    TermRound2 = maps:get(self(), Node_map3),
                    if
                        TermRound2 == 3 ->
                            Fin_List = persistent_term:get(fin),
                            Fin_List2 = lists:append(Fin_List, [self()]),
                            persistent_term:put(fin, Fin_List2);
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            Weights_map2 = maps:update(self(), {NewSum, NewWeight}, Weights_map3),
            persistent_term:put(weights, Weights_map2),
            RMap2 = persistent_term:get(rmap),
            R = maps:update(self(), true, RMap2),
            persistent_term:put(rmap, R),

            Random_node = random_loop(self(), persistent_term:get(list), Topology),
            Random_node ! {self(), NewSum / 2, NewWeight / 2};


        {_Pid} ->
            F_List = persistent_term:get(fin),
            X = length(F_List),
            if
                Topology == line orelse Topology == twodgrid orelse Topology == impthreed ->
                    Neighbor = persistent_term:get(neighbor),
                    Is_key = maps:is_key(self(), Neighbor),

                    Finlen = length(F_List),

                    if
                        Is_key == true ->
                            if
                                Finlen =/= 0 ->
                                    N_list = maps:get(self(), Neighbor),
                                    Y = length(N_list),
                                    converge(N_list, self(), Y);
                                % io:fwrite("~p\n",[K]);
                                true ->
                                    d
                            end;
                        true ->
                            ok
                    end;
                true ->
                    ok
            end,

            if
                X == Limit ->
                    io:format("Finished List: ~p~n", [F_List]),
                    % Mega_map = persistent_term:get(map),
                    % io:format("Map: ~p~n", [Mega_map]),
                    lastid ! {programend},
                    exit(bas);
                true ->
                    gossip(Topology, Limit)
            end,

            Finished_List = persistent_term:get(fin),
            X = length(Finished_List),
            if
                X == Limit ->
                    lastid ! {programend},
                    exit(bas);
                true ->
                    push_sum(Topology, Limit)
            end
    end,
    push_sum(Topology, Limit).

converge(_, Node_id, 0) ->
    F_List = persistent_term:get(fin),
    Boolean = lists:member(Node_id, F_List),
    if
        Boolean == false ->
            FL = [Node_id],
            F = F_List ++ FL,
            persistent_term:put(fin, F);
        true ->
            ok
    end;

converge(N_list, Node_id, Len) ->
    F_list = persistent_term:get(fin),
    [Head | Tail] = N_list,

    Chk = lists:member(Head, F_list),
    % io:fwrite("~p\n", [Chk]),
    if
        Chk == true ->
            converge(Tail, Node_id, Len - 1);
        true ->
            f
    end.