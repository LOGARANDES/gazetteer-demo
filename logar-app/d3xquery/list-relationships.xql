xquery version "3.0";

import module namespace d3xquery="http://syriaca.org/d3xquery" at "d3xquery.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace json="http://www.json.org";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

declare variable $record {request:get-parameter('recordID', '')};
declare variable $collectionPath {request:get-parameter('collection', '')};

(: Allows Syriaca.org to pass in a collection or a record. Defaults to SPEAR if no parameters are passed. :)
let $data :=
            (: Return a collection:)
            if($collectionPath != '') then 
                collection(string($collectionPath))
            (: Return a single TEI record:)    
             else if($record != '') then     
                        collection('/db/apps/logar-data/data')/tei:TEI[.//tei:idno[@type='URI'][. = concat($record,'/tei')]][1] 
             else collection('/db/apps/logar-data/data')    
return d3xquery:list-relationship($data)