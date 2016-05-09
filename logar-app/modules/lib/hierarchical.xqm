xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace hb="http://syriaca.org/hierarchical";

import module namespace functx="http://www.functx.com";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

declare variable $hb:limit {request:get-parameter('limit', 5) cast as xs:integer};
declare variable $hb:fq {request:get-parameter('fq', '') cast as xs:string};


declare function hb:top-level-geo($nodes){
for $facet in $nodes
group by $facet-grp := $facet/tei:region[@type='audiencia']
order by count($facet/ancestor::tei:TEI) descending
return 
    let $facet-value := $facet[1]/child::*/text()
    let $count := count($facet/ancestor::tei:TEI)
    return 
        <p>{$facet-value[1]} <count>{$count}</count></p>
};
