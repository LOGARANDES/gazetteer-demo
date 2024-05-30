xquery version "3.0";

module namespace geokml="http://syriaca.org/geokml";
(:~
 : Module returns coordinates as geoJSON
 : Formats include geoJSON 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : Serialize XML as KML
:)
declare function geokml:kml($nodes as node()*){
<kml xmlns="http://www.opengis.net/kml/2.2">
    <Document>
        {
         for $n in $nodes 
         return geokml:kml-element($n)
         }
    </Document>
</kml>
};

(:~
 : Build KML object for each node with coords
 : Sample data passed to geojson-object
  <place xmlns="http://www.tei-c.org/ns/1.0">
    <idno></idno>
    <title></title>
    <desc></desc>
    <location></location>  
  </place>  
:)
declare function geokml:kml-element($node as node()*) as element()*{
let $id := if($node/descendant::tei:idno[@type='URI']) then $node/descendant::tei:idno[@type='URI'][1]
           else $node/descendant::tei:idno[1]
let $title := root($node)/descendant::tei:titleStmt/tei:title[1]
let $desc := if($node/descendant::tei:desc[1]/tei:quote) then 
                concat('"',$node/descendant::tei:desc[1]/tei:quote,'"')
             else $node//tei:desc[1]  
let $coords := $node/descendant::tei:location[@type="gps"][1]/tei:geo[1]
return 
        <Placemark xmlns="http://www.opengis.net/kml/2.2">
            <name>{string-join($title,' ')} - {replace($id,'/tei','')}</name>
            {if($desc != '') then 
                <description>{string-join($desc,' ')}</description>
            else()}
            <Point>
                <coordinates>{concat(tokenize($coords,' ')[2],', ',tokenize($coords,' ')[1])}</coordinates>
            </Point>
        </Placemark>
};