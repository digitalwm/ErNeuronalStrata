-module(nodePredictor).
-import(io).
-import(lists).
-export([create/2, loopPredictor/2]).

create(StartingPID, ParentID)->
    spawn(nodePredictor,loopPredictor,[StartingPID, ParentID]).

loopPredictor(StartingPID, ParentID)->
    StartingPID ! {self(), {getMeYourLinks}},
	receive
		{thisAreMyLinks, List} ->
			io:fwrite("Predictor: received Links~n"),
			loopMetrics(ParentID, List)
	after 500 ->
		timeout
	end.

loopMetrics(ParentID, List) ->
	loopSend(List),
	Data = loopReceive(List,[]),
	ParentID ! {self(), {predict, Data}}.

loopSend([])->
	ok;
loopSend([H])->
	H ! {self(), {whoAreYou}},
	ok;
loopSend([H|T])->
	H ! {self(), {whoAreYou}},
	loopSend(T).

loopReceive([],Results)->
	Results;
loopReceive(List, Results)->
	receive
		{H, {iAm, {Memory, Count}}}->
			NewResults = lists:append(Results, [{Memory, Count}]),
			loopReceive(lists:delete(H, List), NewResults)
	after 100->
		Results
	end.