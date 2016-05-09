xquery version "3.0";
(:~
 : Shared functions for search modules 
 :)
module namespace rec="http://syriaca.org/short-rec-view";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";


(:
 : Function to truncate description text after first 12 words
 : @param $string
:)
declare function rec:truncate-string($str as xs:string*) as xs:string? {
let $string := string-join($str, ' ')
return 
    if(count(tokenize($string, '\W+')[. != '']) gt 12) then 
        let $last-words := tokenize($string, '\W+')[position() = 14]
        return concat(substring-before($string, $last-words),'...')
    else $string
};

(: 
 : Formats search and browse results 
 : Uses English and Syriac headwords if available, tei:teiHeader/tei:title if no headwords.
 : Should handle all data types, and eliminate the need for 
 : data type specific display functions eg: persons:saints-results-node()
 : @param $node search/browse hits should be either tei:person, tei:place, or tei:body
 : Used by search.xqm, browse.xqm and get-related.xqm
:)
declare function rec:display-recs-short-view($node, $lang) as node()*{
let $ana := 
            for $series in $node/ancestor::tei:TEI/descendant::tei:titleStmt/tei:title[@level='m' or @level='s']
            return
                (switch ($series) 
                    case "A Guide to Syriac Authors" return 
                        <a href="{$global:nav-base}/authors/index.html"><img src="{$global:nav-base}/resources/img/icons-authors-sm.png" alt="A Guide to Syriac Authors"/>author</a>
                    case "Qadishe: A Guide to the Syriac Saints" return 
                        <a href="{$global:nav-base}/q/index.html"><img src="{$global:nav-base}/resources/img/icons-q-sm.png" alt="Qadishe: A Guide to the Syriac Saints"/>saint</a>
                    default return (),
                    if($series/following-sibling::*/text() = ('A Guide to Syriac Authors','Qadishe: A Guide to the Syriac Saints')) 
                        then ', ' 
                    else () 
                 )
let $type := string($node/descendant-or-self::tei:place/@type)
let $uri := 
        if($node//tei:idno[@type='URI'][starts-with(.,$global:base-uri)]) then
                string(replace($node//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei',''))
        else string($node//tei:div[1]/@uri)
let $en-title := 
             if($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^en')][1]) then 
                 string-join($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^en')][1]//text(),' ')
             else $node/descendant::tei:TEI/descendant::tei:title[1]/text()               
let $syr-title := 
             if($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][1]) then
                string-join($node/descendant::*[contains(@syriaca-tags,'#syriaca-headword')][matches(@xml:lang,'^syr')][1]//text(),' ')
             else 'NA'  
let $birth := if($ana != '') then $node/descendant::tei:birth else()
let $death := if($ana != '') then $node/descendant::tei:death else()
let $dates := concat(if($birth) then $birth/text() else(), if($birth and $death) then ' - ' else if($death) then 'd.' else(), if($death) then $death/text() else())    
let $desc := rec:truncate-string($node/descendant::*[starts-with(@xml:id,'abstract')]/descendant-or-self::text())
return
    <div class="results-list">
       <a href="{global:internal-links($uri)}">
        {
        if($lang = 'syr') then
            (<span dir="rtl" lang="syr" xml:lang="syr">{$syr-title}</span>,' - ',
             <span dir="ltr" lang="en">{concat($en-title,
                if($type) then concat(' (',$type,')') else ())}
             </span>)
        else
        ($en-title,
          if($type) then concat('(',$type,')') else (),
            if($syr-title) then 
                if($syr-title = 'NA') then ()
                else (' - ', <span dir="rtl" lang="syr" xml:lang="syr">{$syr-title}</span>)
          else ' - [Syriac Not Available]')
          }   
       </a>
       {if($ana != '') then
            <span class="results-list-desc type" dir="ltr" lang="en">
            (
            {$ana}
            {if($dates) then ', ' else(), $dates}
            )
            </span>
        else ()}
                {
            if($node/descendant-or-self::tei:person/tei:persName[not(@syriaca-tags='#syriaca-headword')][not(starts-with(@xml:lang,('syr','ar'))) and not(@xml:lang ='en-xsrp1')] 
            | $node/descendant-or-self::tei:place/tei:placeName[not(@syriaca-tags='#syriaca-headword')][not(starts-with(@xml:lang,('syr','ar'))) and not(@xml:lang ='en-xsrp1')]) then 
                <span class="results-list-desc names" dir="ltr" lang="en">Names: 
                {
                    for $names in $node/descendant-or-self::tei:person/tei:persName[not(@syriaca-tags='#syriaca-headword')]
                    [not(starts-with(@xml:lang,('syr','ar'))) and not(@xml:lang ='en-xsrp1')] 
                    | $node/descendant-or-self::tei:place/tei:placeName[not(@syriaca-tags='#syriaca-headword')][not(starts-with(@xml:lang,('syr','ar'))) and not(@xml:lang ='en-xsrp1')]                    
                    return <span class="pers-label badge">{global:tei2html($names)}</span>
                }
                </span>
            else() 
        }
        {
        if($desc != '') then 
           <span class="results-list-desc desc" dir="ltr" lang="en">
              {
                 if(request:get-parameter('q', '')) then 
                      kwic:summarize($node, <config width="40"/>)
                 else concat($desc,' ')
              }
           </span>
       else ()}   
     <span class="results-list-desc uri"><span class="srp-label">URI: </span><a href="{global:internal-links($uri)}">{$uri}</a></span>
    </div>
};