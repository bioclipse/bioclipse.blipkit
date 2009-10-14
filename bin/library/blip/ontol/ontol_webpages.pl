:- use_module(bio(ontol_db)).
:- use_module(bio(ontol_restful)).
:- use_module(bio(metadata_db)).
:- use_module(bio(dbmeta)).
:- use_module(bio(serval)).
:- use_module(bio(bioprolog_util)).



downloadbar(ID)=>
 'Download: [', downloadfmt(ID,Fmt) forall download(Fmt), ']'.

downloadfmt(ID,Fmt) =>
 call(id_url(ID,Fmt,URL)),
 a(href=URL, Fmt).

downloadfmt(ID,Fmt,Txt) =>
 call(id_url(ID,Fmt,URL)),
 a(href=URL, Txt).

hide_instance(X) :- inst_sv(X,type,_,_).

entry_page =>
 outer('OBO',
       [h2('Ontologies'),
        div(class=floatL,
            table(class='tagval_table',
                  tdpair(Ont,
                         [hlink(X),' ',
                          '[',downloadfmt(X,metadata),'] ',
                          downloadfmt(X,xps) where inst_sv(Ont,type,logical_definitions,_)
                         ]) forall_unique ont_idspace(Ont,X)))]).

mappings_entry_page =>
 outer('OBO Mappings',
       [h2('Mappings'),
        div(class=floatL,
            table(class='tagval_table',
                  tdpair(Ont,
                         [data(T) where inst_sv(Ont,type,T,_),
                          hlink(X),' ',
                          '[',downloadfmt(X,metadata),'] ',
                          downloadfmt(X,xps) where inst_sv(Ont,type,logical_definitions,_)
                         ]) forall_unique ont_idspace(Ont,X)))]).

basic(ID) =>
  outer(ID,
        span(downloadbar(ID),
%             h2('Class Information'),
	     entity_info(ID))).

multiple2(IDs) =>
 outer(IDs,
       span(downloadbar(IDs),       
	    entity_info(ID) forall_unique (member(ID,IDs)))).

entity_info(ID) =>
  div(class=floatL,
      table(class='tagval_table',
	    tdpair('ID',noesc(ID)),
	    tdpair('ID Space',hlink(X)) forall parse_id_idspace(ID,X),
	    tdpair('URL',a(href=X,X)) forall id_exturl(ID,X),
	    tdpair('Name',Name) forall metadata_db:entity_label(ID,Name),
	    tdpair('Ontology',Ont) forall_unique belongs(ID,Ont),
	    tdpair('Instance of',hlink(X)) forall_unique inst_of(ID,X),                     
	    tdpair('Subset',X) forall_unique entity_partition(ID,X),
	    tdpair('Definition',[Def,' ',
				 hlink(X) forall_unique def_xref(ID,X)]) forall_unique def(ID,Def),                     
	    tdpair('Comment',X) forall_unique entity_comment(ID,X),                     
	    tdpair('Xref',[hlink_with_id(X),
			   hlinklist([X,ID],compare) where knowsabout(X)
			  ]) forall_unique entity_xref(ID,X),                     
	    tdpair('', hlinklist([ID|Xs],'compare all')) where setof(X,(entity_xref(ID,X),knowsabout(X)),Xs),
	    tdpair(hlink(R),X) forall_unique inst_sv(ID,R,X,_),                     
	    tdpair(hlink(R),hlink(X)) forall_unique inst_rel(ID,R,X),                     
	    tdpair([i(b(X)),' Synonym'],
		   [Synonym,
		    i(' type:',b(T)) forall_unique entity_synonym_type(ID,T,Synonym)
		   ]) forall_unique synonym(ID,X,Synonym),
	    tdpair('Disjoint from',hlink(X)) forall_unique disjoint_from(ID,X),                     
	    tdpair('Domain',hlink(X)) forall_unique property_domain(ID,X),                     
	    tdpair('Range',hlink(X)) forall_unique property_range(ID,X),                     
	    tdpair('Property',X) forall_unique metaproperty(ID,X),                     
	    tdpair('Genus',hlink(X)) forall_unique genus(ID,X),                     
	    tdpair('Differentia',rel(R,X)) forall_unique differentium(ID,R,X),                     
	    tdpair('is_a',hlink(X)) forall_unique subclass(ID,X),                     
	    tdpair(hlink(R),hlink(X)) forall_unique restriction(ID,R,X),                     
	    ''),
      class_children(ID),
      div(id=what_links_here,
	  call(id_url(ID,revlinks,RevURL)),
	  call(sformat(JS,'JavaScript:replaceContents(document.getElementById(\'what_links_here\'),\'~w\');',[RevURL])),
	  html:input(type=button,
		     onClick=JS,
		     value='What links here?'))
     ),
  graphimg(ID),
  images_box(ID),
  wikipedia_info(ID,X) forall_unique id_wikipage(ID,X).

multirow(Col,Val,Goal,Var,List) =>
 tr(th(Col),
    td([Val] forall_unique [html:p]/Goal) forall member(Var,List)).

multiple(IDs) =>
 outer(IDs,
       span(downloadbar(IDs),       
	    multiple_entity_info(IDs))).

% shows each ID in its own column
multiple_entity_info(IDs) =>
  div(class=floatL,
      table(class='comparison_table',
	    multirow('ID',data(ID),true,ID,IDs),
	    multirow('Link',hlink(ID),true,ID,IDs),
	    multirow('ID Space',hlink(X),parse_id_idspace(ID,X),ID,IDs),
	    multirow('Name',Name,metadata_db:entity_label(ID,Name),ID,IDs),
	    multirow('Ontology',Ont,belongs(ID,Ont),ID,IDs),
	    multirow('Subset',X,entity_partition(ID,X),ID,IDs),
	    multirow('Definition',[Def,' ',
				   hlink(X) forall_unique def_xref(ID,X)],def(ID,Def),ID,IDs),
	    multirow('Comment',X,entity_comment(ID,X),ID,IDs),                     
	    multirow('Xref',hlink_with_id(X),entity_xref(ID,X),ID,IDs),
	    %multirow(hlink(R),X,inst_sv(ID,R,X,_),ID,IDs),                     
	    %multirow(hlink(R),X,inst_rel(ID,R,X),ID,IDs),
	    call(solutions(X,(member(ID,IDs),synonym(ID,X,_)),Xs)),
	    multirow([i(X),' synonym'],
		     [Synonym,
		      i(' type:',b(T)) forall_unique entity_synonym_type(ID,T,Synonym),
		      ' '
		     ],synonym(ID,X,Synonym),ID,IDs) forall_unique member(X,Xs),
	    multirow('Disjoint from',hlink(X),disjoint_from(ID,X),ID,IDs),
	    multirow('Domain',hlink(X),property_domain(ID,X),ID,IDs),                     
	    multirow('Range',hlink(X),property_range(ID,X),ID,IDs),                     
	    multirow('Property',X,metaproperty(ID,X),ID,IDs),                     
	    multirow('Genus',hlink(X),genus(ID,X),ID,IDs),                     
	    multirow('Differentia',rel(R,X),differentium(ID,R,X),ID,IDs),                     
	    multirow('is_a',hlink(X),subclass(ID,X),ID,IDs),
	    call(solutions(R,(member(ID,IDs),restriction(ID,R,_)),Rs)),
	    multirow(hlink(R),[hlink(X)],restriction(ID,R,X),ID,IDs) forall_unique (member(R,Rs)),
	    html:br),
      call(concat_atom(IDs,'+',IDListAtom)),
      graphimg(IDListAtom,img)).




rel(R,X) =>
  hlink(R),' ',hlink(X).


pageify(Template,Goal,MaxItems) =>
  call((solutions(Template,Goal,Items),
        length(Items,NumItems))),
  if(NumItems =< MaxItems,
     then: Items,
     else: [
            getparam_as_num(page,Page,1),
            pagebar(Page,NumItems,MaxItems),
            call((Start is (Page-1)*MaxItems,
                  End is Page*MaxItems -1)),
            Item forall ((between(Start,End,Index),
                          nth0(Index,Items,Item)))
           ]).

 

xps(ID) =>
  outer(['xps in ',ID],
        [h1('Cross product set ',hlink(ID)),
         table(tr(th('Term'),
                  th('Genus'),
                  th(colspan=2,'Differentia')),
               gdrow(X) forall_unique genus(X,_))]).

gdrow(ID) =>
  call((solutions(R-X,differentium(ID,R,X),Diffs),
        length(Diffs,NumDiffs),
        _NumRows is NumDiffs-1,
        Diffs=[R1-X1|DiffsRest])),
  tr(
     td(rowspan=NumDiffs,hlink(ID)),
     td(rowspan=NumDiffs,hlink(X) forall_unique genus(ID,X)),
     td(hlink(R1)),
     td(hlink(X1))),
  tr(td(''),td(''),td(hlink(R)),td(hlink(X))) forall_unique member(R-X,DiffsRest).

basic_search_form =>
  getparam(search_term,Val,''),
  form(input(type=textfield,
             name=search_term,
             value=Val),
       input(name=submit,type=submit,value=search)).

ontology(Ont) =>
  outer(Ont,
        [h1(hlink(Ont)),
         basic_search_form,
         h3('Fetch: ',downloadfmt(Ont,metadata)),
         table(basicrow(ID) forall class(ID),
               basicrow(ID) forall property(ID),
               basicrow(ID) forall (inst(ID),entity_label(ID,_))
              )
        ]).
%        [ul(li(hlink(X)) forall class(X))]).

ontology_filtered(Ont,S,L) =>
  outer(Ont,
        [h1(hlink(Ont),' filter:',S),
         basic_search_form,
         h3('Fetch: ',downloadfmt(Ont,metadata)),
         table(basicrow(X) forall member(X,L))]).

ontology_query(Ont,Query,Results) =>
  outer([Ont,' ',Query],
        [h1(hlink(Ont),' query'),
         div(class=queryForm,
             form(p('Query:'),textarea(name=query,rows=10,cols=64,[Query]),
                  p('Select:'),textarea(name=select,rows=1,cols=32,[]),
                  input(name=submit,type=submit,value=query))),
         div(class=queryOutput,
             h3('Query results:'),
             p(Query),
             table(query_result_row(X) forall member(X,Results)))]).

query_result_row(Result) =>
  if(Result=..[Pred|Args],
     then: tr(td(data(Pred)),
              td(query_result_colval(X)) forall member(X,Args)),
     else: if(atom(Result),
              then: td(td(query_result_colval(Result))),
              else: td(td(data(Result))))).

query_result_colval(X) =>
 if((atom(X),concat_atom([_,_],':',X)),
    then: hlink(X),
    else: data(X)).

noresults(Ont,S) =>
  outer(Ont,
        [h1(hlink(Ont),' filter:',S),
         basic_search_form,
         h2('Your search produced no results')]).

basicrow(ID) =>
  tr(td(hlink(ID)),
     td(data(X) forall_unique def(ID,X))).


ontology_table(S) =>
  outer(['IDSpace ',S],
        [h2(hlink(S)),
         table(tr(td(hlink(ID)),
                  td(data(X) forall_unique entity_synonym(ID,X)),
                  td(data(X) forall_unique def(ID,X)))
              forall class(ID))]).

ontology_statements(Ont) =>
  outer(Ont,
        [h1(hlink(Ont)),
         h3('Fetch: ',downloadfmt(Ont,metadata)),
         table(tr(td(hlink(X)),
                  th(is_a),
                  td(hlink(Y))) forall_unique subclass(X,Y),
               tr(td(hlink(X)),
                  th(hlink(R)),
                  td(hlink(Y))) forall_unique restriction(X,R,Y),
               tr(td(hlink(X)),
                  th(xref),
                  td(hlink(Y))) forall_unique entity_xref(X,Y))
        ]).

ontology_relationships(Ont,R) =>
  outer(Ont,
        [h1(hlink(Ont)),
         h3('Fetch: ',downloadfmt(Ont,metadata)),
         table(tr(td(hlink(X)),
                  th(hlink(R)),
                  td(hlink(Y))) forall_unique parent(X,R,Y))
        ]).


ontology_metadata(S) =>
  outer(['Metadata for: ',S],
        [
         h2(hlink(S)),
         [h3(Ont),
          table(class='tagval_table',
                tdpair(R,X) forall_unique inst_sv(Ont,R,X))
         ] forall ont_idspace(Ont,S),
         h3('Derived Metadata:'),
         table(class='tagval_table',
               tdpair('Terms', N) where setof_count(X,class(X),N),
               tdpair('Obsolete Terms', N) where setof_count(X,obsolete_class(X,_),N),
               tdpair('Terms with definitions', N) where setof_count(X,(class(X),def(X,_)),N),
               tdpair('Terms with logical definitions', N) where setof_count(X,(class(X),genus(X,_)),N),
               tdpair('Relationships', N) where setof_count(X-R-Y,
                                                             parent(X,R,Y),
                                                             N),
               ntdpair('Differentia', N) where setof_count(X-R-Y,
                                                           differentium(X,R,Y),
                                                           N),
%               if( (solutions(XO,(parent(X,Y),belongs(X,XO),belongs(Y,YO),XO\=YO),XOs),XOs=[_,_|_]),
%                   then: tdpair(rels,table(
%                                           tr( t
               %ntdpair([i(R),' differentia'], N) forall_unique (property(R),setof_count(X-Y,differentium(X,R,Y),N)),
               ntdpair([pagelink([relationships,S,R],R),' relationships'], N) forall_unique ((R=subclass;property(R)),setof_count(X-Y,parent(X,R,Y),N)))
        ]).

what_links_here_table(ID) =>
  table(class='tagval_table',

        th(hlink(ID)),html:td,html:td,td('Source'),
        fwdlink(ID,'Xref',hlink(X),entity_xref(ID,X)),                     
        fwdlink(ID,hlink(R),X, inst_rel(ID,R,X)),                     
        fwdlink(ID,'Domain',hlink(X), property_domain(ID,X)),                     
        fwdlink(ID,'Range',hlink(X), property_range(ID,X)),                     
        fwdlink(ID,'Genus',hlink(X), genus(ID,X)),                     
        fwdlink(ID,'Differentium',rel(R,X), differentium(ID,R,X)),                     
        fwdlink(ID,'is_a',hlink(X), subclass(ID,X)),                     
        fwdlink(ID,hlink(R),hlink(X), restriction(ID,R,X)),

        html:td,html:td,th(hlink(ID)),td('Source'),
        revlink('Xref',hlink(X),entity_xref(X,ID)),                     
        revlink(hlink(R),X, inst_rel(X,R,ID)),                     
        revlink('Domain',hlink(X), property_domain(X,ID)),                     
        revlink('Range',hlink(X), property_range(X,ID)),                     
        revlink('Genus',hlink(X), genus(X,ID)),                     
        revlink('Differentium',rel(R,X), differentium(X,R,ID)),                     
        revlink('is_a',hlink(X), subclass(X,ID)),                     
        revlink(hlink(R),hlink(X), restriction(X,R,ID)),
        

        %invtdpair('Xref',hlink(X)) forall_unique entity_xref(X,ID),                     
        %invtdpair(hlink(R),X) forall_unique inst_rel(X,R,ID),                     
        %invtdpair('Domain',hlink(X)) forall_unique property_domain(X,ID),                     
        %invtdpair('Range',hlink(X)) forall_unique property_range(X,ID),                     
        %invtdpair('Genus',hlink(X)) forall_unique genus(X,ID),                     
        %invtdpair('Differentium',rel(R,X)) forall_unique differentium(X,R,ID),                     
        %invtdpair('is_a',hlink(X)) forall_unique subclass(X,ID),                     
        %invtdpair(hlink(R),hlink(X)) forall_unique restriction(X,R,ID),
        '').

revlink(Prop,Val,Goal) =>
  tr(
     td(Val),
     th(Prop),
     th('"'),
     td(hlink(Source)) forall_unique fact_clausesource(Goal,Source))
  forall_unique Goal.

fwdlink(ID,Prop,Val,Goal) =>
  tr(
     th('"'),
     th(Prop),
     td(Val),
     td(hlink(Source),
        ' ',
        hlink(ID,Source)
        ) forall_unique fact_clausesource(Goal,Source))
  forall_unique Goal.

wikipedia_info(_ID,Page) =>
 call(ensure_loaded(bio(web_fetch_wikipedia))),
 call(sformat(EditURL,'http://en.wikipedia.org/w/index.php?title=~w&action=edit',[Page])),
 div(id=wikipedia,
     h3('Wikipedia'),a(href=EditURL,'Edit wikipedia entry'),html:br,
     div(id=wpData,class=controlTabContent,
	 noesc(Body) forall (        format(user_error,'Fetching ~w~n',[Page]),
				     web_search_wikipedia(Page,Results,[]),
				     member(Body,Results))),
     noesc('<!-- The code to extract wikipedia entries was kindly provided by the Rfam group -->')).

images_box(ID) =>
 div(id=images,
     img(src=URL,'') forall id_imgurl(ID,URL)).

graphimg(ID) =>
 graphimg(ID,floatR).

graphimg(ID,CssClass) =>
 in(Params,call(params_hidden(Params,Hidden))),
 call(sformat(ImgUrl,'/obo/~w.png?~w',[ID,Hidden])),
 %call(sformat(ImgUrlAll,'/obo/~w.png?rel=all',[ID])),
 call(solutions(R,restriction(_,R,_),Rs)),
 in(Params,call(params_drels_crels(Params,DRels,CRels))),
    span(class=CssClass,
      img(id=main_img,
          src=ImgUrl),
      html:br,
      a(id=imgform_toggler,
        href='#',
        onClick='toggleTable(\'imgform\',\'Show graph config panel\',\'Hide\');return false;',
        'Show graph config panel'),
      form(id=imgform,
           style='display:none',
           table(class=small,
                 tr(th('show?'),th(relation),th('contain?')),
                 tr(td(checkbox(rel,R,(member(R,DRels);DRels=[];DRels=[all]))),
                    td(hlink(R)),
                    td(checkbox(cr,R,member(R,CRels)))) forall_unique member(R,Rs),
                 tr(td(''),
                    td(i('is_a')),
                    td(checkbox(cr,subclass,member(subclass,CRels))))),
           call(sformat(JS,'JavaScript:fetch_graph_image(\'~w\',document.forms.imgform);',ImgUrl)),
           html:input(type=button,
                      onClick=JS,
                      value='Redraw'),
           call(sformat(JSAll,'JavaScript:fetch_graph_image_all_relations(\'~w\');',ImgUrl)),
           html:input(type=button,
                      onClick=JSAll,
                      value='Show All'))
           %a(href=ImgURLAll,'Show all'))
     ).

class_parents(ID) =>
  ul(li(hlink(R),' ',hlink(X)) forall_unique parent(ID,R,X)).
class_children(ID) =>
  ul(li(hlink(R),'[rev] ',hlink(X)) forall_unique parent(X,R,ID)).

pagelink(L,N) =>
 in(Params,
    [call((concat_atom(L,'/',X),
          id_params_url(X,Params,URL))),
     a(href=URL,N)]).

hlink(X) =>
 if(parse_id_idspace(X,'Image',Local),
    then:a(href=Local,img(height=80,src=Local)),
    else: in(Params,
             [call(id_params_url(X,Params,URL)),
              a(href=URL,if(entity_label(X,Label),then:Label,else:X))
             ])).

hlink_with_id(X) =>
 if(parse_id_idspace(X,'Image',Local),
    then:a(href=Local,img(height=80,src=Local)),
    else: in(Params,
             [call(id_params_url(X,Params,URL)),
              a(href=URL,if(entity_label(X,Label),then:[X,' ',Label],else:X))
             ])).

hlink(X,Context) =>
 in(Params,
    [call(id_params_url(X,Params,URL,Context)),
     i(a(href=URL,'view in context'))
    ]).

%hlink(X) =>
% call(id_url(X,URL)),
% a(href=URL,if(entity_label(X,Label),then:Label,else:X)).

hlinklist(Xs,Title) =>
 call(concat_atom(Xs,'+',X)),
 call(id_url(X,URL)),
 a(href=URL,Title).

help_page =>
 outer('OBO Browser Documentation',
       div(h2('OBO Browser Documentation'),
           p('This is an experimental browser for OBO ontologies'))).

javascript('http://yui.yahooapis.com/2.3.1/build/yahoo-dom-event/yahoo-dom-event.js').
javascript('http://amigo.geneontology.org/amigo/js/all.js').
javascript('/amigo2/js/obo.js').
javascript('/amigo2/js/dojo.js').

css('#front-nav ul { margin: 0 }
   #front-nav li { background: #e9effa; color: #3875D7; margin: 1em 200px; border: 1px dotted #006; text-align: center; }
   #front-nav .h1 { font: 3em/1.0 "trebuchet ms", "lucida grande", arial, sans-serif; padding: 1em 0; }
   #front-nav a { border: none; display: block; padding: 1em; }
   #front-nav fieldset { color: #000; }
   #front-nav legend { display: inline; }').

%pagelink(search,'Search','Advanced search').
pagelink('/obo/','Ontologies','All ontologies').
pagelink('/obo/help','Help','Documentation').

download(obo).
download(obox).
download(owl).
download(chado).
download(pro).
download(json).
download(png).

outer(N,P) =>
 doc:'wraps HTML in main template; this is the main look and feel template',
 html:html(
           head(title(N),
                html:meta('http-equiv'='content-type', content='text/html; charset=utf-8',
                          html:meta(name=html_url, content='http://amigo.geneontology.org/amigo',
                                    %link(href='http://amigo.geneontology.org/amigo/css/formatting.css', rel=stylesheet, type='text/css'),
                                    link(href='/amigo2/css/formatting.css', rel=stylesheet, type='text/css'),
                                    link(href='http://rfam.sanger.ac.uk/static/css/wp.css', rel=stylesheet, type='text/css'),
				    script(type='text/javascript', src=X) forall_unique javascript(X),
				    html:style(type='text/css',CSS) forall_unique css(CSS)
				   ))),
           
           html:body(div(id=header, a(class='logo floatR', href='search.cgi',
                                      img(src='http://amigo.geneontology.org/amigo/images/logo-sm.png', alt='AmiGO logo', title='AmiGO front page')),
                         h1(id=top, a(href='http://www.obofoundry.org/', title='OBO Foundry website', 'the OBO Foundry'))),
                     
                     div(id=searchbar,
                         ul(id=menuToggle,
                            li(a(href=Link,title=LinkTitle,Text)) forall pagelink(Link,LinkTitle,Text))),

                     div(class=contents,
                         P),
                     div(id=footer,
                              html:font(size='-2','--  --'))
                    )).




% ========================================
% utility (general)
% ========================================

tdpair(Tag,Val) =>
 doc:'amigo style tag:val in table list',
 html:tr(html:th(Tag),html:td(Val)).
invtdpair(Tag,Val) =>
 doc:'amigo style tag:val in table list',
 html:tr(html:td(Val),html:th(Tag)).
ntdpair(Tag,Val) =>
 doc:'amigo style tag:val in table list',
 if(Val>0,html:tr(html:th(Tag),html:td(Val))).

checkbox(Name,Val) => checkbox(Name,Val,(1=0)).
checkbox(Name,Val,Expr) =>
 if(Expr,
    then: html:input(type=checkbox,name=Name,value=Val,checked=on),
    else: html:input(type=checkbox,name=Name,value=Val)).
