xquery version "3.0";

(:~
 : Build email from form returns error or sucess message to ajax function
 :)

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mail="http://exist-db.org/xquery/mail";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace recap = "http://www.exist-db.org/xquery/util/recapture" at "recaptcha.xqm";

declare option exist:serialize "method=xml media-type=text/xml indent=yes";

declare function local:recaptcha(){
(: Need to use cryptographic module to decrypt environment variable, also need to run as admin to get environment variable. :)
let $recapture-private-key := "ADD KEY" 
return 
    recap:validate($recapture-private-key, 
    request:get-parameter("g-recaptcha-response",()))
};

(:~ 
 : Populate email addresses. 
 : Uses values defined in config.xml
:)

declare function local:get-emails(){
for $e-address in $global:get-config//contact/text()
return 
    <to>{$e-address}</to>
};

declare function local:build-message(){
let $place := if(request:get-parameter('id','')) then concat('for ',request:get-parameter('id','')) else ''
let $place-uri := if(request:get-parameter('id','')) then concat('Place: http://logar.edu/place/',request:get-parameter('id','')) else ''
return
  <mail>
    <from>LOGAR.edu &lt;s.wernke@vanderbilt.edu&gt;</from>
    {local:get-emails()}
    <subject>{request:get-parameter('subject','')} for {request:get-parameter(' place ','')} {request:get-parameter('id','')}</subject>
    <message>
      <xhtml>
           <html>
               <head>
                 <title>{request:get-parameter('subject','')}</title>
               </head>
               <body>
                 <p>Name: {request:get-parameter('name','')}</p>
                 <p>e-mail: {request:get-parameter('email','')}</p>
                 <p>Subject: {request:get-parameter('subject','')} {$place}</p>
                 <p>{$place-uri}</p>
                 <p>{request:get-parameter('comments','')}</p>
              </body>
           </html>
      </xhtml>
    </message>
  </mail>
};

let $cache := current-dateTime()
return 
    if(exists(request:get-parameter('email','')) and request:get-parameter('email','') != '') 
        then 
            if(exists(request:get-parameter('comments','')) and request:get-parameter('comments','') != '') 
              then
               if(local:recaptcha() = true()) then 
                 if (mail:send-email(local:build-message(),"library.vanderbilt.edu", ()) ) then
                   <h4>Thank you. Your message has been sent.</h4>
                 else
                   <h4>Could not send message.</h4>
                else 'Recaptcha fail'   
            else  <h4>Incomplete form.</h4>
   else  <h4>Incomplete form.</h4>