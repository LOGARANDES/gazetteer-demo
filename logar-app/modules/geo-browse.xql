xquery version "3.0";
(:~
 : Get raw browse results. Filters them through geojson 
 :
 : @see lib/geojson.xqm for map generation
 :)

import module namespace data="http://syriaca.org/get-data" at "lib/get-data.xqm";

import module namespace geo="http://syriaca.org/geojson" at "lib/geojson.xqm";
import module namespace facets="http://syriaca.org/facets" at "lib/facets.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
(:
declare option output:method "json";
:)
declare option output:media-type "application/json";

declare variable $coll {request:get-parameter('coll', '')};

let $hits := data:get-browse-data($coll)
return geo:json-transform($hits//tei:geo, '','')
