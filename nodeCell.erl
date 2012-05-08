%% TODO: 
%% 1. Check for self reference - DONE
%% 2. Add weight for usage count - DONE
%% 3. Add consolidate functionality (to look for duplicates and merge them)
%% 4. Add backward references / links

-module(nodeCell).
-import(io).
-import(lists).
-export([create/0, loop/0]).

create()->
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
	{Source, {getMeYourLinks}}->
		io:fwrite("Asked about my links~n"),
		Source ! {thisAreMyLinks, Links},
		startLoop(Links, StoredMessage);
	{Source, {whoAreYou}}->
		io:fwrite("Asked about who I am - ~w ~w~n",[Message, HitCount]),
		Source ! {self(), {iAm, {Message, HitCount}}},
		startLoop(Links, StoredMessage);
	{Source, {event, {PrevMessage, ActualMessage}}}->
	    io:fwrite("~w Event catched~n",[self()]),
		%% is the old message current node?
		%% yes, so we look for the connection on the actual message
	    if PrevMessage == Message ->
			   
			%%Is the actual message the same with the current node
			%% yes
		    if ActualMessage == Message ->
			    io:fwrite("~w Linking to itself~n",[self()]),
				%% Anounce that we have found ourselves
				Source ! {found, self()},
				
				%% Add more score to the hit count of the node
			    startLoop(Links, makeStoredData(Message, HitCount + 2));
			   
			%% no
		    true ->
			    io:fwrite("~w Looking up neighbors~n",[self()]),
			    Value = lookupNeighbours(Links, ActualMessage),
			    if Value /= 0 ->
				    io:fwrite("~w Node Found~n",[Value]),
					Source ! {found, Value},
				    startLoop(Links,makeStoredData(Message, HitCount + 1));
			    true ->
				    io:fwrite("~w New Node added~n",[self()]),
				    NewLink = create(),
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
		    propagate(Links, {PrevMessage, ActualMessage}, Source),
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

propagate([], {_, PropagatedMessage}, _) ->
    PropagatedMessage;
propagate([H|T], {PrevMessage, PropagatedMessage}, Source)->
    H ! {Source, {event, {PrevMessage, PropagatedMessage}}},
    propagate(T, {PrevMessage, PropagatedMessage}, Source);
propagate([H], {PrevMessage, PropagatedMessage}, Source) ->
    H ! {Source, {event, {PrevMessage, PropagatedMessage}}},
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
	{Source, {searchResult, false}}->
	    Out = waitResults();
	{Source, {searchResult, true}} ->
	    Out = Source
    after 1050 ->
	    Out = 0
    end,
    Out.
	    
	    
