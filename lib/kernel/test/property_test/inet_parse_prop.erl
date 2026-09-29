%%
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2021-2026. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
%%
-module(inet_parse_prop).
-compile([export_all, nowarn_export_all]).

-include_lib("common_test/include/ct_property_test.hrl").

%%%%%%%%%%%%%%%%%%
%%% Properties %%%
%%%%%%%%%%%%%%%%%%

%% ipv4_address/1, address/1
prop_ipv4_address() ->
    ?FORALL(
        {Expected, Str},
        gen_ipv4_relaxed_address(),
        {ok, Expected} =:= inet_parse:ipv4_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:ipv4_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:address(Str)
        andalso
        {ok, Expected} =:= inet_parse:address(list_to_binary(Str))
    ).

%% ipv4strict_address/1, strict_address/1, ipv4_address/1, address/1
prop_ipv4strict_address() ->
    ?FORALL(
        {Expected, Str},
        gen_ipv4_strict_address(),
        {ok, Expected} =:= inet_parse:ipv4strict_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:ipv4strict_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:strict_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:strict_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:ipv4_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:ipv4_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:address(Str)
        andalso
        {ok, Expected} =:= inet_parse:address(list_to_binary(Str))
    ).

%% ipv6_address/1, address/1
prop_ipv6_address() ->
    ?FORALL(
        {Kind, Expected, Str},
        gen_ipv6_relaxed_address(),
        {ok, Expected} =:= inet_parse:ipv6_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:ipv6_address(list_to_binary(Str))
        andalso
        case Kind of
            ipv6 ->
                {ok, Expected} =:= inet_parse:address(Str)
                andalso
                {ok, Expected} =:= inet_parse:address(list_to_binary(Str));
            ipv4 ->
                true
        end
    ).

%% ipv6strict_address/1, strict_address/1, ipv6_address/1, address/1
prop_ipv6strict_address() ->
    ?FORALL(
        {Expected, Str},
        gen_ipv6_strict_address(),
        {ok, Expected} =:= inet_parse:ipv6strict_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:ipv6strict_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:strict_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:strict_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:ipv6_address(Str)
        andalso
        {ok, Expected} =:= inet_parse:ipv6_address(list_to_binary(Str))
        andalso
        {ok, Expected} =:= inet_parse:address(Str)
        andalso
        {ok, Expected} =:= inet_parse:address(list_to_binary(Str))
    ).

%%%%%%%%%%%%%%%%%%
%%% Generators %%%
%%%%%%%%%%%%%%%%%%

%% Generator for {Addr, Str} with Str in strict dotted-decimal IPv4 notation.
gen_ipv4_strict_address() ->
    ?LET(
        {N1, N2, N3, N4} = Addr,
        {?CT_BYTE(), ?CT_BYTE(), ?CT_BYTE(), ?CT_BYTE()},
        ?LET(
            Str,
            [gen_ipv4_field(N1, dec), $., gen_ipv4_field(N2, dec), $., gen_ipv4_field(N3, dec), $., gen_ipv4_field(N4, dec)],
            {Addr, lists:flatten(Str)}
        )
    ).

%% Generator for {Addr, Str} with Str in relaxed IPv4 notation: 1 to 4
%% fields, each in decimal, octal or hexadecimal.
gen_ipv4_relaxed_address() ->
    ?LET(
        {N1, N2, N3, N4} = Addr,
        {?CT_BYTE(), ?CT_BYTE(), ?CT_BYTE(), ?CT_BYTE()},
        ?LET(
            Str,
            oneof([
                       [gen_ipv4_field((N1 bsl 24) bor (N2 bsl 16) bor (N3 bsl 8) bor N4)],
                       [gen_ipv4_field(N1), $., gen_ipv4_field((N2 bsl 16) bor (N3 bsl 8) bor N4)],
                       [gen_ipv4_field(N1), $., gen_ipv4_field(N2), $., gen_ipv4_field((N3 bsl 8) bor N4)],
                       [gen_ipv4_field(N1), $., gen_ipv4_field(N2), $., gen_ipv4_field(N3), $., gen_ipv4_field(N4)]
                  ]),
           {Addr, lists:flatten(Str)}
        )
    ).

%% Generator for the textual representation of IPv4 field value N, in
%% random or given (hex, dec, oct) notation, with random leading zeros
%% for hex and oct.
gen_ipv4_field(N) ->
    ?LET(
        F,
        oneof([hex, dec, oct]),
        gen_ipv4_field(N, F)
    ).

gen_ipv4_field(N, hex) ->
    ?LET(
       {W, X, B},
       {?CT_RANGE(1, 8), oneof([$x, $X]), oneof([$b, $B])},
       begin
           Str = lists:flatten(io_lib:format("~.16" ++ [B], [N])),
           [$0, X] ++ lists:duplicate(max(0, W - length(Str)), $0) ++ Str
       end
    );
gen_ipv4_field(N, dec) ->
    lists:flatten(io_lib:format("~.10b", [N]));
gen_ipv4_field(N, oct) ->
    ?LET(
        W,
        ?CT_RANGE(0, 11),
        begin
            Str = lists:flatten(io_lib:format("~.8b", [N])),
            [$0] ++ lists:duplicate(max(0, W - length(Str)), $0) ++ Str
        end
    ).

%% Generator for {Kind, Addr, Str}, where Str is either an IPv6 address
%% (Kind = ipv6) or a relaxed IPv4 address (Kind = ipv4), which is
%% expected as IPv4-mapped IPv6 address.
gen_ipv6_relaxed_address() ->
    oneof([
        ?LET({Addr, Str}, gen_ipv6_strict_address(), {ipv6, Addr, Str}),
        ?LET(
            {{N1, N2, N3, N4}, Str},
            gen_ipv4_relaxed_address(),
            {ipv4, {0, 0, 0, 0, 0, 16#ffff, (N1 bsl 8) bor N2, (N3 bsl 8) bor N4}, Str}
        )
    ]).

%% Generator for {Addr, Str} with Str in IPv6 notation, with or without
%% an embedded strict IPv4 address in place of the last two fields.
gen_ipv6_strict_address() ->
    oneof([
        gen_ipv6_fields(8),
        ?LET(
            {{NsHex, StrHex}, {{N1, N2, N3, N4}, StrV4}},
            {gen_ipv6_fields(6), gen_ipv4_strict_address()},
            {
                list_to_tuple(tuple_to_list(NsHex) ++ [(N1 bsl 8) bor N2, (N3 bsl 8) bor N4]),
                case lists:suffix("::", StrHex) of
                    true -> StrHex ++ StrV4;
                    false -> StrHex ++ ":" ++ StrV4
                end
            }
        )
    ]).

%% Generator for {Addr, Str} with Str being Total IPv6 fields, with a
%% random run of zero fields compressed to "::".
gen_ipv6_fields(Total) ->
    ?LET(
        {FieldsL, FieldsR},
        {?CT_RANGE(0, Total), ?CT_RANGE(0, Total)},
        ?LET(
            {NsL, NsM, NsR},
            {vector(FieldsL, ?CT_RANGE(0, 16#FFFF)), lists:duplicate(max(0, Total - FieldsL - FieldsR), 0), vector(min(FieldsR, Total - FieldsL), ?CT_RANGE(0, 16#FFFF))},
            ?LET(
                {StrsL, StrsR},
                {lists:map(fun gen_ipv6_field/1, NsL), lists:map(fun gen_ipv6_field/1, NsR)},
                {
                    list_to_tuple(NsL ++ NsM ++ NsR),
                    lists:flatten(
                        if
                            NsM =:= [] -> lists:join($:, StrsL ++ StrsR);
                            true -> [lists:join($:, StrsL), "::", lists:join($:, StrsR)]
                        end
                    )
                }
            )
        )
    ).

%% Generator for the textual representation of IPv6 field value N, in
%% random case and with random leading zeros.
gen_ipv6_field(N) ->
    ?LET(
        {W, B},
        {?CT_RANGE(1, 4), oneof([$b, $B])},
        begin
            Str = lists:flatten(io_lib:format("~.16" ++ [B], [N])),
            lists:duplicate(max(0, W - length(Str)), $0) ++ Str
        end
    ).
