xquery version "3.0";
(:~ 
 : Partial facet implementation for eXist-db based on the EXPath specifications (http://expath.org/spec/facet)
 : 
 : Uses the following eXist-db specific functions:
 :      util:eval 
 :      request:get-parameter
 :      request:get-parameter-names()
 : 
 : @author Winona Salesky
 : @version 1.0 
 :
 : @see http://expath.org/spec/facet   
 : 
 : TODO: 
 :  Support for hierarchical facets
 :)

module namespace facet = "http://expath.org/ns/facet";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: External facet parameters :)
declare variable $facet:fq {request:get-parameter('fq', '') cast as xs:string};

(:~
 : Given a result sequence, and a sequence of facet definitions, count the facet-values for each facet defined by the facet definition(s).
 : Accepts one or more facet:facet-definition elements
 : Signiture: 
    facet:count($results as item()*,
        $facet-definitions as element(facet:facet-definition)*) as element(facet:facets)
 : @param $results results node to be faceted on.
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:count($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:facets){
<facets xmlns="http://expath.org/ns/facet" count="{count($facet-definitions)}">
    { 
    for $facet in $facet-definitions
    return facet:facet($results, $facet)
    }
</facets>  
};


(:~
 : Given a result sequence, and a facet definition, count the facet-values for each facet defined by the facet definition. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:facet($results as item()*, $facet-definitions as element(facet:facet-definition)?) as item()*{
    <facet xmlns="http://expath.org/ns/facet" name="{$facet-definitions/@name}" show="{$facet-definitions/facet:max-values/@show}" max="{$facet-definitions/facet:max-values/text()}">
        {
        let $max := if($facet-definitions/facet:max-values/text()) then $facet-definitions/facet:max-values/text() else 100
        let $facet := 
                if($facet-definitions/facet:range) then
                    facet:group-by-range($results, $facet-definitions)
                else if ($facet-definitions/facet:group-by/@function) then
                    util:eval(concat($facet-definitions/facet:group-by/@function,'($results,$facet-definitions)'))
                else if($facet-definitions/facet:facet-definition) then 
                    facet:hierarchical-facet($results, $facet-definitions)
                else facet:group-by($results, $facet-definitions)
        for $facets at $i in subsequence($facet,1,$max)
        return $facets
        }
    </facet>
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each facet defined by the facet definition. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
(: TODO: Need to be able to switch out descending with ascending based on facet-def/order-by/@direction:)
declare function facet:group-by($results as item()*, $facet-definitions as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$facet-grp}"/>
};

(:~
 : Syriaca.org specific group-by function for correctly labeling attributes with arrays.
:)
declare function facet:group-by-array($results as item()*, $facet-definitions as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definitions/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    for $f in $d
    group by $facet-grp := tokenize($f,' ')
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$facet-grp}"/>
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each range facet defined by the facet definition. 
 : Range values defined by: range and range/bucket elements
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:group-by-range($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    let $ranges := $facet-definitions/facet:range
    let $sort := $facet-definitions/facet:order-by 
    for $range in $ranges/facet:bucket
    let $path := concat('$results/',$facet-definitions/descendant::facet:sub-path/text(),'[. gt "', facet:type($range/@gt, $ranges/@type),'" and . lt "',facet:type($range/@lt, $ranges/@type),'"]')
    let $f := util:eval($path)
    order by 
            if($sort/text() = 'value') then string($range/@name)
            else if($sort/text() = 'count') then count($f)
            else if($sort/text() = 'order') then xs:integer($range/@order)
            else count($f)
        descending
    return 
         <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{string($range/@name)}" label="{string($range/@name)}"/>
};

(:~ 
 : Hierarchical facets
 : Recurse through nested facets, output using facet:facet($results as item()*, $facet-definitions as element(facet:facet-definition)?)
 : Facets should follow expath example 5.5: http://expath.org/spec/facet#case-5-hierarchical-facet
 :)
declare function facet:hierarchical-facet($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
    return 
        <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$facet-grp}">
           {
            for $child in $facet-definitions/facet:facet-definition
            return facet:facet($results, $child)
           }
        </key>
};

(: LOGAR hierarchical :)
declare function facet:hierarchical-logar($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    for $f in $results[descendant::tei:region[@type='audiencia']]
    group by $facet-grp := $f/descendant::tei:region[@type='audiencia'][1]/text()
    order by count($f)
    return 
        <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$facet-grp}">
           <facet xmlns="http://expath.org/ns/facet" name="Corregimiento" show="20" max="40">
           {
            for $f2 in $f[descendant::tei:region[@type='corregimiento']]
            group by $facet-grp2 := $f2/descendant::tei:region[@type='corregimiento'][1]/text()
            order by $facet-grp2
            return 
                <key xmlns="http://expath.org/ns/facet" count="{count($f2)}" value="{$facet-grp2}" label="{$facet-grp2}">
                    <facet xmlns="http://expath.org/ns/facet" name="Repartimiento" show="20" max="40">
                    {
                        for $f3 in $f2[descendant::tei:region[@type='repartimiento']]
                        group by $facet-grp3 := $f3/descendant::tei:region[@type='repartimiento'][1]/tei:placeName[@type="standardized"][1]/text()
                        order by $facet-grp3
                        return 
                            <key xmlns="http://expath.org/ns/facet" count="{count($f3)}" value="{$facet-grp3}" label="{$facet-grp3}">
                                <facet xmlns="http://expath.org/ns/facet" name="Pueblo" show="20" max="40">
                                    {
                                    for $f4 in $f3[descendant::tei:settlement[@type='pueblo']]
                                    group by $facet-grp4 := $f4/descendant::tei:settlement[@type='pueblo'][1]/text()
                                    order by $facet-grp4
                                    return
                                        <key xmlns="http://expath.org/ns/facet" count="{count($f4)}" value="{$facet-grp4}" label="{$facet-grp4}"/>
                                    }
                                </facet>                                    
                            </key>
                    }
                    </facet>
                 </key>
                
           }
           </facet>
        </key> 
};


(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function facet:type($value as item()*, $type as xs:string?) as item()*{
    if($type != '') then  
        if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:decimal') then xs:decimal($value)
        else if($type = 'xs:integer') then xs:integer($value)
        else if($type = 'xs:long') then xs:long($value)
        else if($type = 'xs:int') then xs:int($value)
        else if($type = 'xs:short') then xs:short($value)
        else if($type = 'xs:byte') then xs:byte($value)
        else if($type = 'xs:float') then xs:float($value)
        else if($type = 'xs:double') then xs:double($value)
        else if($type = 'xs:dateTime') then xs:dateTime($value)
        else if($type = 'xs:date') then xs:date($value)
        else if($type = 'xs:gYearMonth') then xs:gYearMonth($value)        
        else if($type = 'xs:gYear') then xs:gYear($value)
        else if($type = 'xs:gMonthDay') then xs:gMonthDay($value)
        else if($type = 'xs:gMonth') then xs:gMonth($value)        
        else if($type = 'xs:gDay') then xs:gDay($value)
        else if($type = 'xs:duration') then xs:duration($value)        
        else if($type = 'xs:anyURI') then xs:anyURI($value)
        else if($type = 'xs:Name') then xs:Name($value)
        else $value
    else $value
};

(:~
 : XPath filter to be passed to main query
 : creates XPath based on facet:facet-definition//facet:sub-path.
 : @param $facet-def facet:facet-definition element
 : NOTE: need to do type checking here
 : NOTE: add range handling here. 
:)
declare function facet:facet-filter($facet-definitions as node()*)  as item()*{
    if($facet:fq != '') then
        string-join(
        for $facet in tokenize($facet:fq,';fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            if($facet-name = 'Corregimiento') then 
                concat('[descendant::tei:location/tei:region[@type="corregimiento"][normalize-space(.) = "',replace($facet-value,'"','""'),'"]',']')
            else if($facet-name = 'Repartimiento') then
                concat('[descendant::tei:location/tei:region[@type="repartimiento"]/tei:placeName[normalize-space(.) = "',replace($facet-value,'"','""'),'"]',']')
            else if($facet-name = 'Ciudad') then
                concat('[descendant::tei:location/tei:region[@type="ciudad"][normalize-space() = "',replace($facet-value,'"','""'),'"]',']')
            else if($facet-name = 'Pueblo') then
                concat('[descendant::tei:location/tei:settlement[@type="pueblo"][normalize-space() = "',replace($facet-value,'"','""'),'"]',']')
            else 
                for $facet in $facet-definitions//facet:facet-definition[@name = $facet-name]
                let $path := 
                             if(matches($facet/facet:group-by/facet:sub-path/text(), '^/@')) then concat('descendant::*/',substring($facet/descendant::facet:sub-path/text(),2))
                             else $facet/facet:group-by/facet:sub-path/text()
                return 
                    if($facet-value != '') then 
                        if($facet/facet:range) then
                            concat('[',$path,'[string(.) gt "', facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'" and string(.) lt "',facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@lt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'"]]')
                        else if($facet/facet:group-by[@function="facet:group-by-array"]) then 
                            concat('[',$path,'[matches(., "',$facet-value,'(\W|$)")]',']')
                        else if($facet/facet:group-by[@function="facet:spear-type"]) then 
                            concat('[',substring-before($path,'/name(.)'),'[name(.) = "',$facet-value,'"]',']')                    
                        else concat('[',$path,'[normalize-space(.) = "',replace($facet-value,'"','""'),'"]',']')
                    else(),'')    
    else ()   
};

(:~ 
 : Builds new facet params for html links.
 : Uses request:get-parameter-names() to get all current params 
 :)
declare function facet:url-params(){
    string-join(
    for $param in request:get-parameter-names()
    return 
        if($param = 'fq') then ()
        else if($param = 'start') then '&amp;start=1'
        else if(request:get-parameter($param, '') = ' ') then ()
        else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
};

(: HTML display functions :)

(:~
 : Create 'Remove' button 
 : Constructs new URL for user action 'remove facet'
:)
declare function facet:selected-facets-display($facets as node()*){
    for $facet in tokenize($facet:fq,';fq-')
    let $facet-name := substring-before($facet,':')
    let $new-fq := string-join(
                for $facet-param in tokenize($facet:fq,';fq-') 
                return 
                    if($facet-param = $facet) then ()
                    else concat(';fq-',$facet-param),'')
    let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
    return
        if($facet != '') then
            for $f in $facets//facet:facet[@name = $facet-name]
            let $fn := string($f/@name)
            let $label := string($f/facet:key[@value = substring-after($facet,concat($facet-name,':'))]/@label)
            let $value := if(starts-with($label,'http://syriaca.org/')) then 
                             facet:get-label($label)   
                          else $label
            return 
                if($value != '') then 
                    <span class="selected-facets label label-facet " title="Remove {$value}">
                        {concat($fn,': ', $value)} <a href="{$href}" class="facet icon"> x</a>
                    </span>
                else()
        else()
};

(:~
 : HTML for facet display
:)
declare function facet:html-list-facets-as-buttons($facets as node()*){
(facet:selected-facets-display($facets),
if($facets) then
    for $f in $facets/facet:facet
    let $count := count($f//facet:key)
    return 
        if($count gt 0) then 
            facet:html-facet($f, $count, 1)
        else $facets 
else ()
)    
};

(:~
 : HTML for each facet defined as facet-definition in facet-def.xml
 { if($level eq 1) then <span class="facet-group-label">{string($facet/@name)}</span> else () }
:)
declare function facet:html-facet($facet as node()*, $count as xs:integer?, $level as xs:integer?){
    <div class="facet-grp">
        <span class="facet-group-label">{string($facet/@name)}</span>
        <div class="facet-list show">
            {
                for $key at $l in subsequence($facet/facet:key,1,$facet/@show)    
                return facet:html-facet-key($facet, $key, $level)
             }
        </div>
        {
            if(count($facet/facet:key) gt xs:integer($facet/@show)) then
                (<div>More facets</div>,
                <a href="#">show more</a>)
            else()
          }
    </div>
};

(:~
 : HTML for each key
:)
declare function facet:html-facet-key($facet as node()*, $key as node()*, $level as xs:integer?){
    let $facet-query := replace(replace(concat(';fq-',string($facet/@name),':',string($key/@value)),';fq-;fq-;',';fq-'),';fq- ','')
    let $new-fq := 
                    if($facet:fq) then concat('fq=',$facet:fq,$facet-query)
                    else concat('fq=',$facet-query)
    let $active := if(contains($facet:fq,concat(';fq-',string($facet/@name),':',string($key/@value)))) then 'active' else ()
    return
    <span class="facet-key">
        {if($key/facet:facet/facet:key) then
             <a class="expand togglelink" 
                data-toggle="collapse" 
                data-target="#show{concat(replace(string($key/@label),'\s|-|\?|\[|\]',''),$key/@count,replace($key/facet:facet[1]/@name,' ',''))}" 
                href="#show{concat(replace(string($key/@label),'\s|-|\?|\[|\]',''),$key/@count,replace($key/facet:facet[1]/@name,' ',''))}" 
                data-text-swap=" - "> + </a>
        else()}
        <a href="?{$new-fq}{facet:url-params()}" class="facet-key-label">
            {facet:get-label(string($key/@label))} <span class="count"> ({string($key/@count)})</span>
        </a>
        {if($key/facet:facet) then
            <span id="show{concat(replace(string($key/@label),'\s|-|\?|\[|\]',''),$key/@count,replace($key/facet:facet[1]/@name,' ',''))}" class="collapse">{
                for $f in $key/facet:facet
                let $count := count($f/facet:key)
                let $level := count($f/ancestor-or-self::facet:facet)
                return facet:html-facet($f, $count, $level)            
            }</span>
        else ()}
    </span>
};

(:~
 : Syriaca.org specific function to label URI's with human readable labels. 
 : @param $uri Syriaca.org uri to be used for lookup. 
 : URI can be a record or a keyword
 : NOTE: this function will probably slow down the facets.
:)
declare function facet:get-label($uri as item()*){
if(starts-with($uri,'http://syriaca.org/')) then 
  if(contains($uri,'/keyword/')) then
    lower-case(functx:camel-case-to-words(substring-after($uri,'/keyword/'),' '))
  else 
      let $doc := collection($global:data-root)//tei:TEI[.//tei:idno = concat($uri,"/tei")][1]
      return 
      if (exists($doc)) then
        replace(string-join($doc/descendant::tei:fileDesc/tei:titleStmt[1]/tei:title[1]/text()[1],' '),' — ','')
      else $uri 
else $uri
};