-module(nodeStrata).
-export([start/1]).
-import(nodeCell,[create/0]).
-import(gen_tcp).
-import(string).
-import(io).

-define(TCP_OPTIONS,[list, {packet, 0}, {active, false}, {reuseaddr, true}]).

start()->
	start(2000).
start(Port) ->
    	S = nodeCell:create(),
	{ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
	doAccept(LSocket, S).

doAccept(LSocket, S) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    spawn(fun() -> doClientLoop(Socket, S, "") end),
    doAccept(LSocket, S).

doClientLoop(Socket, S, L) ->
    case gen_tcp:recv(Socket, 0, 30000) of
        {ok, Data} ->
	    IsClear = string:equal(Data, "#clr"),
	    if 
		IsClear == true ->
		    doClientLoop(Socket,S, "");
		true ->
		    S ! {self(), {event, {L, Data}}},
		    gen_tcp:send(Socket, "Ok\n"),
		    doClientLoop(Socket, S, Data)
	    end;
	{error, closed} ->
            ok;
	{error, timeout} ->
	    io:fwrite("Last data cleaned~n"),
	    grabEventsAndSend(Socket),
	    doClientLoop(Socket, S, "")
    end.

grabEventsAndSend(Socket) ->
    receive
	    {_, Data} ->
		    gen_tcp:send(Socket, Data),
		    grabEventsAndSend(Socket)
    after 0 ->
	    ok
    end.

