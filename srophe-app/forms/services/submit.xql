xquery version "3.1";
(:~
 : Submit xforms generated data
 : @param $type options view (view xml in new window), download (download xml without saving), save (save to db, only available to logged in users)
:)
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";
import module namespace gitcommit="http://syriaca.org/srophe/gitcommit" at "git-commit.xql";
import module namespace http="http://expath.org/ns/http-client";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.json.org";

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
        case element(tei:TEI) return 
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                {($node/@*[. != ''], local:transform($node/node()))}
            </TEI>
        case element(tei:change) return
            if($node[@who = 'online-submission']) then 
                element { local-name($node) }
                    { 
                        attribute who { 'http://syriaca.org/documentation/editors.xml#onlineForms' },
                        attribute when { current-date() },
                        string-join($node/descendant::*,', ')
                    }
            else if($node[@who = '' and @when = '']) then
                element { local-name($node) } 
                    { 
                        attribute who { 'http://syriaca.org/documentation/editors.xml#onlineForms' },
                        attribute when { current-date() },
                        'Record created by Syriaca.org webforms'
                    }
            else local:passthru($node)
        case element(tei:persName) return
            if($node/parent::tei:person) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[local-name(.) = 'persName']) + 1) },
                        local:transform($node/node())
                    }
            else 
                element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:placeName) return
            if($node/parent::tei:place) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[local-name(.) = 'placeName']) + 1) },
                        local:transform($node/node())
                    }
            else 
                element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:title) return
            if($node/parent::tei:bibl[parent::tei:body]) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[local-name(.) = 'title']) + 1) },
                        local:transform($node/node())
                    }
            else element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:bibl) return
            if($node/@xml:id[. != '']) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('bib',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',
                        count($node/preceding-sibling::*[local-name(.) = 'bibl']) + 1) },
                        local:transform($node/node())
                    }
            else element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}                   
        case element(tei:location) return 
            if($node/tei:lat or $node/tei:long) then
                element { local-name($node) } 
                    {
                        $node/@*[. != '' and not(name(.) = 'type')], attribute type { "gps" }, 
                        element { 'geo' }
                          { concat($node/tei:lat, ' ', $node/tei:long) }
                        
                    }
            else element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}                   
        case element() return local:passthru($node)
        default return local:transform($node/node())
};

(: Recurse through child nodes :)
declare function local:passthru($node as node()*) as item()* { 
    element {local-name($node)} {($node/@*[. != ''], local:transform($node/node()))}
};


let $data := if(request:get-parameter('postdata','')) then request:get-parameter('postdata','') else request:get-data()
let $record := 
    if($data instance of node()) then
        $data//tei:TEI
    else fn:parse-xml($data)        
let $post-processed-xml := local:transform($record)
let $id := replace($post-processed-xml/descendant::tei:idno[1],'/tei','')
let $file-name := if($id != '') then concat(tokenize($id,'/')[last()], '.xml') else 'form.xml'
let $document-uri := document-uri(root(collection($global:data-root)//tei:idno[@type='URI'][. = $id]))
let $collection-uri := substring-before($document-uri,$file-name)
let $github-path := substring-after($collection-uri,'logar-data/')
return 
    if(request:get-parameter('type', '') = 'save') then
        try {
            let $save := xmldb:store($collection-uri, xmldb:encode-uri($file-name), $post-processed-xml)
            return 
             <response status="okay" code="200"><message>Record saved, thank you for your contribution. {$post-processed-xml}</message></response>  
        } catch * {
            (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to update resource {$id}: {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }
    else if(request:get-parameter('type', '') = 'github') then
        try {
            let $save := gitcommit:run-commit($post-processed-xml, concat($github-path,$file-name), concat("User submitted content for ",$document-uri))
            return 
             <response status="okay" code="200"><message>Thank you for your contribution.</message></response>  
        } catch * {
            (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to submit, please download your changes and send via email. {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }    
    else if(request:get-parameter('type', '') = ('download','view')) then
            (response:set-header("Content-Type", "application/xml; charset=utf-8"),
             response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$post-processed-xml)     
    else 
        <response code="500">
            <message>General Error</message>
        </response> 