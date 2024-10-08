<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:template name="config">
		<options>
		</options>
		<properties> <!--  accessible at run time -->
			<html>4</html>
			<language>fr</language>
			<calendar.label>...</calendar.label>
			<calendar.day0>Lun</calendar.day0>
			<calendar.day1>Mar</calendar.day1>
			<calendar.day2>Mer</calendar.day2>
			<calendar.day3>Jeu</calendar.day3>
			<calendar.day4>Ven</calendar.day4>
			<calendar.day5>Sam</calendar.day5>
			<calendar.day6>Dim</calendar.day6>
			<calendar.initDay>0</calendar.initDay>
			<calendar.month0>Janvier</calendar.month0>
			<calendar.month1>Février</calendar.month1>
			<calendar.month2>Mars</calendar.month2>
			<calendar.month3>Avril</calendar.month3>
			<calendar.month4>Mai</calendar.month4>
			<calendar.month5>Juin</calendar.month5>
			<calendar.month6>Juillet</calendar.month6>
			<calendar.month7>Août</calendar.month7>
			<calendar.month8>Septembre</calendar.month8>
			<calendar.month9>Octobre</calendar.month9>
			<calendar.month10>Novembre</calendar.month10>
			<calendar.month11>Décembre</calendar.month11>
			<calendar.close>Fermer</calendar.close>
			<format.date>dd/MM/yyyy</format.date>
			<format.datetime>dd/MM/yyyy hh:mm:ss</format.datetime>
			<format.decimal>,</format.decimal>
			<format-number.decimal-separator-sign>,</format-number.decimal-separator-sign>
			<format-number.exponent-separator-sign>.10^</format-number.exponent-separator-sign>
			<format-number.grouping-separator-sign> </format-number.grouping-separator-sign>
			<format-number.infinity>Infini</format-number.infinity>
			<format-number.minus-sign>-</format-number.minus-sign>
			<format-number.NaN>Non numérique</format-number.NaN>
			<format-number.percent-sign>%</format-number.percent-sign>
			<format-number.per-mille-sign>‰</format-number.per-mille-sign>
			<status>Traitement en cours</status>
		</properties>
		<extensions/> <!-- HTML elements to be added just after xsltforms.js and xsltforms.css loading -->
	</xsl:template>
</xsl:stylesheet>