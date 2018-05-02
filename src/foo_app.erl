-module(foo_app).
-export([start/2]).

start(normal, []) ->
    foo_sup:start_link().
