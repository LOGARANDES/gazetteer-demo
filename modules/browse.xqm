xquery version "3.0";
(:~  
 : Builds browse pages for Syriac.org sub-collections 
 : Alphabetical English and Syriac Browse lists, browse by type, browse by date, map browse. 
 :
 : @see lib/facet.xqm for facets
 : @see lib/global.xqm for global variables
 : @see lib/paging.xqm for paging functionality
 : @see lib/maps.xqm for map generation
 : @see browse-spear.xqm for additional SPEAR browse functions 
 :)

module namespace browse="http://syriaca.org/browse";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";
import module namespace facet="http://expath.org/ns/facet" at "lib/facet.xqm";
import module namespace facet-defs="http://syriaca.org/facet-defs" at "facet-defs.xqm";
import module namespace page="http://syriaca.org/page" at "lib/paging.xqm";
import module namespace maps="http://syriaca.org/maps" at "lib/maps.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "content-negotiation//tei2html.xqm";
import module namespace functx="http://www.functx.com";
import module namespace templates="http://exist-db.org/xquery/templates";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";

(:~ 
 : Parameters passed from the url
 : @param $browse:coll selects collection (persons/places ect) from browse.html  @depreciated use $browse:collection
 : @param $browse:type selects doc type filter eg: place@type
 : @param $browse:view selects language for browse display
 : @param $browse:date selects doc by date
 : @param $browse:sort passes browse by letter for alphabetical browse lists
 :)
declare variable $browse:coll {request:get-parameter('coll', '')};
declare variable $browse:collection {request:get-parameter('collection', '')};
declare variable $browse:type {request:get-parameter('type', '')};
declare variable $browse:lang {request:get-parameter('lang', '')};
declare variable $browse:view {request:get-parameter('view', '')};
declare variable $browse:alpha-filter {request:get-parameter('alpha-filter', '')};
declare variable $browse:sort-element {request:get-parameter('sort-element', 'title')};
declare variable $browse:sort-order {request:get-parameter('sort-order', '')};
declare variable $browse:date {request:get-parameter('date', '')};
declare variable $browse:start {request:get-parameter('start', 1) cast as xs:integer};
declare variable $browse:perpage {request:get-parameter('perpage', 25) cast as xs:integer};
declare variable $browse:fq {request:get-parameter('fq', '')};

(:~ 
 : Set a default value for language, default sets to English. 
 : @param $browse:lang language parameter from URL
:)
declare variable $browse:computed-lang{ 
    if($browse:lang != '') then $browse:lang
    else ()
};
 
(:~
 : Build initial browse results based on parameters
 : @param $collection collection name passed from html, should match data subdirectory name or tei series name
 : @param $element element used to filter browse results, passed from html
 : @param $facets facet xml file name, relative to collection directory
 : Calls data function data:get-browse-data($collection as xs:string*, $series as xs:string*, $element as xs:string?)
:)  
declare function browse:get-all($node as node(), $model as map(*), $collection as xs:string*, $element as xs:string?){
    map{"browse-data" : data:get-browse-data($collection, $element) }
};

(:~
 : Display paging functions in html templates
:)
declare %templates:wrap function browse:pageination($node as node()*, $model as map(*), $collection as xs:string?, $sort-options as xs:string*){
   page:pages($model("browse-data"), $browse:start, $browse:perpage,'', $sort-options)
};

(:
 : Display facets from HTML page 
 : For place records map coordinates
 : For other records, check for place relationships
 : @param $collection passed from html 
 : @param $facet relative (from collection root) path to facet definition 
:)
declare function browse:display-facets($node as node(), $model as map(*), $collection as xs:string?, $facets as xs:string?){
let $hits := $model("browse-data")
let $facet-config := doc(concat($global:app-root, '/', string(global:collection-vars($collection)/@app-root),'/',$facets))
return 
    if($facet-config) then 
        facet:html-list-facets-as-buttons(facet:count($hits, $facet-config/descendant::facet:facet-definition))
    else if(exists(facet-defs:facet-definition($collection))) then 
        facet:html-list-facets-as-buttons(facet:count($hits, facet-defs:facet-definition($collection)/child::*))
    else ()               
};

(:
 : Main HTML display of browse results
 : @param $collection passed from html 
:)
declare function browse:results-panel($node as node(), $model as map(*), $collection, $sort-options as xs:string*, $facets as xs:string?){
    let $hits := $model("browse-data")
    return 
       if($browse:view = 'map') then 
            <div class="col-md-12 map-lg">
                <div class="browse-map">
                <div id="map-filters" class="map-overlay">
                    <span class="filter-label">Filter Map
                        <a class="pull-right small togglelink text-info" data-toggle="collapse" data-target="#filterMap" href="#filterMap" data-text-swap="+ Show"> - Hide </a>
                    </span>
                    <div class="collapse in" id="filterMap">
                    {browse:display-facets($node, $model,$collection, $facets)} 
                    </div>
                </div>
                {browse:get-map($hits)}
                </div>
            </div>           
        else if($browse:view = 'all' or $browse:view = 'ܐ-ܬ' or $browse:view = 'ا-ي' or $browse:view = 'other') then 
            <div class="col-md-12">
                <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                <div>{browse:display-hits($hits)}</div>
            </div>
        else 
            <div class="col-md-12">
                {(
                <div class="float-container">
                    {browse:browse-abc-menu()}
                    <div class="pull-right" style="marign-top:-2em;">
                         <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                    </div>
                </div>,
                <h3>{(
                    if(($browse:lang = 'syr') or ($browse:lang = 'ar')) then (attribute dir {"rtl"}, attribute lang {"syr"}, attribute class {"label pull-right"}) 
                    else attribute class {"label"},
                    if($browse:alpha-filter != '') then $browse:alpha-filter else 'A')}</h3>,
                <div class="en-list">
                    <div class="row">
                        <div class="col-sm-12">
                            {browse:display-hits($hits)}
                        </div>
                    </div>
                </div>,
                <div class="float-container">
                    <br/>
                    <div class="pull-right" style="marign-top:-2em;">
                         <div>{page:pages($hits, $browse:start, $browse:perpage,'', $sort-options)}</div>
                    </div>
                </div>
                )}
            </div>
};

declare function browse:total-places(){
    count(collection($global:data-root || '/places/tei')//tei:place)
};

(:
 : Display map from HTML page 
 : For place records map coordinates
 : For other records, check for place relationships
 : @param $collection passed from html 
:)
declare function browse:display-map($node as node(), $model as map(*), $collection, $sort-options as xs:string*){
let $hits := $model("browse-data")[descendant::tei:location[@type='gps']/tei:geo]
return maps:build-map($hits, count($hits))                    
};

(: Display map :)
declare function browse:get-map($hits){
    if($hits/descendant::tei:body/tei:listPlace/descendant::tei:geo) then 
            maps:build-map($hits[descendant::tei:geo], count($hits))
    else ()
};

(:
 : Pass each TEI result through xslt stylesheet
:)
declare function browse:display-hits($hits){
    for $hit in subsequence($hits, $browse:start,$browse:perpage)
    let $sort-title := 
        if($browse:computed-lang != 'en' and $browse:computed-lang != 'syr') then 
            <span class="sort-title" lang="{$browse:computed-lang}" xml:lang="{$browse:computed-lang}">{(if($browse:computed-lang='ar') then attribute dir { "rtl" } else (), string($hit/@sort-title))}</span> 
        else () 
    let $uri :=  replace($hit/descendant::tei:publicationStmt/tei:idno[1],'/tei','')
    return 
        <div xmlns="http://www.w3.org/1999/xhtml" style="border-bottom:1px dotted #eee; padding-top:.5em" class="short-rec-result">
            {($sort-title, tei2html:summary-view($hit, $browse:computed-lang, $uri))}
        </div>
};



(:~
 : Browse Alphabetical Menus
:)
declare function browse:browse-abc-menu(){
    <div class="browse-alpha tabbable">
        <ul class="list-inline">
        {
            if(($browse:lang = 'syr')) then  
                for $letter in tokenize('ܐ ܒ ܓ ܕ ܗ ܘ ܙ ܚ ܛ ܝ ܟ ܠ ܡ ܢ ܣ ܥ ܦ ܩ ܪ ܫ ܬ ALL', ' ')
                return 
                    <li class="syr-menu {if($browse:alpha-filter = $letter) then "selected" else()}" lang="syr"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
            else if(($browse:lang = 'ar')) then  
                for $letter in tokenize('ALL ا ب ت ث ج ح  خ  د  ذ  ر  ز  س  ش  ص  ض  ط  ظ  ع  غ  ف  ق  ك ل م ن ه  و ي', ' ')
                return 
                    <li class="ar-menu {if($browse:alpha-filter = $letter) then "selected" else()}" lang="ar"><a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
            else if($browse:lang = 'ru') then 
                for $letter in tokenize('А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я ALL',' ')
                return 
                <li>{if($browse:alpha-filter = $letter) then attribute class {"selected"} else()}<a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
            (: Used by SPEAR :)
            else if($browse:view = 'persons') then  
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z Anonymous All', ' ')
                return
                    <li>{if($browse:alpha-filter = $letter) then attribute class {"selected"} else()}<a href="?view={$browse:view}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
            (: Used by SPEAR :)
            else if($browse:view = 'places') then  
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z All', ' ')
                return
                     <li>{if($browse:alpha-filter = $letter) then attribute class {"selected"} else()}<a href="?view={$browse:view}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>            
            else                
                for $letter in tokenize('A B C D E F G H I J K L M N O P Q R S T U V W X Y Z ALL', ' ')
                return
                    <li>{if($browse:alpha-filter = $letter) then attribute class {"selected badge"} else()}<a href="?lang={$browse:lang}&amp;alpha-filter={$letter}{if($browse:view != '') then concat('&amp;view=',$browse:view) else()}{if(request:get-parameter('element', '') != '') then concat('&amp;element=',request:get-parameter('element', '')) else()}">{$letter}</a></li>
        }
        </ul>
    </div>
};
(:~
 : Browse Type Menus
:)
declare function browse:browse-type($collection){  
    <ul class="nav nav-tabs nav-stacked">
        {
            if($collection = ('places','geo')) then 
                    for $types in collection($global:data-root || '/places/tei')//tei:place
                    group by $place-types := $types/@type
                    order by $place-types ascending
                    return
                        <li> {if($browse:type = replace(string($place-types),'#','')) then attribute class {'active'} else '' }
                            <a href="?view=type&amp;type={$place-types}">
                            {if(string($place-types) = '') then 'unknown' else replace(string($place-types),'#|-',' ')}  <span class="count"> ({count($types)})</span>
                            </a> 
                        </li>
            else  () 
        }
    </ul>

};

(:
 : Build Tabs dynamically.
 : @param $text tab text, from template
 : @param $param tab parameter passed to url from template
 : @param $value value of tab parameter passed to url from template
 : @param $alpha-filter-value for abc menus. 
 : @param $default indicates initial active tab
:)
declare function browse:tabs($node as node(), $model as map(*), $text as xs:string?, $param as xs:string?, $value as xs:string?, $alpha-filter-value as xs:string?, $element as xs:string?, $default as xs:string?){ 
let $s := if($alpha-filter-value != '') then $alpha-filter-value else if($browse:alpha-filter != '') then $browse:alpha-filter else 'A'
return
    <li xmlns="http://www.w3.org/1999/xhtml">{
        if($default = 'true' and empty(request:get-parameter-names())) then  attribute class {'active'}
        (:else if(($value='en' and $browse:computed-lang = 'en')) then attribute class {'active'}:) 
        else if($value = $browse:view) then attribute class {'active'}
        else if($value = $browse:lang) then attribute class {'active'}
        (:else if($value = 'English' and empty(request:get-parameter-names())) then attribute class {'active'}:)
        else ()
        }
        <a href="browse.html?{$param}={$value}{if($param = 'lang') then concat('&amp;alpha-filter=',$s) else ()}{if($element != '') then concat('&amp;element=',$element) else()}">
        {if($value = 'syr' or $value = 'ar') then (attribute lang {$value},attribute dir {'ltr'}) else ()}
        {$text}
        </a>
    </li> 
};