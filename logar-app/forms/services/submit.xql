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

(: Any post processing to TEI form data happens here :)
declare function local:transform($nodes as node()*) as item()* {
  for $node in $nodes
  return 
    typeswitch($node)
        case processing-instruction() return $node 
        case comment() return $node 
        case text() return parse-xml-fragment($node)
        case element(tei:change) return
            if($node[@who = 'online-submission']) then 
                element { fn:local-name($node) }
                    { 
                        attribute who { 'http://syriaca.org/documentation/editors.xml#onlineForms' },
                        attribute when { current-date() },
                        string-join($node/descendant::*,', ')
                    }
            else if($node[@who = '' and @when = '']) then
                element { fn:local-name($node) } 
                    { 
                        attribute who { 'http://syriaca.org/documentation/editors.xml#onlineForms' },
                        attribute when { current-date() },
                        'Record created by Syriaca.org webforms'
                    }
            else local:passthru($node)
        case element(tei:persName) return
            if($node/parent::tei:person) then 
                  element { fn:local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[fn:local-name(.) = 'persName']) + 1) },
                        local:transform($node/node())
                    }
            else 
                element { fn:local-name($node) } 
                    { 
                        local:transform($node/node())
                    } 
        case element(tei:placeName) return
            if($node/parent::tei:place) then 
                  element { fn:local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[fn:local-name(.) = 'placeName']) + 1) },
                        local:transform($node/node())
                    }
            else 
                element { fn:local-name($node) } 
                    { 
                        local:transform($node/node())
                    } 
        case element(tei:title) return
            if($node/parent::tei:bibl[parent::tei:body]) then 
                  element { fn:local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[fn:local-name(.) = 'title']) + 1) },
                        local:transform($node/node())
                    }
            else element { name($node) } 
                    { 
                        local:transform($node/node())
                    }
        case element(tei:bibl) return
            if($node/@xml:id[. != '']) then 
                  element { fn:local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('bib',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[fn:local-name(.) = 'bibl']) + 1) },
                        local:transform($node/node())
                    }
            else element { name($node) } 
                    { 
                        local:transform($node/node())
                    }                    
        case element(tei:location) return
            if($node/tei:lat or $node/tei:long) then
                element { fn:local-name($node) } 
                    { ($node/@*[. != ''], 
                        element { 'geo' }
                          {  concat($node/tei:lat, ' ', $node/tei:long) }
                        )
                    }
            else element { fn:local-name($node) } 
                    { 
                        local:transform($node/node())
                    }                     
        case element() return local:passthru($node)
        default return local:transform($node/node())
};

(: Recurse through child nodes :)
declare function local:passthru($node as node()*) as item()* { 
    element {fn:local-name($node)} {($node/@*[. != ''], local:transform($node/node()))}
};

let $data := request:get-data()
let $record := $data//tei:TEI
let $post-processed-xml := local:transform($record)
let $id := replace($post-processed-xml/descendant::tei:idno[1],'/tei','')
let $file-name := if($id != '') then concat(tokenize($id,'/')[last()], '.xml') else 'form.xml'
let $document-uri := document-uri(root(collection($global:data-root)//tei:idno[@type='URI'][. = $id]))
let $collection-uri := substring-before($document-uri,$file-name)
return 
    if(request:get-parameter('type', '') = 'view') then
        (response:set-header("Content-type", 'text/xml'),
        serialize($post-processed-xml, 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>text/xml</output:media-type>
        </output:serialization-parameters>))
    else if(request:get-parameter('type', '') = 'save') then
    (:
        try {
            let $save := xmldb:store($collection-uri, xmldb:encode-uri($file-name), $post-processed-xml)
            return 
             <response status="okay" code="200"><message>Record saved, thank you for your contribution.</message></response>  
        } catch * {
            (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to update resource {$id}: {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }
        :)
        <response code="400">
            <message>Thanks for your submission, this feature is being tested and your data will not be saved to the database at this time, use the download button to save a local copy of the record. </message>
        </response>
    else if(request:get-parameter('type', '') = 'download') then
       (response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$post-processed-xml)       
    else 
        <response code="500">
            <message>General Error</message>
        </response> 
