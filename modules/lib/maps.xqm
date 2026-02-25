xquery version "3.0";

module namespace maps = "http://srophe.org/srophe/maps";

(:~
 : Module builds leafletjs maps and/or Google maps
 : Pulls geoJSON from http://syriaca.org/geojson module. 
 : 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)
import module namespace geojson = "http://srophe.org/srophe/geojson" at "../content-negotiation/geojson.xqm";
import module namespace global = "http://srophe.org/srophe/global" at "global.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : Selects map rendering based on config.xml entry
:)
declare function maps:build-map($nodes as node()*, $total-count as xs:integer?){
if($global:app-map-option = 'google') then maps:build-google-map($nodes)
else maps:build-leaflet-map($nodes,$total-count)
};

(:~
 : Build leafletJS map
:)
declare function maps:build-leaflet-map($nodes as node()*, $total-count as xs:integer?){
    <div id="map-data" style="margin-bottom:3em;">
         <script type="text/javascript" src="{$global:nav-base}/resources/leaflet/leaflet.js"/>
        <script type="text/javascript" src="{$global:nav-base}/resources/leaflet/leaflet.awesome-markers.min.js"/>
        <!--
        <script src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js" type="text/javascript"/>
        <script src="http://isawnyu.github.com/awld-js/awld.js?autoinit" type="text/javascript"/>
        -->
        <div id="map"/>
        {
            if($total-count gt 0) then 
               <div class="hint map pull-right small">
                * This map displays {count($nodes)} of {$total-count} places. 
               </div>
            else ()
            }
        <script type="text/javascript">
            <![CDATA[
            var terrain = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'});
                                
            /* Not added by default, only through user control action */
                                 
            var placesgeo = ]]>{geojson:geojson($nodes)}
            <![CDATA[                                
            var sropheIcon = L.Icon.extend({
                                            options: {
                                                iconSize:     [38, 38],
                                                iconAnchor:   [22, 94],
                                                popupAnchor:  [-3, -76]
                                                }
                                            });
                                            var redIcon =
                                                L.AwesomeMarkers.icon({
                                                    icon:'fa-circle',
                                                    markerColor: 'red'
                                                }),
                                            orangeIcon =  
                                                L.AwesomeMarkers.icon({
                                                    icon:'fa-circle',
                                                    markerColor: 'orange'
                                                }),
                                            purpleIcon = 
                                                L.AwesomeMarkers.icon({
                                                    icon:'fa-circle',
                                                    markerColor: 'purple'
                                                }),
                                            blueIcon =  L.AwesomeMarkers.icon({
                                                    icon:'fa-circle',
                                                    markerColor: 'blue'
                                                });
                                        
            var geojson = L.geoJson(placesgeo, {onEachFeature: function (feature, layer){
                                            var popupContent = 
                                            "<a href='" + feature.properties.uri + "' class='map-pop-title'>" +
                                            feature.properties.name + "</a>" + 
                                            (feature.properties.desc ? "<span class='map-pop-desc'>"+ feature.properties.desc +"</span>" : "");
                                            layer.bindPopup(popupContent);
                                            switch (feature.properties.type) {
                                                case 'born-at': return layer.setIcon(orangeIcon);
                                                case 'died-at':   return layer.setIcon(redIcon);
                                                case 'has-literary-connection-to-place':   return layer.setIcon(purpleIcon);
                                                case 'has-relation-to-place':   return layer.setIcon(blueIcon);
                                            }
                                            
                                        }
                                })
        var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 5});     
        terrain.addTo(map);
                                        
       L.control.layers({
                        "Terrain (default)": terrain}).addTo(map);
        geojson.addTo(map);   
        ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};

(:~
 : Build Google maps
:)
declare function maps:build-google-map($nodes as node()*){
    let $key := doc($global:app-root || '/config.xml')//*:map-key/text()
    return
    <div id="map-data" style="margin-bottom:3em;">
       <div id="map" class="map-lg"/>
       <div class="hint map pull-right">* {count($nodes)} places have coordinates and are shown on this map.</div>
        <script type="text/javascript">
          <![CDATA[

            var map;
            
            function initMap(){
                var bounds = new google.maps.LatLngBounds();
                map = new google.maps.Map(document.getElementById('map'), {
                    center: new google.maps.LatLng(0,0),
                    mapTypeId: google.maps.MapTypeId.TERRAIN
                });

                var placesgeo = ]]>{geojson:geojson($nodes)}
                <![CDATA[ 
                
                var infoWindow = new google.maps.InfoWindow();
                
                for(var i = 0, length = placesgeo.features.length; i < length; i++) {
                    var data = placesgeo.features[i]
                    var coords = data.geometry.coordinates;
                    var latLng = new google.maps.LatLng(coords[1],coords[0]);
                    var marker = new google.maps.Marker({
                        position: latLng,
                        map:map
                    });
                    
                    // Creating a closure to retain the correct data, notice how I pass the current data in the loop into the closure (marker, data)
         			(function(marker, data) {
         
         				// Attaching a click event to the current marker
         				google.maps.event.addListener(marker, "click", function(e) {
         					infoWindow.setContent("<a href='" + data.properties.uri + "'>" + data.properties.name + "</a>");
         					infoWindow.open(map, marker);
         				});
         
         
         			})(marker, data);
                    bounds.extend(latLng);
                }
                
                // This is needed to set the zoom after fitbounds, 
                google.maps.event.addListener(map, 'zoom_changed', function() {
                    zoomChangeBoundsListener = 
                        google.maps.event.addListener(map, 'bounds_changed', function(event) {
                            if (this.getZoom() > 10 && this.initialZoom == true) {
                                // Change max/min zoom here
                                this.setZoom(10);
                                this.initialZoom = false;
                            }
                        google.maps.event.removeListener(zoomChangeBoundsListener);
                    });
                });
                map.initialZoom = true;
                map.fitBounds(bounds);
            }

            //google.maps.event.addDomListener(window, 'load', initMap)

        ]]>
        </script>
        <script async="async" defer="defer" src="https://maps.googleapis.com/maps/api/js?key={$key}&amp;callback=initMap"></script> 
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};
