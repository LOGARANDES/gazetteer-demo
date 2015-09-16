xquery version "3.0";

module namespace timeline="http://syriaca.org/timeline";

(:~
 : Module to build timeline json passed to http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js widget
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-08-05
:)
import module namespace json="http://www.json.org";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace global="http://syriaca.org/global" at "global.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:
    NOTES on display,
    headline should be person names perhaps Events: PersName
    credit syriaca.org?
    xqjson:serialize-json
:)
declare function timeline:timeline($data as node()*, $title as xs:string*){
(: Test for valid dates json:xml-to-json() May want to change some css styles for font:)
if($data/descendant-or-self::*[@when or @to or @from or @notBefore or @notAfter]) then 
    <div class="timeline">
        <script type="text/javascript" src="http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
        <script type="text/javascript">
        <![CDATA[
            $(document).ready(function() {
                var parentWidth = $(".timeline").width();
                createStoryJS({
                    start:      'start_at_end',
                    type:       'timeline',
                    width:      "'" +parentWidth+"'",
                    height:     '375',
                    source:     ]]>{xqjson:serialize-json(timeline:format-dates($data, $title))}<![CDATA[,
                    embed_id:   'my-timeline'
                    });
                });
                ]]>
        </script>
    <div id="my-timeline"/>
    <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a></p>
    </div>
else ()
};


declare function timeline:format-dates($data as node()*, $title as xs:string*){
let $timeline-title := if($title != '') then $title else 'Timeline'
return 
    <json type="object">
        <pair name="timeline" type="object">
            <pair name="headline" type="string">{$timeline-title}</pair>
            <pair name="type" type="string">default</pair>
            <pair name="text" type="string"></pair>
            <pair name="asset" type="object">
                <pair name="media" type="string">{$global:app-url}</pair>
                <pair name="credit" type="string">{$global:app-title}</pair>
                <pair name="caption" type="string">Events for {$timeline-title}</pair>
            </pair>  
            <pair name="date" type="array">
            {
                (
                timeline:get-birth($data), 
                timeline:get-death($data), 
                timeline:get-floruit($data), 
                timeline:get-state($data), 
                timeline:get-events($data)
                )
            }
            </pair>
        </pair>
    </json>
};

(:~
 : Build birth date ranges
 : @param $data as node
:)
declare function timeline:get-birth($data as node()*) as node()?{
    if($data/descendant-or-self::tei:birth) then
        let $birth-date := $data/descendant-or-self::tei:birth[1]
        let $start := if($birth-date/@when) then string($birth-date/@when)
                      else if($birth-date/@from) then string($birth-date/@from)
                      else if($birth-date/@notBefore) then string($birth-date/@notBefore)
                      else ()
        let $end :=   if($birth-date/@when) then string($birth-date/@when)
                      else if($birth-date/@to) then string($birth-date/@to)
                      else if($birth-date/@notAfter) then string($birth-date/@notAfter)
                      else ()                    
        return
            <pair type="object">
                    <pair name="startDate" type="string">
                    {
                        if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                        else replace($start,'-',',')
                        }
                    </pair>
                    <pair name="endDate" type="string">
                    {
                        if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                        else replace($end,'-',',')
                    }
                    </pair>
                    <pair name="headline" type="string">{$birth-date/text()} Birth</pair>
            </pair>
    else () 
};

(:~
 : Build death date ranges
 : @param $data as node
:)
declare function timeline:get-death($data as node()*) as node()?{
       if($data/descendant-or-self::tei:death) then 
        let $death-date := $data//tei:death[1]
        let $start := if($death-date/@when) then string($death-date/@when)
                      else if($death-date/@from) then string($death-date/@from)
                      else if($death-date/@notBefore) then string($death-date/@notBefore)
                      else ()
        let $end :=   if($death-date/@when) then string($death-date/@when)
                      else if($death-date/@to) then string($death-date/@to)
                      else if($death-date/@notAfter) then string($death-date/@notAfter)
                      else () 
        return
            <pair type="object">
                <pair name="startDate" type="string">
                    {
                        if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                        else replace($start,'-',',')
                        }
                    </pair>
                    <pair name="endDate" type="string">
                    {
                        if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                        else replace($end,'-',',')
                    }
                    </pair>
                    <pair name="headline" type="string">{$death-date/text()} Death</pair>
            </pair>
    else () 
};

(:~
 : Build floruit date ranges
 : @param $data as node
:)
declare function timeline:get-floruit($data as node()*) as node()*{
   if($data/descendant-or-self::tei:floruit) then 
        for $floruit-date in $data//tei:floruit
        let $start := if($floruit-date/@when) then string($floruit-date/@when)
                      else if($floruit-date/@from) then string($floruit-date/@from)
                      else if($floruit-date/@notBefore) then string($floruit-date/@notBefore)
                      else ()
        let $end :=   if($floruit-date/@when) then string($floruit-date/@when)
                      else if($floruit-date/@to) then string($floruit-date/@to)
                      else if($floruit-date/@notAfter) then string($floruit-date/@notAfter)
                      else () 
        return
            <pair type="object">
                    <pair name="startDate" type="string">
                    {
                        if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                        else replace($start,'-',',')
                        }
                    </pair>
                    <pair name="endDate" type="string">
                    {
                        if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                        else replace($end,'-',',')
                    }
                    </pair>
                    <pair name="headline" type="string">{$floruit-date/text()} Floruit</pair>
            </pair>
    else () 
};

(:~
 : Build state date ranges
 : @param $data as node
:)
declare function timeline:get-state($data as node()*) as node()*{
    if($data/descendant-or-self::tei:state) then 
        for $state-date in $data//tei:state
        let $start := if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notBefore) then string($state-date/@notBefore)
                      else if($state-date/@from) then string($state-date/@from)
                      else ()
        let $end :=   if($state-date/@when) then string($state-date/@when)
                      else if($state-date/@notAfter) then string($state-date/@notAfter)
                      else if($state-date/@to) then string($state-date/@to)
                      else () 
        let $office := if($state-date/@role) then concat(' ',string($state-date/@role)) else concat(' ',string($state-date/@type))                 
        return
                <pair type="object">
                    <pair name="startDate" type="string">
                    {
                        if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                        else replace($start,'-',',')
                        }
                    </pair>
                    <pair name="endDate" type="string">
                    {
                        if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                        else replace($end,'-',',')
                    }
                    </pair>
                    <pair name="headline" type="string">{$state-date/text()} {$office}</pair>
                </pair>
    else () 
};

(:~
 : Build events date ranges
 : @param $data as node
 : build end and start?
 replace(string($event/descendant-or-self::*[@from][1]/@from),'-',',')
:)
declare function timeline:get-events($data as node()*) as node()*{
     if($data/descendant-or-self::tei:event) then 
        for $event in $data/descendant-or-self::tei:event
        let $event-content := normalize-space(string-join($event/descendant::*/text(),' '))
        let $start := if($event/descendant-or-self::*/@when) then $event/descendant-or-self::*[@when][1]/@when
                      else if($event/descendant-or-self::*/@notBefore) then $event/descendant-or-self::*[@notBefore][1]/@notBefore
                      else if($event/descendant-or-self::*/@from) then $event/descendant-or-self::*[@from][1]/@from
                      else ()
        let $end :=   if($event/descendant-or-self::*/@when) then $event/descendant-or-self::*[@when][1]/@when
                      else if($event/descendant-or-self::*/@notAfter) then $event/descendant-or-self::*[@notAfter][1]/@notAfter
                      else if($event/descendant-or-self::*/@to) then $event/descendant-or-self::*[@to][1]/@to
                      else ()         
        return
                <pair type="object">
                    <pair name="startDate" type="string">
                    {
                        if(starts-with($start,'-')) then concat('-',tokenize($start,'-')[2])
                        else replace($start,'-',',')
                        }
                    </pair>
                    <pair name="endDate" type="string">
                    {
                        if(starts-with($end,'-')) then concat('-',tokenize($end,'-')[2])
                        else replace($end,'-',',')
                    }
                    </pair>
                    <pair name="headline" type="string">{concat(substring($event-content,1, 30),'...')}</pair>
                    <pair name="text" type="string">{$event-content}</pair>
                </pair>
    else ()   
};