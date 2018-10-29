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

declare function local:update-github($new-content, $path){
    let $repo := 'https://api.github.com/repos/wsalesky/blogs'
    let $authorization-token := 'ec447cb4c82ce35b24faf8733b58004563bc5c4a'
    let $commit := 'Online submission from webforms. Please review.'

    let $headers := 
    <httpclient:headers>
        <httpclient:header name="Authorization" value="{concat('token ',$authorization-token)}"/>
    </httpclient:headers>
    
    (: Get master branch of $repo :)
    let $latest-commit := xqjson:parse-json(util:base64-decode(httpclient:get(xs:anyURI(concat($repo,'/git/refs/heads/master')),false(), $headers)/httpclient:body))
    (: Get latest commit SHA from master branch  :)
    let $get-latest-commit-sha := $latest-commit//pair[@name='sha']/text()
    
    (: Get latest commit tree using $get-latest-commit-sha :)
    let $get-latest-commit := xqjson:parse-json(util:base64-decode(httpclient:get(xs:anyURI(concat($repo,'/git/commits/',$get-latest-commit-sha)),false(), $headers)/httpclient:body))
    (: Get latest commit tree SHA :) 
    let $latest-commit-tree-sha := $get-latest-commit//pair[@name='tree']/pair[@name='sha']/text()
    
    (: Get latest tree using $latest-commit-tree-sha :)
    let $get-latest-tree := xqjson:parse-json(util:base64-decode(httpclient:get(xs:anyURI(concat($repo,'/git/trees/',$latest-commit-tree-sha)),false(), $headers)/httpclient:body))
    
    (: Create new blob with new content base64/utf-8 :)
    let $new-blob-content := 
    xqjson:serialize-json(
        <pair name="object" type="object">
            <pair name="content" type="string">{$new-content}</pair>
            <pair name="encoding" type="string">utf-8</pair>
        </pair>)
    
    (: Send new blob-content to Github API:)
    let $new-blob := xqjson:parse-json(util:base64-decode(httpclient:post(xs:anyURI(concat($repo,'/git/blobs')), $new-blob-content, false(), $headers)/httpclient:body))    
    (: New blob sha :)
    let $new-blob-sha := $new-blob/pair[@name='sha']/text()
    
    (: 
     : Create a new tree
     : New tree includes
     : base_tree: $latest-commit-tree-sha (the tree referenced in the latest commit, referenced in the master branch.)
     : path: path to the new/updated file relative to app/repo root.
     : sha: $new-blob-sha (SHA for the just created new content blob)
    :)
    let $new-tree-content := 
    xqjson:serialize-json(
        <pair name="object" type="object">
            <pair name="base_tree" type="string">{$latest-commit-tree-sha}</pair>
            <pair name="tree" type="array">
                <pair name="object" type="object">
                    <pair name="path" type="string">{$path}</pair>
                    <pair name="mode" type="string">100644</pair>
                    <pair name="type" type="string">blob</pair>
                    <pair name="sha" type="string">{$new-blob-sha}</pair>
                </pair>
            </pair>
        </pair>)
    (: Send new tree to Github API:)    
    let $new-tree := xqjson:parse-json(util:base64-decode(httpclient:post(xs:anyURI(concat($repo,'/git/trees')), $new-tree-content, false(), $headers)/httpclient:body))    
    (: New tree SHA :)    
    let $new-tree-sha := $new-tree/pair[@name='sha']/text()
    
    (: 
     : Create new commit 
     : message: commit message
     : tree: $new-tree-sha (the SHA of the tree you have just created for your new content)
     : parents: $get-latest-commit-sha (an array of parent SHA's, can be just one, should not be empty)
     :)
    let $new-commit-content :=
    xqjson:serialize-json(
        <pair name="object" type="object">
            <pair name="message" type="string">{$commit}</pair>
            <pair name="tree" type="string">{$new-tree-sha}</pair>
            <pair name="parents" type="array"><item type="string">{$get-latest-commit-sha}</item></pair>
        </pair>)
    (: Send new commit to Github API:)  
    let $new-commit := xqjson:parse-json(util:base64-decode(httpclient:post(xs:anyURI(concat($repo,'/git/commits')), $new-commit-content, false(), $headers)/httpclient:body))    
    (: New commit SHA :)  
    let $new-commit-sha := $new-commit/self::json[@type='object']/pair[@name='sha']/text()
        
    (: Update refs in repository to your new commit SHA :)
    let $commit-ref-data :=
    xqjson:serialize-json(
        <pair name="object" type="object">
            <pair name="sha" type="string">{$new-commit-sha}</pair>
            <pair name="force" type="boolean">true</pair>
        </pair>)    
    let $commit-ref := httpclient:post(xs:anyURI(concat($repo,'/git/refs/heads/master')), $commit-ref-data, false(), $headers)
    let $commit-ref-message := xqjson:parse-json(util:base64-decode($commit-ref//httpclient:body))
    
    (: Returns final commit message :)
    return $commit-ref-message
};

let $data := request:get-data()
let $record := $data//tei:TEI
let $post-processed-xml := local:transform($record)
let $id := replace($post-processed-xml/descendant::tei:idno[1],'/tei','')
let $file-name := if($id != '') then concat(tokenize($id,'/')[last()], '.xml') else 'form.xml'
let $document-uri := document-uri(root(collection($global:data-root)//tei:idno[@type='URI'][. = $id]))
let $collection-uri := substring-before($document-uri,$file-name)
let $github-path := substring-after($collection-uri,'logar-data/')
return 
    if(request:get-parameter('type', '') = 'view') then
        (response:set-header("Content-type", 'text/xml'),
        serialize($post-processed-xml, 
        <output:serialization-parameters>
            <output:method>xml</output:method>
            <output:media-type>text/xml</output:media-type>
        </output:serialization-parameters>))
    else if(request:get-parameter('type', '') = 'save') then
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
(:
        <response code="400">
            <message>Thanks for your submission, this feature is being tested and your data will not be saved to the database at this time, 
            use the download button to save a local copy of the record. 
            {$post-processed-xml}
            </message>
        </response>
        :)
    else if(request:get-parameter('type', '') = 'github') then
        <response status="okay" code="200"><message>{ 
            gitcommit:run-commit($post-processed-xml, concat($github-path,$file-name), concat("User submitted content for ",$document-uri))
        }</message></response>
    else if(request:get-parameter('type', '') = 'download') then
       (response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$post-processed-xml)     
    else 
        <response code="500">
            <message>General Error</message>
        </response> 