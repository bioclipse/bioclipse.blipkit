/* -*- Mode: Prolog -*- */

:- module(metadata_db,
          [idspace/1,
           idspace_uri/2,
           id_idspace/2,
           id_localid/2,
           partition/1,
           entity_label/2,
           entity_label_or_synonym/2,
           entity_label_scope/3,
           entity_alternate_identifier/2,
           entity_source/2,
           entity_partition/2,
           entity_resource/2,
           entity_creator/2,
           entity_publisher/2,
           entity_contributor/2,
           entity_comment/2,
           entity_example/2,
           entity_created/2,
           entity_description/2,
           entity_description_type/3,
           entity_xref/2,
           entity_date/2,
           entity_obsolete/2,
           entity_consider/2,
           entity_replaced_by/2,
           entity_consider_or_replaced_by/2,
           entity_synonym/2,
           entity_synonym_scope/3,
           entity_synonym_type/3,
           entity_synonym_xref/3,
           entity_authority/2,
           entity_localname/2,
           entity_pair_is_non_univocal/2,
           entity_pair_is_non_univocal/3,
           entity_query/2,
           synonym_type_desc/3
          ]).

% metadata on the data predicates used in this module
:- use_module(bio(dbmeta)).

%% idspace(?IDSpace)
:- extensional(idspace/1).

%% id_idspace(?ID,?IDSpace)
% true if ID is prefixed with IDSpace
id_idspace(ID,IDSpace) :- concat_atom([IDSpace|_],':',ID).
:- pure(id_idspace/2).

%% id_localid(?ID,?IDSpace)
% true if ID is suffixed with IDSpace
id_localid(ID,Local) :- concat_atom([_|L],':',ID),concat_atom(L,':',Local).

        
%% idspace_uri(?IDSpace,?URI)
% maps IDspaces (aka namespaces) such as GO to URI prefixes -- such as http://purl.org/obo/owl/GO#
:- extensional(idspace_uri/2).

%% partition(?Partition)
% true if Partition identifies a subset of entities grouped together for some purpose.
% paritions can also be seen as extensional views over a resource.
% corresponds to subsets in OBO format, or slims in GO
:- extensional(partition/1).

%% entity_label(?Entity,?Label)
%  it is recommended (required?) that entities have a single label
%  use entity_synonym/2 for multiple labels
:- extensional(entity_label/2).

%% entity_alternate_identifier(?Entity,?AltID)
%  both Entity and AltID denote the same entity
% same as alt_id
:- extensional(entity_alternate_identifier/2).

%% entity_resource(?Entity,?Source)
%  true if Entity is derived from Source
%  - Source denotes a logical source, for example an identifier for a publication
:- extensional(entity_source/2).

:- extensional(entity_example/2).
:- extensional(entity_creator/2).
:- extensional(entity_publisher/2).
:- extensional(entity_contributor/2).

%% entity_resource(?Entity,?Resource)
%  true if Entity comes from Resource, where Resource is a physical resource - 
%  typically a file, URI or namespace
%  not to be confused with entity_source/2 - the distinction is logical vs physical
:- extensional(entity_resource/2).

%% entity_comment(?Entity,?Comment)
% true if Comment is a human-readable text comment associated with Entity
:- extensional(entity_comment/2).

%% entity_partition(?Entity,?Partion)
%  true if Entity belongs to Partition
:- extensional(entity_partition/2).

%% entity_created(?Entity,?Date)
% true if Entity created on Date
% Date is in form YYYY-MM-DD
:- extensional(entity_created/2).

:- extensional(entity_description/2).
:- extensional(entity_description_type/3).
entity_definition(E,D):- entity_description_type(E,D,definition).

:- extensional(entity_xref/2).
:- extensional(entity_date/2). % todo: 3-ary event-date?

%% entity_obsolete(?Entity,?Predicate) is nondet
%  true if Entity is a retired identifier, and Predicate(Entity) was once true
:- extensional(entity_obsolete/2).

:- extensional(entity_consider/2).
:- extensional(entity_replaced_by/2).

entity_consider_or_replaced_by(E,X):- entity_consider(E,X).
entity_consider_or_replaced_by(E,X):- entity_replaced_by(E,X).


:- extensional(entity_synonym/2).
:- extensional(entity_synonym_scope/3).
:- extensional(entity_synonym_type/3).
:- extensional(entity_synonym_xref/3).

entity_label_or_synonym(E,L):- entity_synonym(E,L).
entity_label_or_synonym(E,L):- entity_label(E,L).


%% entity_label_type(?E,?L,?label) is nondet
% any kind of label/synonym
entity_label_scope(E,L,label):- entity_label(E,L).
entity_label_scope(E,L,T):- entity_synonym_scope(E,L,T).



entity_pair_is_non_univocal(E1,E2):-
        entity_pair_is_non_univocal(E1,E2,_).
entity_pair_is_non_univocal(E1,E2,N):-
        entity_label(E1,N),
        entity_label(E2,N),
        \+ entity_obsolete(E1,_),
        \+ entity_obsolete(E2,_),
        E1\=E2.

:- extensional(synonym_type_desc/3).


entity_authority(E,A):-
        concat_atom([A,_|_],':',E).
entity_localname(E,N):-
        concat_atom([_|T],':',E),
        (   T=[]
        ->  N=E
        ;   concat_atom(T,':',N)).


entity_query(search(S),_):-
        var(S),
        !,
        throw(search_term_must_be_instantiated).
entity_query(search(''),ID):-
        entity_label(ID,_).
entity_query(search(ID),ID):-
        ID \= '',
        entity_label(ID,_).
entity_query(search(S),ID):-
        S \= '',
        entity_label(ID,S).
entity_query(search(S),ID):-
        S \= '',
        downcase_atom(S,Slc),
        entity_query(search_lc(Slc),ID).
entity_query(search_lc(Slc),ID):-
        entity_label(ID,N),
        downcase_atom(N,Nlc),
        sub_atom(Nlc,_,_,_,Slc).
%entity_query(search_lc(Slc),ID):-
%        def(ID,N),
%        downcase_atom(N,Nlc),
%        sub_atom(Nlc,_,_,_,Slc).


/** <module> modeling of simple metadata

  ---+ Synopsis

  ==
  :- use_module(bio(metadata_db)).

  ==

  ---+ Package

  This module is part of the blipkit metadata package. See README.txt
  
  ---+ Description

  see also - dublin core -- http://dublincore.org/
  
**/
