<?xml version="1.0" encoding="UTF-8"?>
<p:pipeline type="pxi:block-translate" version="1.0"
            xmlns:p="http://www.w3.org/ns/xproc"
            xmlns:pxi="http://www.daisy.org/ns/pipeline/xproc/internal"
            exclude-inline-prefixes="#all">
	
	<p:option name="query" required="true"/>
	
	<p:xslt>
		<p:input port="stylesheet">
			<p:document href="block-translate.xsl"/>
		</p:input>
		<p:with-param name="query" select="$query"/>
	</p:xslt>
	
</p:pipeline>
