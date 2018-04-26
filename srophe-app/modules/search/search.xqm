xquery version "3.0";        
 
module namespace search="http://syriaca.org/search";
import module namespace data="http://syriaca.org/data" at "../lib/data.xqm";
import module namespace page="http://syriaca.org/page" at "../lib/paging.xqm";
import module namespace rel="http://syriaca.org/related" at "../lib/get-related.xqm";
import module namespace facet="http://expath.org/ns/facet" at "../lib/facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "../facet-defs.xqm";
import module namespace maps="http://syriaca.org/maps" at "../lib/maps.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "../content-negotiation/tei2html.xqm";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
(: Search modules :)
import module namespace places="http://syriaca.org/places" at "places-search.xqm";

import module namespace functx="http://www.functx.com";
import module namespace templates="http://exist-db.org/xquery/templates" ;

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ 
 : Shared global parameters for building search paging function
:)
declare variable $search:q {request:get-parameter('q', '') cast as xs:string};
declare variable $search:persName {request:get-parameter('persName', '') cast as xs:string};
declare variable $search:placeName {request:get-parameter('placeName', '') cast as xs:string};
declare variable $search:title {request:get-parameter('title', '') cast as xs:string};
declare variable $search:bibl {request:get-parameter('bibl', '') cast as xs:string};
declare variable $search:idno {request:get-parameter('uri', '') cast as xs:string};
declare variable $search:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $search:sort-element {request:get-parameter('sort-element', '') cast as xs:string};
declare variable $search:perpage {request:get-parameter('perpage', 20) cast as xs:integer};
declare variable $search:collection {request:get-parameter('collection', '') cast as xs:string};

(:~
 : Builds search string and evaluates string.
 : Search stored in map for use by other functions
 : @param $collection passed from search page templates to build correct sub-collection search string
:)
declare %templates:wrap function search:get-results($node as node(), $model as map(*), $collection as xs:string?, $view as xs:string?){
    let $coll := if($search:collection != '') then $search:collection else $collection
    let $eval-string := search:query-string($collection)
    let $hits := data:search($eval-string)
    let $path := concat("$hits",facet:facet-filter(facet-defs:facet-definition($collection)))
    return map {"hits" := util:eval($path) }  
};

(: for debugging :)
declare function search:search-xpath($collection as xs:string?){
   let $coll := if($search:collection != '') then $search:collection else $collection
   return search:query-string($collection)                    
};

(:~   
 : Builds general search string from main syriaca.org page and search api.
:)
declare function search:query-string($collection as xs:string?) as xs:string?{
let $search-config := concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/','search-config.xml')
return
if($collection != '') then 
    if(doc-available($search-config)) then 
       concat("collection('",$global:data-root,"/",$collection,"')//tei:body",search:dynamic-paths($search-config))
    else
        concat("collection('",$global:data-root,"/",$collection,"')//tei:body",
        data:keyword(),
        search:persName(),
        search:placeName(), 
        search:title(),
        search:bibl(),
        data:uri()
      )
else 
concat("collection('",$global:data-root,"')//tei:body",
    data:keyword(),
    search:persName(),
    search:placeName(), 
    search:title(),
    search:bibl(),
    data:uri()
    )
};

declare function search:dynamic-paths($search-config as xs:string?){
    let $config := if(doc-available($search-config)) then doc($search-config) else ()
    let $params := request:get-parameter-names()
    return string-join(
    for $p in $params
    return 
        if($p = 'q') then
            concat("[ft:query(.,'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
        else 
           for $field in $config//input[@name = $p]
           return 
                if(request:get-parameter($p, '') != '') then
                       if(string($field/@element) = '.') then
                            concat("[ft:query(",string($field/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")
                        else concat("[ft:query(.//",string($field/@element),",'",data:clean-string(request:get-parameter($p, '')),"',data:search-options())]")    
                    else (),'')
};

declare function search:persName(){
    if($search:persName != '') then 
        data:element-search('persName',$search:persName) 
    else '' 
};

declare function search:placeName(){
    if($search:placeName != '') then 
        data:element-search('placeName',$search:placeName) 
    else '' 
};

declare function search:title(){
    if($search:title != '') then 
        data:element-search('title',$search:title) 
    else '' 
};

declare function search:bibl(){
    if($search:bibl != '') then  
        let $terms := data:clean-string($search:bibl)
        let $ids := 
            if(matches($search:bibl,'^http://syriaca.org/')) then
                normalize-space($search:bibl)
            else 
                string-join(distinct-values(
                for $r in collection($global:data-root || '/bibl')//tei:body[ft:query(.,$terms, data:search-options())]/ancestor::tei:TEI/descendant::tei:publicationStmt/tei:idno[starts-with(.,'http://syriaca.org')][1]
                return concat(substring-before($r,'/tei'),'(\s|$)')),'|')
        return concat("[descendant::tei:bibl/tei:ptr[@target[matches(.,'",$ids,"')]]]")
    else ()
       (: data:element-search('bibl',$search:bibl):)  
};

(: NOTE add additional idno locations, ptr/@target @ref, others? :)
declare function search:idno(){
    if($search:idno != '') then 
         (:concat("[ft:query(descendant::tei:idno, '&quot;",$search:idno,"&quot;')]"):)
         concat("[.//tei:idno = '",$search:idno,"']")
    else () 
};

declare function search:search-string(){
<span xmlns="http://www.w3.org/1999/xhtml">
{(
    let $parameters :=  request:get-parameter-names()
    for  $parameter in $parameters
    return 
        if(request:get-parameter($parameter, '') != '') then
            if($parameter = 'start' or $parameter = 'sort-element' or $parameter = 'fq') then ()
            else if($parameter = 'q') then 
                (<span class="param">Keyword: </span>,<span class="match">{$search:q}&#160;</span>)
            else (<span class="param">{replace(concat(upper-case(substring($parameter,1,1)),substring($parameter,2)),'-',' ')}: </span>,<span class="match">{request:get-parameter($parameter, '')}&#160; </span>)    
        else ())
        }
</span>
};

(:~
 : Display search string in browser friendly format for search results page
 : @param $collection passed from search page templates
:)
declare function search:search-string($collection as xs:string?){
 search:search-string()
};

(:~ 
 : Count total hits
:)
declare  %templates:wrap function search:hit-count($node as node()*, $model as map(*)) {
    count($model("hits"))
};

(:~
 : Build paging for search results pages
 : If 0 results show search form
:)
declare  %templates:wrap function search:pageination($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?, $sort-options as xs:string*){
   if($view = 'all') then 
        page:pages($model("hits"), $search:start, $search:perpage, '', $sort-options)
   else if(exists(request:get-parameter-names())) then 
        page:pages($model("hits"), $search:start, $search:perpage, search:search-string($collection), $sort-options)
   else ()
};

(:~
 : Build Map view of search results with coordinates
 : @param $node search resuls with coords
:)
declare function search:build-geojson($node as node()*, $model as map(*)){
let $data := $model("hits")
let $geo-hits := $data/descendant::tei:geo
return
    if(count($geo-hits) gt 0) then
         (
         maps:build-map($data[descendant::tei:geo], count($data[descendant::tei:geo])),
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>,
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>)
    else ()         
};

(:~
 : Calls advanced search forms from sub-collection search modules
 : @param $collection
:)
declare %templates:wrap  function search:show-form($node as node()*, $model as map(*), $collection as xs:string?) {   
    if(exists(request:get-parameter-names())) then ''
    else <div>{search:search-form($collection)}</div>
};

declare function search:show-rec($hit, $p, $collection){
    <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
            <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">
                <span class="badge" style="margin-right:1em;">
                    {
                        if(request:get-parameter('relId', '') != '' and request:get-parameter('showPart', '') = 'true') then
                            string($hit/descendant::tei:relation[@passive[matches(.,request:get-parameter('relId', ''))]][1]/tei:desc[1]/tei:label[@type='order'][1]/@n)
                        else $search:start + $p - 1
                    }
                </span>
             </div>
            <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                { tei2html:summary-view($hit, (), $hit/descendant::tei:idno[1]) }
            </div>
    </div>                   
};

declare function search:display-map($node as node()*, $model as map(*), $collection as xs:string?) {
    <div xmlns="http://www.w3.org/1999/xhtml">{search:build-geojson($node,$model)}</div>
};

declare function search:display-facets($node as node()*, $model as map(*), $collection as xs:string?) {
<div xmlns="http://www.w3.org/1999/xhtml">
    <h2>Browse by</h2>
    <div >{facet:html-list-facets-as-buttons(facet:count($model("hits"), facet-defs:facet-definition($collection)/facet:facet-definition))}</div>
</div>    
};

(:~ 
 : Builds results output
:)
declare 
    %templates:default("start", 1)
function search:show-hits($node as node()*, $model as map(*), $collection as xs:string?) {
<div class="indent" id="search-results" xmlns="http://www.w3.org/1999/xhtml">
    {
            let $hits := $model("hits")
            for $hit at $p in subsequence($hits, $search:start, $search:perpage)
            let $id := replace($hit/descendant::tei:idno[1],'/tei','')
            return 
             <div class="row record" xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em">
                 <div class="col-md-1" style="margin-right:-1em; padding-top:.25em;">        
                     <span class="badge" style="margin-right:1em;">{$search:start + $p - 1}</span>
                 </div>
                 <div class="col-md-11" style="margin-right:-1em; padding-top:.25em;">
                     {tei2html:summary-view(root($hit), '', $id)}
                 </div>
             </div>   
   } 
</div>
};

(:~          
 : Checks to see if there are any parameters in the URL, if yes, runs search, if no displays search form. 
 : NOTE: could add view param to show all for faceted browsing? 
:)
declare %templates:wrap function search:build-page($node as node()*, $model as map(*), $collection as xs:string?, $view as xs:string?) {
    if(exists(request:get-parameter-names()) or ($view = 'all')) then search:show-hits($node, $model, $collection)
    else ()
};

(:~
 : Builds advanced search form
 :)
declare function search:search-form($collection) {  
let $search-config := concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/','search-config.xml')
return 
    if(doc-available($search-config)) then 
        search:build-form($search-config) 
    else search:default-search-form()
};

declare function search:build-form($search-config){
let $config := if(doc-available($search-config)) then doc($search-config) else ()
return 
<form method="get" action="search.html" xmlns:xi="http://www.w3.org/2001/XInclude"  class="form-horizontal indent" role="form">
    <h1 class="search-header">{if($config//label != '') then $config//label else 'Search'}</h1>
    {if($config//desc != '') then 
        <p class="indent">{$config//desc}</p>
    else() 
    }
    <div class="well well-small">
        <div class="well well-small" style="background-color:white; margin-top:2em;">
            <div class="row">
                <div class="col-md-10">
                    {
                        for $input in $config//input
                        let $label := string($input/@label)
                        let $name := string($input/@name)
                        let $id := concat('s',$name)
                        (:<input type="text" label="Headword" name="headword" element="tei:term[@type='headword']" keyboard="yes"/>:)
                        return 
                            <div class="form-group">
                                <label for="{$name}" class="col-sm-2 col-md-3  control-label">{$label}: </label>
                                <div class="col-sm-10 col-md-9 ">
                                    <div class="input-group">
                                        <input type="text" id="{$id}" name="{$name}" class="form-control keyboard"/>
                                        {
                                            if($input/@keyboard='yes') then 
                                                <div class="input-group-btn">
                                                    <button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false" title="Select Keyboard">
                                                        &#160;<span class="syriaca-icon syriaca-keyboard">&#160; </span><span class="caret"/>
                                                    </button>{global:keyboard-select-menu($id)}
                                                </div>
                                            else ()
                                        }
                                    </div> 
                                </div>
                            </div>     
                    }
            </div>
         </div> 
         </div>
         <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
         </div>
        <br class="clearfix"/><br/>
    </div>
</form>
};

(:~
 : Builds advanced search form
 :)
declare function search:default-search-form() {   
<form method="get" action="search.html" class="form-horizontal" role="form">
<h1>Advanced Search</h1>
    <div class="well well-small">
        <div class="well well-small" style="background-color:white;">
            <div class="row">
                <div class="col-md-10">
                <!-- Keyword -->
                 <div class="form-group">
                    <label for="q" class="col-sm-2 col-md-3  control-label">Keyword: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="q" name="q" class="form-control"/>
                    </div>
                  </div>
                    <!-- Place Name-->
                  <div class="form-group">
                    <label for="p" class="col-sm-2 col-md-3  control-label">Place Name: </label>
                    <div class="col-sm-10 col-md-9 ">
                        <input type="text" id="p" name="p" class="form-control"/>
                    </div>
                  </div>
                    <!-- Location --> 
                    <div class="form-group">
                        <label for="loc" class="col-sm-2 col-md-3  control-label">Location: </label>
                        <div class="col-md-6 ">
                            <input type="text" id="loc" name="loc" class="form-control"/>
                        </div>
                        <div class="col-md-3">
                             <select name="type" id="type" class="form-control">
                                <option value="">- Select -</option>
                                <option value="audiencia">Audiencia</option>
                                <option value="ciudad">ciudad</option>
                                <option value="corregimiento">Corregimiento</option>
                                <option value="repartimiento">repartimiento</option>
                                <option value="pueblo">Pueblo</option>
                            </select>
                         </div>
                    </div>
                    
                    </div>
            </div>
        </div>
        <div class="pull-right">
            <button type="submit" class="btn btn-info">Search</button>&#160;
            <button type="reset" class="btn">Clear</button>
        </div>
        <br class="clearfix"/><br/>
    </div>    
</form>
};
