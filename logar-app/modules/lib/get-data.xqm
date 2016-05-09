xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Browse by type
 :
 : @see lib/geojson.xqm for map generation
 :)

module namespace data="http://syriaca.org/get-data";

import module namespace common="http://syriaca.org/common" at "../search/common.xqm";
import module namespace geo="http://syriaca.org/geojson" at "geojson.xqm";
import module namespace facets="http://syriaca.org/facets" at "facets.xqm";
import module namespace global="http://syriaca.org/global" at "global.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) for browse.html 
 : @param $browse:type selects doc type filter eg: place@type person@ana
 : @param $browse:view selects language for browse display
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $data:coll {request:get-parameter('coll', '')};
declare variable $data:type {request:get-parameter('type', '')}; 
declare variable $data:view {request:get-parameter('view', '')};
declare variable $data:sort {request:get-parameter('sort', '')};
declare variable $data:type-map {request:get-parameter('type-map', '')};
declare variable $data:date {request:get-parameter('date', '')};
declare variable $data:fq {request:get-parameter('fq', '')};

(:~
 : Build browse path for evaluation 
 : Uses $coll to build path to appropriate data set 
 : If no $coll parameter is present data and all subdirectories will be searched.
 : @param $coll collection name passed from html, should match data subdirectory name
:)
declare function data:get-browse-data($coll as xs:string?){
let $path := 
    if($coll = 'places') then concat("collection('",$global:data-root,"/places/tei')//tei:place",facets:facet-filter())
    else if(exists($coll)) then concat("collection('",$global:data-root,xs:anyURI($coll),"')//tei:body",facets:facet-filter())
    else concat("collection('",$global:data-root,"')//tei:body",facets:facet-filter())
return util:eval($path)    
};

