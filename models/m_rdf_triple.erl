-module(m_rdf_triple).

-export([
    insert/2
]).

-include_lib("zotonic.hrl").
-include_lib("../include/rdf.hrl").

%% @doc Insert a triple, making sure no duplicates are created
%% @spec insert(Triple, Context) -> {ok, Id} | {error, Reason}
insert(#triple{type=Type, subject=Subject, predicate=Predicate, object=Object}, Context) ->
    PredicateId = ensure_predicate(Predicate, Context),
    Result = m_edge:insert(
        m_rdf:ensure_resource(Subject, Context), 
        PredicateId, 
        m_rdf:ensure_resource(Object, Context),
        Context
    ),
    ?DEBUG({"Inserting RDF triple for ", Subject}).

%% @doc Ensure predicate exists. If it doesn't yet exist, create it.
%% @spec ensure_predicate(Uri, Context) -> int()
ensure_predicate(Uri, Context) ->
    %% Check if the predicate already exists in Zotonic
    case m_rsc:uri_lookup(Uri, Context) of
        undefined ->
            %% predicate needs to be created
            {ok, Id} = create_predicate(Uri, Context),
            Id;
        Id -> Id
    end.
    
%% @doc Create RDF predicate
create_predicate(Uri, Context) ->
    Props = [
        {title, Uri},
        {name, z_string:to_name(Uri)},
        {uri, Uri},
        {category, predicate},
        {group, admins},
        {is_published, true},
        {visible_for, 0}
    ],
    case m_rsc_update:insert(Props, [{acl_check, false}], Context) of
        {ok, Id} -> 
            m_predicate:flush(Context),
            {ok, Id};
        {error, Reason} ->
            {error, Reason}
    end.
