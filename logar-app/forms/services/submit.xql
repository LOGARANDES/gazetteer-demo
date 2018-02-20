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

declare variable $VALIDATE_URI as xs:anyURI := xs:anyURI("https://www.google.com/recaptcha/api/siteverify");

declare variable $editor := 
    if(request:get-attribute(concat($global:login-domain, '.user'))) then 
        request:get-attribute(concat($global:login-domain, '.user')) 
    else if(xmldb:get-current-user()) then 
        xmldb:get-current-user() 
    else '';

(: Any post processing to form data happens here :)
declare function local:transform($nodes as node()*) as item()* {
  for $node in $nodes
  return
    typeswitch($node)
        case text() return 
            parse-xml-fragment($node)
        case element(tei:change) return
            if($node[@who = 'online-submission']) then 
                element { xs:QName($node) }
                    { 
                        attribute who { 'http://syriaca.org/documentation/editors.xml#onlineForms' },
                        attribute when { current-date() },
                        string-join($node/descendant::*,', ')
                    }
            else if($node[@who = '' and @when = '']) then
                element { xs:QName($node) } 
                    { 
                        attribute who { $editor },
                        attribute when { current-date() },
                        'Record created by Syriaca.org webforms'
                    }
            else local:passthru($node)
        case element(tei:persName) return
            if($node/parent::tei:person) then 
                  element { xs:QName($node) } 
                    { 
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',count($node/preceding-sibling::tei:persName) + 1) },
                        local:transform($node)
                    }
            else 
                element { xs:QName($node) } 
                    { 
                        local:transform($node)
                    } 
        case element(tei:placeName) return
            if($node/parent::tei:place) then 
                  element { xs:QName($node) } 
                    { 
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',count($node/preceding-sibling::tei:placeName) + 1) },
                        local:transform($node)
                    }
            else  element { xs:QName($node) } 
                    { 
                        local:transform($node)
                    } 
        case element(tei:title) return
            if($node/parent::tei:bibl[parent::tei:body]) then 
                  element { xs:QName($node) } 
                    { 
                        attribute xml:id { concat('name',tokenize($node/ancestor::tei:TEI/descendant::tei:idno[1],'/')[5],'-',count($node/preceding-sibling::tei:title) + 1) },
                        local:transform($node)
                    }
            else element { xs:QName($node) } 
                    { 
                        local:transform($node)
                    }              
        case element() return local:passthru($node)
        default return local:transform($node)
};

(: Recurse through child nodes :)
declare function local:passthru($node as node()*) as item()* { 
    element {name($node)} {($node/@*, local:transform($node/node()))}
};

(:~
: Module for working with reCaptcha
:)
declare function local:recaptcha(){
let $recapture-private-key := "ADD KEY" 
return 
    local:validate($recapture-private-key, 
    request:get-parameter("g-recaptcha-response",()))
};

(:~
: Module for working with reCaptcha
:)
declare function local:validate($private-key as xs:string, $recaptcha-response as xs:string) {
    let $response :=  http:send-request(<http:request http-version="1.1" href="{$VALIDATE_URI}" method="post">
                                            <http:body media-type="application/x-www-form-urlencoded">{'?secret=',$private-key,'&amp;response=',$recaptcha-response}</http:body>
                                        </http:request>)[2]
    let $payload := util:base64-decode($response)
    let $json-data := parse-json($payload)
    return $json-data
    (:
        if(starts-with($recaptcha-response, "true")) then (true())
        else false()
    :)             
};

if(request:get-data()) then
     <response code="200">
            <message>{request:get-data()}</message>
     </response> 
else 
     <response code="500">
            <message>No data received</message>
     </response> 
