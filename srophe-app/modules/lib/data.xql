xquery version "3.1";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by browse, search, and view records.  
 :
 : @see lib/facet.xqm for facets
 : @see lib/paging.xqm for sort options
 : @see lib/global.xqm for global variables 
 :)
 

import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace facet="http://expath.org/ns/facet" at "facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "../facet-defs.xqm";
import module namespace page="http://syriaca.org/page" at "paging.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:
 : Generic get record function
 : Manuscripts and SPEAR recieve special treatment as individule parts may be treated as full records. 
 : Syriaca.org uses tei:idno for record IDs 
 : @param $id syriaca.org uri for record or part. 
:)
declare function local:get-rec($id as xs:string?){  
        if($global:id-path != '') then
            for $rec in util:eval(concat('collection($global:data-root)//tei:TEI[',$global:id-path,' = $id]'))
            return $rec
        else
            for $rec in collection($global:data-root)//tei:TEI[.//tei:idno[@type='URI'][. = concat($id,'/tei')]][1]
            return $rec 
};


(:~
 : Build browse/search path.
 : @param $collection name from repo.xml
 : @note parameters can be passed to function via the HTML templates or from the requesting url
 : @note there are two ways to define collections, physical collection and tei collection, seriesStmt
 : Enhancement: It would be nice to be able to pass in multiple collections to browse function
:)
declare function local:build-collection-path($collection as xs:string?) as xs:string?{  
let $collection-path := 
        if(global:collection-vars($collection)/@data-root != '') then concat('/',global:collection-vars($collection)/@data-root)
        else if($collection != '') then concat('/',$collection)
        else ()
let $get-series :=  
        if(global:collection-vars($collection)/@collection-URI != '') then string(global:collection-vars($collection)/@collection-URI)
        else ()                             
let $series-path := 
        if($get-series != '') then concat("[descendant::tei:idno[. = '",$get-series,"'][ancestor::tei:seriesStmt]]")
        else ''
return concat("collection('",$global:data-root,$collection-path,"')",$series-path)
};
(:
return data:build-collection-path()
 :)
let $collection :=  request:get-parameter("collection", ())
let $format :=  request:get-parameter("format", ())
let $data := if($collection != '') then
                    collection($global:data-root || '/' || $collection)
                 else collection($global:data-root)
let $request-format := if($format != '') then $format  else if($content-type) then $content-type else 'xml'
return cntneg:content-negotiation($data, $request-format,())
 