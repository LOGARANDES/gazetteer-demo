<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:template name="config">
		<options>
		</options>
		<properties> <!--  accessible at run time -->
			<html>4</html>
			<language>es</language>
			<calendar.label>...</calendar.label>
			<calendar.day0>Lun</calendar.day0>
			<calendar.day1>Mar</calendar.day1>
			<calendar.day2>Mie</calendar.day2>
			<calendar.day3>Jue</calendar.day3>
			<calendar.day4>Vie</calendar.day4>
			<calendar.day5>Sab</calendar.day5>
			<calendar.day6>Dom</calendar.day6>
			<calendar.initDay>0</calendar.initDay>
			<calendar.month0>Enero</calendar.month0>
			<calendar.month1>Febrero</calendar.month1>
			<calendar.month2>Marzo</calendar.month2>
			<calendar.month3>Abril</calendar.month3>
			<calendar.month4>Mayo</calendar.month4>
			<calendar.month5>Junio</calendar.month5>
			<calendar.month6>Julio</calendar.month6>
			<calendar.month7>Agosto</calendar.month7>
			<calendar.month8>Septiembre</calendar.month8>
			<calendar.month9>Octubre</calendar.month9>
			<calendar.month10>Noviembre</calendar.month10>
			<calendar.month11>Diciembre</calendar.month11>
			<calendar.close>Cerrar</calendar.close>
			<format.date>dd/MM/yyyy</format.date>
			<format.datetime>dd/MM/yyyy hh:mm:ss</format.datetime>
			<format.decimal>,</format.decimal>
			<status>... Cargando ...</status>
		</properties>
		<extensions/> <!-- HTML elements to be added just after xsltforms.js and xsltforms.css loading -->
	</xsl:template>
</xsl:stylesheet>