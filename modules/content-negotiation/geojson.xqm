xquery version "3.0";

module namespace geojson="http://srophe.org/srophe/geojson";
(:~
 : Module returns coordinates as geoJSON
 : Formats include geoJSON 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)

import module namespace global="http://srophe.org/srophe/global" at "../lib/global.xqm";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace json = "http://www.json.org";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : Serialize XML as JSON
:)
declare function geojson:geojson($nodes as node()*){
    serialize(geojson:json-wrapper($nodes), 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>)
    (: xqjson:serialize-json(geojson:json-wrapper($nodes)) :)
};

(:~
 : Build root element for geojson output
:)
declare function geojson:json-wrapper($nodes as node()*) as element()*{
    <root>
        <type>FeatureCollection</type>
        <features>
            {
            let $nodes := $nodes[descendant-or-self::tei:geo]
            let $count := count($nodes)
            for $n in $nodes
            return geojson:geojson-object($n, $count)}
        </features>
    </root>
};

(:~
 : Build geoJSON object for each node with coords
 : Sample data passed to geojson-object
  <place xmlns="http://www.tei-c.org/ns/1.0">
    <idno></idno>
    <title></title>
    <desc></desc>
    <location></location>  
  </place>
:)
declare function geojson:geojson-object($node as node()*, $count as xs:integer?) as element()*{
let $id := ($node/descendant::tei:idno[@type='URI'], $node/descendant::tei:idno)[1]
let $title := root($node)/descendant::tei:titleStmt/tei:title[1]
let $desc := if($node/descendant::tei:desc[1]/tei:quote) then 
                concat('"',$node/descendant::tei:desc[1]/tei:quote,'"')
             else $node//tei:desc[1]  
let $coords := $node/descendant::tei:location[@type="gps"][1]/tei:geo[1]
return 
    <json:value>
        {(if(count($count) = 1) then attribute {xs:QName("json:array")} {'true'} else())}
        <type>Feature</type>
        <geometry>
            <type>Point</type>
            <coordinates json:literal="true">{tokenize($coords,' ')[2]}</coordinates>
            <coordinates json:literal="true">{tokenize($coords,' ')[1]}</coordinates>
        </geometry>
        <properties>
            <uri>{replace(replace($id,$global:base-uri,$global:nav-base),'/tei','')}</uri>
            <name>{string-join($title/text(),' ')}</name>
            {if($desc != '') then
                <desc>{string-join($desc,' ')}</desc> 
            else()}
        </properties>
    </json:value>
};