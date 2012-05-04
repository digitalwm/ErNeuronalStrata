%% TODO: 
%% 1. Check for self reference - DONE
%% 2. Add weight for usage count - DONE
%% 3. Add consolidate functionality (to look for duplicates and merge them)
%% 4. Add backward references / links

-module(nodeCell).
-export([start/0, loop/0]).

start()->
    spawn(nodeCell,loop,[]).

loop()->
    Links = [],
    startLoop(Links, {"",0}).

startLoop(Links, StoredMessage)->
    {Message, HitCount} = StoredMessage,
    receive
	{_, {init, NewMessage}}->
	    io:fwrite("~w Node initialised~n",[self()]),
	    startLoop(Links, {NewMessage, 0});
	{_, {event, {PrevMessage, ActualMessage}}}->
	    io:fwrite("~w Event catched~n",[self()]),
	    if PrevMessage == Message ->
		    if ActualMessage == Message ->
			    io:fwrite("~w Linking to itself~n",[self()]),
			    startLoop(Links, makeStoredData(Message, HitCount + 2));
		       true ->
			    io:fwrite("~w Looking up neighbors~n",[self()]),
			    Value = lookupNeighbours(Links, ActualMessage),
			    if Value == 1 ->
				    io:fwrite("~w Node Found~n",[self()]),
				    startLoop(Links,makeStoredData(Message, HitCount + 1));
			       true ->
				    io:fwrite("~w New Node added~n",[self()]),
				    NewLink = start(),
				    io:fwrite("~w Node created ~w~n",[self(),NewLink]),
				    io:fwrite("~w List available ~w~n",[self(),Links]),
				    NewLinks = lists:append(Links, [NewLink]),
				    io:fwrite("~w Saved Link to Link ~w~n",[self(),NewLinks]),
				    NewLink ! {self(), {init, ActualMessage}},
				    startLoop(NewLinks, makeStoredData(Message,HitCount))
			    end
		    end;
	    true ->
		    io:fwrite("~w Propagatig forward~n",[self()]),
		    propagate(Links, {PrevMessage, ActualMessage}),
		    startLoop(Links, makeStoredData(Message,HitCount))			
	    end;
	{Source, {search, SearchedMessage}}->
	    if Message == SearchedMessage ->
		    Source ! {self(), {searchResult, true}},
		    io:fwrite("~w Message found~n",[self()]);
	    true ->
		    Source ! {self(), {searchResult, false}},
		    io:fwrite("~w Message not found~n",[self()])
	    end,
	    startLoop(Links, makeStoredData(Message,HitCount))
    end
.

makeStoredData(Message, HitCount)->
    {Message, HitCount}.

propagate([], {PrevMessage, PropagatedMessage}) ->
    PropagatedMessage;
propagate([H|T], {PrevMessage, PropagatedMessage})->
    H ! {self(), {event, {PrevMessage, PropagatedMessage}}},
    propagate(T, {PrevMessage, PropagatedMessage});
propagate([H], {PrevMessage, PropagatedMessage}) ->
    H ! {self(), {event, {PrevMessage, PropagatedMessage}}},
    PropagatedMessage.

lookupNeighbours(Links, SearchedMessage)->
    traverseSearch(Links, SearchedMessage),
    io:fwrite("Traversed Searched~n"),
    LookupResult = waitResults(),
    io:fwrite("Lookup Res ~w~n",[LookupResult]),
    LookupResult.

traverseSearch([], SearchedMessage)->
    SearchedMessage;
traverseSearch([H], SearchedMessage) ->
    H ! {self(), {search, SearchedMessage}},
    SearchedMessage;
traverseSearch([H|T], SearchedMessage)->
    H ! {self(), {search, SearchedMessage}},
    traverseSearch(T, SearchedMessage).

waitResults()->
    receive
	{_, {searchResult, false}}->
	    Out = waitResults();
	{_, {searchResult, true}} ->
	    Out = 1
    after 1050 ->
	    Out = 0
    end,
    Out.
	    
	    
