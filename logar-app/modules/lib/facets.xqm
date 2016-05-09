xquery version "3.0";
(:~
 : Builds browse page for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists
 : Results output as TEI xml and are transformed by /srophe/resources/xsl/browselisting.xsl
 :)
 
module namespace facets="http://syriaca.org/facets";

import module namespace functx="http://www.functx.com";
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

declare variable $facets:limit {request:get-parameter('limit', 5) cast as xs:integer};
declare variable $facets:fq {request:get-parameter('fq', '') cast as xs:string};

(:
NOTES about facet module
Will have to have a special cases to handle the crazyness of @ref facets
add facet parameters and functionality to browse.xm and search.xqm?
:)

(:
 : Filter by facets to be passed to browse or search function
:)
declare function facets:facet-filter(){
    if($facets:fq != '') then
        string-join(
        for $facet in tokenize($facets:fq,'fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            if($facet-value != '') then 
                if($facet-name = 'title') then 
                    concat("[ancestor::tei:TEI/descendant::tei:titleStmt[1]/tei:title[1][. = '",$facet-value,"']]")
                else if($facet-name = 'keyword') then 
                    concat("[descendant::*[matches(@ref,'(^|\W)",$facet-value,"(\W|$)') | matches(@target,'(^|\W)",$facet-value,"(\W|$)')]]")
                else if($facet-name = 'audiencia') then 
                    concat("[descendant::tei:location/tei:region[@type='audiencia'][.='",$facet-value,"']]")
                else if($facet-name = 'corregimiento') then 
                    concat("[descendant::tei:location/tei:region[@type='corregimiento'][.='",$facet-value,"']]")
                else if($facet-name = 'repartimiento') then 
                    concat("[descendant::tei:location/tei:region[@type='repartimiento'][descendant::* ='",$facet-value,"']]")
                else if($facet-name = 'ciudad') then 
                    concat("[descendant::tei:location/tei:region[@type='ciudad'][.='",$facet-value,"']]")
                else if($facet-name = 'pueblo') then 
                    concat("[descendant::tei:location/tei:settlement[@type='pueblo'][.='",$facet-value,"']]")                    
                else
                    concat('[descendant::tei:',$facet-name,'[normalize-space(.) = "',$facet-value,'"]]')
            else(),'')    
    else ()   
};

(:~
 : Build facets menus from nodes passed by search or browse
 : @param $facets nodes to facet on
 : @param $facets:limit number of facets per catagory to display, defaults to 5
:)
declare function facets:facets($facets as node()*){
<div>
    <!--<div>{facets:facet-filter()}</div>-->
    <span class="facets applied">
        {
            if($facets:fq) then facets:selected-facet-display()
            else ()            
        }
    </span>
    {
        for $facet-group in $facets
        group by $category := node-name($facet-group)
        return 
            <div class="category">
                {
                    if(string($category) = 'event') then 
                        <div>
                            <h4>Keyword</h4>
                            {
                            (<div class="facet-list show">
                                {
                                if($facets:limit) then 
                                    for $facet-list at $l in subsequence(facets:keyword($facets),1,$facets:limit)
                                    return $facet-list
                                else facets:keyword($facets)
                                }
                               </div>,
                               <div class="facet-list collapse" id="{concat('show',string($category))}">
                                {
                                if($facets:limit) then 
                                    for $facet-list at $l in subsequence(facets:keyword($facets),$facets:limit + 1)
                                    return $facet-list
                                else facets:keyword($facets)
                                }
                               </div>,
                               <a class="togglelink" data-toggle="collapse" data-target="#{concat('show',string($category))}" data-text-swap="less">more...</a>)
                            }
                        </div>  
                    else if(string($category) = 'title') then 
                        <div>
                                <h4>Source Text</h4>
                                {
                                (<div class="facet-list show">
                                    {
                                    if($facets:limit) then 
                                        for $facet-list at $l in subsequence(facets:title($facets),1,$facets:limit)
                                        return $facet-list
                                    else facets:title($facets)
                                    }
                                   </div>,
                                   <div class="facet-list collapse" id="{concat('show',string($category))}">
                                    {
                                    if($facets:limit) then 
                                        for $facet-list at $l in subsequence(facets:title($facets),$facets:limit + 1)
                                        return $facet-list
                                    else facets:title($facets)
                                    }
                                   </div>,
                                   <a class="togglelink" data-toggle="collapse" data-target="#{concat('show',string($category))}" data-text-swap="less">more...</a>)
                                }
                            </div>   
                    else if(string($category) = 'location') then 
                        <div>
                            <h4>Location</h4>
                            <div class="facet-list show">{facets:hierarchical-geo($facets)}</div>
                        </div>  
                    else 
                        <div>
                            <h4>{if(string($category) = 'persName') then 'Person' else if(string($category) = 'placeName') then 'Place' else if(string($category) = 'title') then 'Source Text' else string($category)}</h4>
                            {
                                if($facets:limit) then 
                                    (<div class="facet show">
                                    {
                                    for $facet-list at $l in subsequence(facets:build-facet($facet-group,string($category)),1,$facets:limit)
                                    return $facet-list
                                    }
                                    </div>,
                                    <div class="facet collapse" id="{concat('show',string($category))}">
                                    {
                                    for $facet-list at $l in subsequence(facets:build-facet($facet-group,string($category)),$facets:limit + 1)
                                    return $facet-list
                                    }
                                    </div>,
                                    <a class="togglelink" data-toggle="collapse" data-target="#{concat('show',string($category))}" data-text-swap="less">more...</a>)
                                else facets:build-facet($facet-group,string($category))   
                            }
                        </div>
                }     
            </div>
    }
</div>
};

declare function facets:url-params(){
    for $param in request:get-parameter-names()
    return 
        if($param = 'fq') then ()
        else if(request:get-parameter($param, '') = ' ') then ()
        else if(request:get-parameter($param, '') = '') then ()
        else concat('&amp;',$param, '=',request:get-parameter($param, ''))
};

(:~
 : Display selected facets, and button to remove from results set
:)
declare function facets:selected-facet-display(){
    for $facet in tokenize($facets:fq,' fq-')
    let $title := if(contains($facet,'http:')) then 
                    lower-case(functx:camel-case-to-words(substring-after($facet[1],'/keyword/'),' '))
                   else substring-after($facet,':')
    let $new-fq := string-join(for $facet-param in tokenize($facets:fq,' fq-') 
                    return 
                        if($facet-param = $facet) then ()
                        else concat('fq-',$facet-param),' ')
    let $href := concat('?fq=',$new-fq,facets:url-params())
    return 
        <span class="facet" title="Remove {$title}">
            <span class="label label-facet" title="{$title}">{$title} 
                <a href="{$href}" class="facet icon">
                    <span class="glyphicon glyphicon-remove" aria-hidden="true"></span>
                </a>
            </span>
        </span>
};

(:~
 : Build individual facet lists for each facet category
 : @param $nodes nodes to facet on
:)
declare function facets:build-facet($nodes, $category){
    for $facet in $nodes
    group by $facet-grp := $facet/@ref
    order by count($facet) descending
    return  
        let $facet-val := $facet[1]
        let $facet-query := concat('fq-',$category,':',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($facet-val)} <span class="count">  ({count($facet)})</span></a>
};

(:~
 : Build individual facet lists for title facet category
 : Special because it is a parent of returned div, not child
 : @param $nodes nodes to facet on
:)
declare function facets:title($nodes){
    for $facet in $nodes
    group by $facet-grp := $facet/ancestor::tei:TEI/descendant::tei:titleStmt[1]/tei:title[1]
    order by count($facet/ancestor::tei:TEI//tei:div) descending
    return  
        let $facet-val := $facet[1]
        let $facet-query := concat('fq-title:',normalize-space($facet-val))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($facet/ancestor::tei:TEI/descendant::tei:titleStmt[1]/tei:title[1])} <span class="count">  ({count($facet/ancestor::tei:TEI//tei:div)})</span></a>
};
(:~
 : Special handling for keywords which are in attributes and must be tokenized
 : @param $nodes nodes to build keyword list
:)
declare function facets:keyword-list($nodes){
    (for $keyword in $nodes//@target[contains(.,'/keyword/')]
    return 
        for $key in tokenize($keyword,' ')
        return <p>{$key}</p>,
    for $keyword in $nodes//@ref[contains(.,'/keyword/')]
    return
    for $key in tokenize($keyword,' ')
        return <p>{$key}</p>)
};

(:~
 : Special handling for keywords which are in attributes and must be tokenized
 : Facets on keyword list generated from events nodes passed to facets:facet()
 : @param $nodes nodes to build keyword list
:)
declare function facets:keyword($nodes){
    for $k in facets:keyword-list($nodes)
    group by $k := $k
    order by count($k) descending
    return
        let $khref := string($k[1])
        let $kpretty := lower-case(functx:camel-case-to-words(substring-after($k[1],'/keyword/'),' '))
        let $facet-query := concat('fq-keyword:',normalize-space($khref))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return
        <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($kpretty)} <span class="count"> ({count($k)})</span></a>
};

(: Logar specific hierarchical geographic facets :)
declare function facets:hierarchical-geo($nodes){
for $facet in $nodes[tei:region[@type='audiencia']]
group by $facet-grp := $facet/tei:region[@type='audiencia']
order by count($facet/ancestor::tei:TEI) descending
return 
        let $s := $facet[1]/tei:region[@type='audiencia']/text()
        let $facet-query := concat('fq-audiencia:',normalize-space($s))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        let $id := replace(string($s),' ','')   
        return
            if($s != '') then 
             <ul class="facet-group nav nav-pills nav-stacked facet-top">
                 <li class="facet-group-item">
                     <span class="row">
                         <span class="col-md-1">
                             <a class="togglelink" data-toggle="collapse" data-target="#{concat('show',string($id))}" data-text-swap="-">+</a>
                         </span>
                         <span class="col-md-8">
                             <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($s)}</a>
                         </span>
                         <span class="col-md-1">
                             <span class="badge pull-right">{count($facet)}</span>
                         </span>
                     </span>
                     <ul id="{concat('show',string($id))}" class="facet-group list-unstyled collapse">
                         {facets:hierarchical-geo-tier2($facet)}
                     </ul>
                 </li>
             </ul>
           else () 
};

declare function facets:hierarchical-geo-tier2($nodes){
for $facet in $nodes[tei:region[@type='corregimiento']]
group by $facet-grp := $facet/tei:region[@type='corregimiento']
order by count($facet/ancestor::tei:TEI) descending
return 
        let $s := $facet[1]/tei:region[@type='corregimiento']/text()
        let $facet-query := concat('fq-corregimiento:',normalize-space($s))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        let $id := replace(replace(string($s),' ',''),'/','')   
        return
            <li class="facet-group-item">
                    <span class="row">
                        <span class="col-md-1">
                            {<a class="togglelink" data-toggle="collapse" data-target="#{concat('show',string($id))}" data-text-swap="-">+</a>}
                        </span>
                        <span class="col-md-8">
                            <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($s)}</a>
                        </span>
                        <span class="col-md-1">
                            <span class="badge pull-right">{count($facet)}</span>
                        </span>
                    </span>
                    <ul class="facet-group list-unstyled collapse" id="{concat('show',string($id))}">
                        {facets:hierarchical-geo-tier3($facet)}
                    </ul>
            </li>
};

declare function facets:hierarchical-geo-tier3($nodes){
for $facet in $nodes[tei:region[@type='repartimiento']]
group by $facet-grp := $facet/tei:region[@type='repartimiento'][1]/tei:placeName[@type="standardized"]/text()
order by count($facet/ancestor::tei:TEI) descending
return 
        let $s := $facet[1]/tei:region[@type='repartimiento'][1]/tei:placeName[@type="standardized"]/text()
        let $facet-query := concat('fq-repartimiento:',normalize-space($s))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        let $id := replace(string($s),' ','')                
        return
            <li class="facet-group-item">
                    <span class="row">
                        <span class="col-md-1">
                            {
                                if(not(empty(facets:hierarchical-geo-tier4($facet)))) then 
                                    <a class="togglelink" data-toggle="collapse" data-target="#{concat('show',string($id))}" data-text-swap="-">+</a>
                                else ()
                            }
                        </span>
                        <span class="col-md-8">
                            <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($s)}</a>
                        </span>
                        <span class="col-md-1">
                             <span class="badge pull-right">{count($facet)}</span>
                        </span>
                    </span>
                    <ul class="facet-group list-unstyled collapse" id="{concat('show',string($id))}">
                        {facets:hierarchical-geo-tier4($facet)}
                    </ul>
                </li>
};

declare function facets:hierarchical-geo-tier4($nodes){
for $facet in $nodes[tei:settlement[@type='pueblo']]
group by $facet-grp := $facet/tei:settlement[@type='pueblo']
order by count($facet/ancestor::tei:TEI) descending
return 
        let $s := $facet[1]/tei:settlement[@type='pueblo']/text()
        let $facet-query := concat('fq-pueblo:',normalize-space($s))
        let $new-fq := 
                if($facets:fq) then concat('fq=',$facets:fq,' ',$facet-query)
                else concat('fq=',$facet-query)
        return
            <li class="facet-group-item">
                <span class="row">
                        <span class="col-md-1"></span>
                        <span class="col-md-8">
                            <a href="?{$new-fq}{facets:url-params()}" class="facet-label">{string($s)}</a>
                        </span>
                        <span class="col-md-1">
                             <span class="badge pull-right">{count($facet)}</span>
                        </span>
                    </span>
            </li>

};