xquery version "3.0";
(:~
 : Builds tei conversions. 
 : Used by oai, can be plugged into other outputs as well.
 :)
 
module namespace tei2tsv="http://srophe.org/srophe/tei2tsv";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace util="http://exist-db.org/xquery/util";

declare function tei2tsv:value($nodes as item()*){
(:let $q := codepoints-to-string(34)
return concat('"',replace(normalize-space(string-join($nodes//text(),' ')),$q,concat($q,$q)),'"')
:)normalize-space(string-join($nodes//text(),' '))
};

declare function tei2tsv:tei2tsv($nodes as node()*) {
let $headers :=concat(string-join(('title', 'uri','principal','principal2','principal3','editor', 'editor2', 'editor3', 'editor4', 'published',
                 'placeName-standardized','placeName-standardized-Spanish','placeName-standardized-Andean',
                 'placeName-verbatim','placeName-other','placeName-other',
                 'location-ancient-audiencia','location-ancient-ciudad','location-ancient-repartimiento-standardized',
                 'location-ancient-repartimiento-verbatim','location-ancient-repartimiento-standardized',
                 'location-ancient-repartimiento-verbatim','location-ancient-pueblo','location-modern-country', 
                 'location-modern-province', 'location-modern-department', 'location-modern-pueblo',
                 'latitude','longitude','location','note', 'note2', 'note3','bibl1','bibl2','bibl3','bibl4','bibl5',
                 'note-admin-moved','note-admin-move-ref',
                 'note-admin-move-date', 'note-admin-delete', 'note-admin-other'),"&#x9;"),
                  '&#xa;')
let $data :=                   
    string-join(
    for $record in $nodes//tei:TEI
    let $n := $record/descendant::tei:listPlace/tei:place
    let $title := tei2tsv:value($record/descendant::tei:title[1])
    let $uri := replace($record/descendant::tei:idno[1],'/tei','')
    let $principal := tei2tsv:value($record/descendant::tei:principal[1])
    let $principal2 := tei2tsv:value($record/descendant::tei:principal[2])
    let $principal3 := tei2tsv:value($record/descendant::tei:principal[3])
    let $editor := tei2tsv:value($record/descendant::tei:editor[1])
    let $editor2 := tei2tsv:value($record/descendant::tei:editor[2])
    let $editor3 := tei2tsv:value($record/descendant::tei:editor[3])
    let $editor4 := tei2tsv:value($record/descendant::tei:editor[4])
    let $published := tei2tsv:value($record/descendant::tei:publicationStmt/tei:date)
    let $placeName1 := tei2tsv:value($n/tei:placeName[@type="standardized"][1])
    let $placeName2 := tei2tsv:value($n/tei:placeName[@type="standardized-Spanish"][1])
    let $placeName3 := tei2tsv:value($n/tei:placeName[@type="standardized-Andean"][1])
    let $placeName4 := tei2tsv:value($n/tei:placeName[@type="verbatim"][1])
    let $placeName5 := tei2tsv:value($n/tei:placeName[@type="verbatim"][1])
    let $placeName6 := tei2tsv:value($n/tei:placeName[5])
    let $placeName6 := tei2tsv:value($n/tei:placeName[6])
    let $audiencia := tei2tsv:value($n/tei:location/tei:region[@type='audiencia'])
    let $ciudad := tei2tsv:value($n/tei:location[@type='ancient']/tei:region[@type='ciudad'])
    let $repartimiento-standardized := tei2tsv:value($n/tei:location[@type='ancient']/tei:region[@type='repartimiento'][1]/tei:placeName[@type='standardized'])
    let $repartimiento-verbatim := tei2tsv:value($n/tei:location[@type='ancient']/tei:region[@type='repartimiento'][1]/tei:placeName[@type='verbatim'])
    let $repartimiento2-standardized := tei2tsv:value($n/tei:location[@type='ancient']/tei:region[@type='repartimiento'][2]/tei:placeName[@type='standardized'])
    let $repartimiento2-verbatim := tei2tsv:value($n/tei:location[@type='ancient']/tei:region[@type='repartimiento'][2]/tei:placeName[@type='verbatim'])
    let $pueblo := tei2tsv:value($n/tei:location[@type='ancient']/tei:settlement[@type='pueblo'])
    let $country := tei2tsv:value($n/tei:location[@type='modern']/tei:country)
    let $province := tei2tsv:value($n/tei:location[@type='modern']/tei:region[@type='province'])
    let $department := tei2tsv:value($n/tei:location[@type='modern']/tei:region[@type='department'])
    let $pueblo-modern := tei2tsv:value($n/tei:location[@type='modern']/tei:settlement[@type='pueblo'])
    (:let $location-gps := tei2tsv:value($n/tei:location[@type='gps']/tei:geo):)
    let $lat := tokenize($n/tei:location[@type='gps']/tei:geo,' ')[1]
    let $long := tokenize($n/tei:location[@type='gps']/tei:geo,' ')[2]
    let $location := tei2tsv:value($n/tei:location[not(@type='gps') and not(@type='ancient') and not(@type='modern')]/tei:geo)
    let $note := tei2tsv:value($n/tei:note[1])
    let $note2 := tei2tsv:value($n/tei:note[2])
    let $note3 := tei2tsv:value($n/tei:note[3])
    let $bibl1 := tei2tsv:value($n/tei:bibl[1])
    let $bibl2 := tei2tsv:value($n/tei:bibl[2])
    let $bibl3 := tei2tsv:value($n/tei:bibl[3])
    let $bibl4 := tei2tsv:value($n/tei:bibl[4])
    let $bibl5 := tei2tsv:value($n/tei:bibl[5])
    let $note-admin := tei2tsv:value($n/tei:note[@type='administrative'][1])
    let $note-admin2 := tei2tsv:value($n/tei:note[@type='administrative'][2])
    let $note-admin3 := tei2tsv:value($n/tei:note[@type='administrative'][3])
    let $note-admin4 := tei2tsv:value($n/tei:note[@type='administrative'][4])
    let $note-admin5 := tei2tsv:value($n/tei:note[@type='administrative'][5])
    return 
        concat(
            string-join(($title,$uri,$principal,$principal2,$principal3,$editor,$editor2,$editor3,$editor4,$published,
                $placeName1,$placeName2,$placeName3,$placeName4,$placeName5,$placeName6,
                $audiencia,$ciudad,$repartimiento-standardized,$repartimiento-verbatim,$repartimiento2-standardized,$repartimiento2-verbatim,$pueblo,
                $country,$province,$department,$pueblo-modern,
                $lat,$long,$location, 
                $note,$note2,$note3,
                $bibl1,$bibl2,$bibl3,$bibl4,$bibl5,
                $note-admin,$note-admin2,$note-admin3,$note-admin4,$note-admin5
            ),"&#x9;"),'&#xa;'))
return concat($headers,($data))    
};
