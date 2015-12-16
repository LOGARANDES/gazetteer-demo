
LOGAR
=======
An adaptation of Syriaca.org: Gazetteer App [https://github.com/srophe/gazetteer-demo]

An eXist-db app for gazetteer data. 

This repository is a subset of the Syriac.org app containing only code for the Gazetteer. Forked from [https://github.com/srophe/srophe-eXist-app] gazetteer branch.
All publications of Syriaca.org are made available online in a free and open format using the Creative Commons licenses.

The app can be installed using the latest build from: APP-ROOT/releases

Or can be customized and rebuilt using ant. [https://ant.apache.org/]


### Dependencies
#### TEI data 
Syriaca.org TEI data for publications is available: [https://github.com/srophe/srophe-app-data]
The data must be packaged and deployed to your eXist instance in order to use the syriaca.org app. 

A different data repository can be used, and specified in the config.xml file, TEI structure should be similiar. 

#### Additional dependancies 
Check that the following packages/libraries are deployed in eXist before deploying the srophe-eXist-app:
* eXist-db Shared apps: [http://exist-db.org:8098/exist/apps/public-repo/packages/shared.html]
* JSON Parser and Serializer for XQuery .1.6 + : [https://github.com/joewiz/xqjson]
* Functx Library: [http://exist-db.org:8098/exist/apps/public-repo/packages/functx.html]

Packages can be deployed via the eXistdb dashboard. 

