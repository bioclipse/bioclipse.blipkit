/* -*- Mode: Prolog -*- */

:- module(ontol_writer_dot,[
                            edges_to_dot/3,
                            edges_to_display/2,
                            write_edges_to_image/2,
                            write_edges_via_dot/3
                           ]).
:- use_module(bio(ontol_writer_text),[rcode/3,rcode_info/2,class_label_by_xp/2]).
:- use_module(bio(metadata_db)).
:- use_module(bio(ontol_db)).
:- use_module(bio(graphviz)).
:- use_module(bio(bioprolog_util)).

:- multifile user:image_display_exec/1.
:- dynamic user:image_display_exec/1.

:- multifile user:graphviz_ontol_param/2.
%:- dynamic user:graphviz_ontol_param/2.
:- multifile user:graphviz_ontol_param/3.
% todo - move to conf file

node_shape(ID,box):- class(ID),!.
node_shape(_,oval).

user:graphviz_ontol_param(Template,Param,_):- 
        user:graphviz_ontol_param(Template,Param).

user:graphviz_ontol_param(edge(_,_,R,Via),label=ELab):-
        rcode_info(Via,Info),
        (   entity_label(R,RLabel) -> true ; RLabel=R),
        sformat(ELab,'~w ~w',[RLabel,Info]).
user:graphviz_ontol_param(edge(A,B,R,_),label=ELab):-
        range_cardinality_restriction(A,R,Card,B),
        Card\=1-inf,
        sformat(ELab,'~w [~w]',[R,Card]).
user:graphviz_ontol_param(node(ID),label=N):- entity_label(ID,N).
user:graphviz_ontol_param(node(Node),label=Label):-
        is_anonymous(Node),
        class_label_by_xp(Node,Label).

% see http://www.graphviz.org/doc/info/attrs.html
%user:graphviz_ontol_param(graph,prop(style=filled)).
%user:graphviz_ontol_param(node(_),fillcolor=red).
user:graphviz_ontol_param(node(ID),shape=Shape):- node_shape(ID,Shape).
user:graphviz_ontol_param(node(_),fontname=helvetica).
%user:graphviz_ontol_param(node(_),fontname='/System/Library/Fonts/Courier.dfont'). % OS X only!!
user:graphviz_ontol_param(node(_),fontsize=14).
%user:graphviz_ontol_param(edge(_,_,_,_),weight=100).
user:graphviz_ontol_param(edge(_,_,is_a,_),arrowhead=empty).
user:graphviz_ontol_param(edge(_,_,is_a,_),color=green).
user:graphviz_ontol_param(edge(_,_,po,_),color=blue).
user:graphviz_ontol_param(edge(_,_,integral_part_of,_),arrowtail=ediamond).
user:graphviz_ontol_param(edge(_,_,integral_part_of,_),color=blue).
user:graphviz_ontol_param(edge(_,_,only_part_of,_),arrowhead=empty).
user:graphviz_ontol_param(edge(_,_,only_part_of,_),arrowtail=ediamond).
user:graphviz_ontol_param(edge(_,_,only_part_of,_),color=blue).
user:graphviz_ontol_param(edge(_,_,has_part,_),arrowhead=ediamond).
user:graphviz_ontol_param(edge(_,_,has_part,_),color=blue).
user:graphviz_ontol_param(edge(_,_,df,_),arrowhead=open).
user:graphviz_ontol_param(edge(_,_,df,_),color=red).
user:graphviz_ontol_param(edge(_,_,followed_by,_),color=red).
user:graphviz_ontol_param(edge(_,_,xref,_),color=grey).
user:graphviz_ontol_param(edge(_,_,xref,_),weight=1000).
user:graphviz_ontol_param(edge(_,_,xref,_),arrowhead=open).
user:graphviz_ontol_param(edge(_,_,'OBO_REL:results_in_complete_development_of',_),color=grey).
user:graphviz_ontol_param(edge(_,_,'OBO_REL:homologous_to',_),color=grey).
%user:graphviz_ontol_param(edge(_,_,_,_),fontname='/System/Library/Fonts/Times.dfont'). % OS X only!!

dotpath(Dot):-
        (   expand_file_search_path(path_to_dot(dot),Dot)
        ->  true
        ;   Dot=dot).

edges_to_display(Edges,Opts):-
        dotpath(DotPath),
        Fmt=png,
        tmp_file(Fmt,File),
        tmp_file(dot,DotFile),
	debug(dot,'writing temp dot file: ~w',[DotFile]),
        tell(DotFile),
        edges_to_dot(Edges,Dot,Opts),
        write(Dot),
        told,
        sformat(Cmd,'~w -o ~w.~w -T~w ~w',[DotPath,File,Fmt,Fmt,DotFile]),
	debug(dot,'cmd: ~w',[Cmd]),
        shell(Cmd),
	(   user:image_display_exec(DispProg)
	->  true
	;   DispProg=open),
        sformat(DispCmd,'~w ~w.~w',[DispProg,File,Fmt]),
	debug(dot,'display cmd: ~w',[DispCmd]),
        (  shell(DispCmd)
	-> true
	;  format(user_error,'Cannot execute: ~w~nTry setting user:image_display_exec~n',[Cmd])).	   
	

write_edges_to_image(Edges,Opts):-
        dotpath(DotPath),
        Fmt=png,
        tmp_file(dot,DotFile),
        tell(DotFile),
        edges_to_dot(Edges,Dot,Opts),
        write(Dot),
        told,
        sformat(Cmd,'~w -T~w ~w',[DotPath,Fmt,DotFile]),
        shell(Cmd).


write_edges_via_dot(Fmt,Edges,PathStem):-
        dotpath(DotPath),
        edges_to_dot(Edges,Dot,[]),
        sformat(PathToDotFile,'~w.dot',[PathStem]),
        sformat(PathToImg,'~w.~w',[PathStem,Fmt]),
        open(PathToDotFile,write,DotIO,[]),
        write(DotIO,Dot),
        close(DotIO),
        sformat(Cmd,'~w -T~w ~w > ~w',[DotPath,Fmt,PathToDotFile,PathToImg]),
        shell(Cmd).





% TOOD: this would be more elegant as a DCG
edges_to_dot(Edges,Dot,Opts):-
        ensure_loaded(bio(graphviz)),
        solutions(ID,(   member(edge(_,ID,_),Edges)
                     ;   member(edge(ID,_,_),Edges)),IDs),
        edges_to_dot(Edges,Dot,IDs,Opts).

edges_to_dot(Edges,Dot,IDs,Opts):-
        member(containment_relations([_|_]),Opts),
        !,
        edges_to_dot_new(Edges,Dot,IDs,Opts).

edges_to_dot(Edges,Dot,IDs,Opts):-
        (   member(cluster_pred(Goal,X,Cluster),Opts)
        ->  findall(X-Cluster,(member(X,IDs),Goal),XClusterPairs),
            solutions(Cluster,member(_-Cluster,XClusterPairs),Clusters),
            findall(nodeset(Cluster,Cluster,Terms),
                    (   member(Cluster,Clusters),
                        findall(Term,
                                (   member(ID-Cluster,XClusterPairs),
                                    findall(Param,user:graphviz_ontol_param(node(ID),Param,Edges),NodeParams),
                                    Term=node(ID,NodeParams)),
                                Terms)),
                    NodeTermsL)
        ;   findall(Term,
                    (   member(ID,IDs),
                        findall(Param,user:graphviz_ontol_param(node(ID),Param,Edges),NodeParams),
                        Term=node(ID,NodeParams)),
                    NodeTermsL)),
        findall(Terms,
                (   member(ID,IDs),
                    findall(edge(ID,PID,EdgeParams),
                            (   member(edge(ID,PID,RPred),Edges),
                                rcode(RPred,Code,Via),
                                findall(Param,user:graphviz_ontol_param(edge(ID,PID,Code,Via),Param,Edges),EdgeParams)),
                            Terms)),
                EdgeTermsL),
        flatten([NodeTermsL,EdgeTermsL],AllTerms),
        Style=[prop(style=filled)],
        graph_to_dot(graph(g,[Style|AllTerms]),Dot),
        !.

% this uses the new dotwriter module, and implements containment relations
edges_to_dot_new(Edges,Dot,IDs,Opts):-
        ensure_loaded(bio(dotwriter)),
        member(containment_relations(CMRs),Opts),
        debug(dot,'edges= ~w',[Edges]),
        solutions(R,member(edge(_,_,R),Edges),Rs),
        debug(dot,'containment relations= ~w',[Rs]),
        /*
        findall(A-B,(member(edge(A,B,Pred),Edges), % TODO
                     (   Pred=relation_link(R)
                     ;   Pred=parent_over_oneof(R-_)),
                     member(R,CMRs)),NestPairs),
          */
        /*
        findall(A-B,(member(edge(A,B,_),Edges), % TODO
                     %parent(A,R,B),
                     parent_over_nr(R,A,B),
                     member(R,CMRs)),NestPairs),
          */
        findall(A-B,(member(A,IDs),
                     member(B,IDs),
                     A\=B,
                     member(R,CMRs),
                     (   parent_over_nr(R,A,B)
                     ;   (   R=genus, % todo: any intersection element?
                             genus(A,B)))
                    ),NestPairs),
        debug(dot,'nps= ~w',[NestPairs]),
        findall(Term,
                (   member(ID,IDs),
                    findall(Param,user:graphviz_ontol_param(node(ID),Param,Edges),NodeParams),
                    Term=node(ID,NodeParams)),
                NodeTerms),
        findall(edge(ID,PID,EdgeParams),
                (   member(edge(ID,PID,RPred),Edges),
                    rcode(RPred,Code,Via),
                    findall(Param,user:graphviz_ontol_param(edge(ID,PID,Code,Via),Param,Edges),EdgeParams)),
                EdgeTerms),
        flatten([NodeTerms,EdgeTerms],AllTerms),
        G=graph(g,[],AllTerms),
        graph_nest_pairs(G,GX,NestPairs),
        graph_to_dot_atom(GX,Dot),
        !.

        
        
/*
% advanced/experimental
% compound graphs - treat some classes as clusters.
% must be disjoint over cluster rel
% in future, with a higher level graph language, will this be necessary?
edges_to_dot_compound(Edges,Dot,IDs,Opts):-

        solutions(R,member(containment_relation(R),Opts),CMRs),
        
        % unify CLusterIDs with set of nodes that must be drawn as
        % clusters by virtue of having children of the designated type.
        % for example, if we nest boxes according to subclass, then
        % any node with a subclass child (in the subgraph) must be
        % drawn as a cluster
        solutions(PID,( member(edge(ID,PID,R),Edges),
                        member(R,CMRs)),
                  Clusters),
        solutions(ID-Cluster,( member(Cluster,Clusters),
                               edge(ID,Cluster,R),
                               member(R,CMRs)),
                  IDClusterPairs),

        % generate clusters, plus the nodes within them
        findall(nodeset(Cluster,Cluster,Terms),
                (   member(Cluster,Clusters),
                    findall(Term,
                            (   member(edge(ID,Cluster,R),Edges),
                                member(R,CMRs),
                                findall(Param,user:graphviz_ontol_param(node(ID),Param,Edges),NodeParams),
                                Term=node(ID,NodeParams)),
                                Terms)),
                ClusterTermsL),

        % all nodes not belonging to clusters
        findall(Term,
                (   member(ID,IDs),
                    \+ member(ID-_,IDClusterPairs),
                    findall(Param,user:graphviz_ontol_param(node(ID),Param,Edges),NodeParams),
                    Term=node(ID,NodeParams)),
                NodeTermsL),

        % all edges: between n x n, n x c, c x c
        findall(Terms,
                (   member(ID,IDs),
                    findall(EdgeTerm,
                            (   member(edge(ID,PID,RPred),Edges),
                                rcode(RPred,Code,Via),
                                cluster_edgeterm(ID,PID,RPred,IDClusterPairs,EdgeTerm)),
                            Terms)),
                EdgeTermsL),
        flatten([ClusterTermsL,NodeTermsL,EdgeTermsL],AllTerms),
        Style=[prop(style=filled),prop(compound=true)],
        graph_to_dot(graph(g,[Style|AllTerms]),Dot),
        !.

%edge_cluster_attrs(ID,PID,IDClusterPairs,EdgeParams,[EdgeParams)

% cluster to cluster
cluster_edgeterm(ID,PID,RPred,IDClusterPairs,EdgeTerm):-
        member(-ID,IDClusterPairs),
        member(-PID,IDClusterPairs),
        !,
        EdgeTerm=edge(ID,PID,EdgeParams),
        findall(Param,user:graphviz_ontol_param(edge(ID,PID,Code,Via),Param,Edges),EdgeParams1),
        edge_cluster_attrs(ID,PID,IDClusterPairs,EdgeParams1,EdgeParams)),
*/

        

/** <module>   
  @author Chris Mungall
  @version  $Revision: 1.2 $
  @date  $Date: 2006/03/18 04:00:47 $
  @license LGPL

  */
