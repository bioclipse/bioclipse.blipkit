/* -*- Mode: Prolog -*- */


:- module(ontol_bridge_from_owl2,
          [
           owlrestriction_to_oborelationship/2,
           rdfid_oboid/2
          ]).

% SEE ALSO: ontol_bridge_from_owl2_ext - in progress
% REMEMBER: -f thea2_owl on command line

:- use_module(bio(ontol_db),[]).
:- use_module(bio(rdf_id_util),[rdfid_oboid/2]).
:- use_module(bio(mode)).
:- use_module(bio(bioprolog_util),[solutions/3]).
:- use_module(library('thea2/owl2_model')).
:- use_module(library('semweb/rdf_db'),[rdf_global_id/2]).

:- dynamic implicit_metarelation/3.

:- multifile suppress_entity/1.
% OE1 has issues with relationships to xsd types
suppress_entity(X) :- nonvar(X),atom(X),sub_atom(X,0,_,_,'http://www.w3.org/2001/XMLSchema#').

% cut-n-pasted:
literal_value_type(literal(lang(en,X)),X,string):- !.
literal_value_type(literal(lang(_,X)),X,string):- !.
literal_value_type(literal(type(T1,X)),X,T):- !, convert_xsd_type(T1,T).
literal_value_type(literal(X),X,string):- !.

% shorten xsd url to prefix
convert_xsd_type(In,Out):-
        rdf_global_id(Prefix:Local,In),
        concat_atom([Prefix,Local],':',Out),
        !.
convert_xsd_type(X,X).

% ----------------------------------------
% HOOKS
% ----------------------------------------
:- multifile consumed_property/1.
consumed_property('rdfs:label').


% ----------------------------------------
% DECLARATIONS
% ----------------------------------------
ontol_db:class(X) :-    rdfid_oboid(U,X),owl2_model:class(U),\+suppress_entity(U).
ontol_db:property(X) :- rdfid_oboid(U,X),owl2_model:objectProperty(U),\+suppress_entity(U).
%ontol_db:inst(X) :- rdfid_oboid(U,X),owl2_model:namedIndividual(U),\+suppress_entity(U).
ontol_db:inst(X) :- rdfid_oboid(U,X),owl2_model:classAssertion(_,U),\+suppress_entity(U).

% TODO: annotationAsserted --> is_obsolete

% ----------------------------------------
% ANNOTATIONS
% ----------------------------------------
% these are intended to be extended in specific modules
metadata_db:entity_label(X,Label) :- rdfid_oboid(U,X),owl2_model:labelAnnotation_value(U,Label).

% ----------------------------------------
% RELATION AXIOMS
% ----------------------------------------
ontol_db:is_transitive(X) :- rdfid_oboid(U,X),transitiveProperty(U).
ontol_db:is_reflexive(X) :- rdfid_oboid(U,X),reflexiveProperty(U).
ontol_db:is_irreflexive(X) :- rdfid_oboid(U,X),irreflexiveProperty(U).
ontol_db:is_symmetric(X) :- rdfid_oboid(U,X),symmetricProperty(U).
ontol_db:is_asymmetric(X) :- rdfid_oboid(U,X),asymmetricProperty(U).
ontol_db:is_functional(X) :- rdfid_oboid(U,X),functionalProperty(U).
ontol_db:is_inverse_functional(X) :- rdfid_oboid(U,X),inverseFunctionalProperty(U).
ontol_db:inverse_of_on_instance_level(X,Y) :- rdfid_oboid(UX,X),rdfid_oboid(UY,Y),owl2_model:inverseProperties(UX,UY).

% NOTE: revisit in future versions: overloading obo subsumption relation for legacy reasons
ontol_db:subclass(X,Y) :-
        rdfid_oboid(UX,X),rdfid_oboid(UY,Y),owl2_model:subPropertyOf(UX,UY),
        objectProperty(UX),objectProperty(UY).
% TODO: more complex role chains
ontol_db:holds_over_chain(X,Y,Z) :- rdfid_oboid(UX,X),rdfid_oboid(UY,Y),rdfid_oboid(UZ,Z),owl2_model:subPropertyOf(UX,propertyChain([UY,UZ])).

% all-some/all-only
ontol_db:property_relationship(R1,MR,R2) :- implicit_metarelation(R1,MR,R2).

% ----------------------------------------
% CLASS AXIOMS
% ----------------------------------------
%ontol_db:subclass(X,Y) :- rdfid_oboid(UX,X),rdfid_oboid(UY,Y),owl2_model:subClassOf(UX,UY),class(UX),class(UY),\+suppress_entity(UY).
ontol_db:subclass(X,Y) :- rdfid_oboid(UX,X),rdfid_oboid(UY,Y),owl2_model:subClassOf(UX,UY),referenceable(UX),referenceable(UY),classExpression(UX),classExpression(UY),\+suppress_entity(UY).
ontol_db:restriction(X,R,Y) :- rdfid_oboid(UX,X),owl2_model:subClassOf(UX,Restr),owlrestriction_to_oborelationship(Restr,R=Y).
ontol_db:min_cardinality_restriction(X,R,Card,Y) :- rdfid_oboid(UX,X),owl2_model:subClassOf(UX,Restr),owlrestriction_to_oborelationship(Restr,c(min,Card,R,Y)).
ontol_db:max_cardinality_restriction(X,R,Card,Y) :- rdfid_oboid(UX,X),owl2_model:subClassOf(UX,Restr),owlrestriction_to_oborelationship(Restr,c(max,Card,R,Y)).
ontol_db:exact_cardinality_restriction(X,R,Card,Y) :- rdfid_oboid(UX,X),owl2_model:subClassOf(UX,Restr),owlrestriction_to_oborelationship(Restr,c(exact,Card,R,Y)).

% so far we only allow intersection-constructs in genus-differentia form
ontol_db:genus(X,Y) :- class_genus_differentia(X,Y,_).
%ontol_db:genus(X,Y) :- setof(X-Y,Z^class_genus_differentia(X,Y,Z),XYs),member(X-Y,XYs).
ontol_db:differentium(X,R,Y) :- class_genus_differentia(X,_,DL),member(R=Y,DL).

% so far we only allow named classes in the union element
ontol_db:class_union_element(X,Y) :-
        rdfid_oboid(UX,X),rdfid_oboid(UY,Y),
        owl2_model:equivalentClasses(EL),
        member(UX,EL),class(UX),
        member(unionOf(UL),EL),
        member(UY,UL).

ontol_db:disjoint_from(X,Y) :- rdfid_oboid(UX,X),rdfid_oboid(UY,Y),owl2_model:disjoint_with(UX,UY).

% ----------------------------------------
% INSTANCE AXIOMS
% ----------------------------------------
ontol_db:inst_of(X,Y) :- rdfid_oboid(UX,X),rdfid_oboid(UY,Y),owl2_model:classAssertion(UY,UX).
ontol_db:inst_rel(X,R,Y) :- rdfid_oboid(UX,X),rdfid_oboid(UR,R),rdfid_oboid(UY,Y),owl2_model:objectPropertyAssertion(UR,UX,UY).
ontol_db:inst_sv(X,R,Y,DT) :- rdfid_oboid(UX,X),rdfid_oboid(UR,R),
        owl2_model:propertyAssertion(UR,UX,Lit),literal_value_type(Lit,Y,DT),
        \+ consumed_property(R),
        \+ consumed_property(UR).

%        owl2_model:dataPropertyAssertion(UR,UX,Lit),literal_value_type(Lit,Y,DT).

% ----------------------------------------
% Translation of expressions
% ----------------------------------------

% so far we only allow intersection-constructs in genus-differentia form
class_genus_differentia(C,G,DL) :-
        rdfid_oboid(UC,C),
        rdfid_oboid(UG,G),
        owl2_model:equivalent_to(UC,intersectionOf(UIL)),
        class(UC),
        select(UG,UIL,UDL),
        class(UG), % named genus only
        maplist(owlrestriction_to_oborelationship,UDL,DL).

%% owlrestriction_to_oborelationship(+Restr,?OboExpr)
owlrestriction_to_oborelationship(someValuesFrom(UR,UY),R_t=Y) :-
        rdfid_oboid(UR,R_i),
        rdfid_oboid(UY,Y),
        referenceable(UR),
        referenceable(UY),
        force_all_some(R_i,R_t).
owlrestriction_to_oborelationship(allValuesFrom(UR,UY),R_t=Y) :-
        rdfid_oboid(UR,R_i),
        rdfid_oboid(UY,Y),
        referenceable(UR),
        referenceable(UY),
        force_all_only(R_i,R_t).
owlrestriction_to_oborelationship(minCardinality(Card,UR,UY),c(min,Card,R_i,Y)) :-
        rdfid_oboid(UR,R_i),
        rdfid_oboid(UY,Y),
        referenceable(UR),
        referenceable(UY).
owlrestriction_to_oborelationship(maxCardinality(Card,UR,UY),c(max,Card,R_i,Y)) :-
        rdfid_oboid(UR,R_i),
        rdfid_oboid(UY,Y),
        referenceable(UR),
        referenceable(UY).
owlrestriction_to_oborelationship(exactCardinality(Card,UR,UY),c(exact,Card,R_i,Y)) :-
        rdfid_oboid(UR,R_i),
        rdfid_oboid(UY,Y),
        referenceable(UR),
        referenceable(UY).

owlrestriction_to_oborelationship(exactCardinality(Card,UR),RV) :-
        owlrestriction_to_oborelationship(exactCardinality(Card,UR,'bfo:Entity'),RV).

% TODO: type/instance level relation conversion
force_all_some(R,R).
force_all_only(R_i,R_t) :-
        fail,                   % TODO: make configurable
        atom_concat(R_t,'_only',R_i),
        assert_implicit_metarelation(R_t,all_only,R_i).

% TODO: allow non-named classes, auto-construct anonymous classes
:- multifile referenceable_hook/1.
referenceable(U) :-
        suppress_entity(U),
        !,
        fail.
referenceable(U) :-
        debug(owl2_ext,'?ref ~w',[U]),
        entity(U),
        !.
referenceable(U) :-
        referenceable_hook(U).



%
assert_implicit_metarelation(R_i,MR,R_t) :-
        implicit_metarelation(R_i,MR,R_t),
        !.
assert_implicit_metarelation(R_i,MR,R_t) :-
        assert(implicit_metarelation(R_i,MR,R_t)),
        !.



% -------------------- TESTS --------------------
% regression tests to ensure behaviour of module is correct;
% lines below here are not required for module functionality

unittest(test(load_owl,
            [],
            (   ensure_loaded(bio(ontol_db)),
                ensure_loaded(bio(ontol_bridge_from_owl)),
                load_bioresource(rdfs),
                load_bioresource(owl),
                load_biofile(owl,'sofa.owl'),
                class(ID,mRNA),
                class(PID,transcript),
                subclassT(ID,PID),
                class(_,exon)),
            true)).

unittest(test(genus_diff,
            [],
            (   ensure_loaded(bio(ontol_db)),
                ensure_loaded(bio(ontol_bridge_from_owl)),
                load_bioresource(rdfs),
                load_bioresource(owl),
                load_biofile(owl,'llm.owl'),
                forall(genus(ID,GID),
                       format('~w genus:~w~n',[ID,GID])),
                forall(differentium(ID,R,DID),
                       format('diff ~w == ~w ~w~n',[ID,R,DID])),
                nl),
            true)).

unittest(test(wine_test,
            [],
            (   ensure_loaded(bio(ontol_db)),
                ensure_loaded(bio(ontol_bridge_from_owl)),
                load_bioresource(rdfs),
                load_bioresource(owl),
                load_biofile(owl,'wine.owl'),
                write_biofile(obo,'wine.obo')),
            true)).

/** <module>  maps to OBO-style ontol_db model from OWL2 using Thea

  ---+ Synopsis

  ==
  :- use_module(bio(io),[load_biofile/2]).
  :- use_module(bio(ontol_db)).
  :- use_module(bio(ontol_bridge_from_owl2)).
  
  % access biopax OWL model using ontol_db predicates
  demo:-
    load_biofile(owl,'biopax-level1.owl'),
    class(ID,rna),
    format('In biopax, rna is a subclass of the following:~n',[]),
    forall(subclass(ID,PID),
           showclass(PID)).

  showclass(ID):-
    class(ID,N),
    format('Class ID:~w~nClass name:~w~n',[ID,N]).
  ==

  Command line usage:
  
  ==
  blip -i http://purl.obolibrary.org/obo/obi.owl -f thea2_owl io-convert -to ontol_db:pro
  ==

  
  ---+ Description

  * owl2_model:subClassOf/2 mapped to ontol_db:subclass/2 (for named classes)
  * owl2_model:subClassOf/2 mapped to ontol_db:restriction/3 (when 2nd argument is objectSomeValuesFrom/1)
  

  ---+ See Also

  * ontol_bridge_to_owl2.pro -- for the reverse transformation -- TODO

  
*/
