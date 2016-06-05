xquery version "3.0";
(:
 : Run modules as needed
:)
import module namespace xrest="http://exquery.org/ns/restxq/exist" at "java:org.exist.extensions.exquery.restxq.impl.xquery.exist.ExistRestXqModule";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace cito = "http://purl.org/spar/cito";
declare namespace cnt = "http://www.w3.org/2011/content";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace foaf = "http://xmlns.com/foaf/0.1";
declare namespace geo = "http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace gn = "http://www.geonames.org/ontology#";
declare namespace lawd = "http://lawd.info/ontology";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";

declare option exist:serialize "method=xml media-type=application/rss+xml omit-xml-declaration=no indent=yes";

xrest:register-module(xs:anyURI($global:app-root || '/modules/rest.xqm'))

(:
rdfq:build-collex(
for $recs in collection('/db/apps/srophe-data/data/places/tei')
return $recs)
:)