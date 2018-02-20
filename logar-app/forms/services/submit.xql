xquery version "3.1";
(:~
 : Submit xforms generated data
 : @param $type options view (view xml in new window), download (download xml without saving), save (save to db, only available to logged in users)
:)
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";
import module namespace http="http://expath.org/ns/http-client";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare option output:method "xml";
declare option output:media-type "text/xml";

if(request:get-data()) then 
     <response code="200">
            <message>{'You may not save records while this feature is in development.'}</message>
     </response>
     
else 
     <response code="500">
            <message>No data received</message>
     </response> 
