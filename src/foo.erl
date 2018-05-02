-module(foo).
-export([start_link/0]).
-export([init/1, handle_info/2]).

start_link() ->
    gen_server:start_link(foo, [], []).

init([]) ->
    timer:send_interval(1000, self(), hello),
    {ok, []}.

handle_info(hello, State) ->
    io:format("hello~n"),
    {noreply, State};

handle_info(_Msg, State) ->
    {noreply, State}.
