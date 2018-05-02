-module(foo_sup).
-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link(foo_sup, []).

init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 1, period => 5},
    ChildSpecs = [#{id => foo, start => {foo, start_link, []}}],
    {ok, {SupFlags, ChildSpecs}}.
