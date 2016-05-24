<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pf="http://www.daisy.org/ns/pipeline/functions"
                xmlns:css="http://www.daisy.org/ns/pipeline/braille-css"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-result-prefixes="#all">
	
	<xsl:import href="http://www.daisy.org/pipeline/modules/braille/css-utils/transform/block-translator-template.xsl"/>
	
	<xsl:param name="text-transform" required="yes"/>
	
	<xsl:template match="css:block" mode="#default before after">
		<xsl:variable name="text" as="text()*" select="//text()"/>
		<xsl:variable name="style" as="xs:string*">
			<xsl:apply-templates mode="style"/>
		</xsl:variable>
		<xsl:apply-templates select="node()[1]" mode="treewalk">
			<xsl:with-param name="new-text-nodes" select="pf:text-transform($text-transform, $text, $style)"/>
		</xsl:apply-templates>
		<xsl:for-each select="distinct-values(//dtb:noteref/@idref)">
			<xsl:variable name="idref" select="."/>
			<xsl:sequence select="collection()[1]//dtb:note[@id=replace($idref, '^#', '')]"/>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template mode="style" match="*" as="xs:string*">
		<xsl:param name="source-style" as="element()*" tunnel="yes"/>
		<xsl:variable name="source-style" as="element()*">
			<xsl:call-template name="css:computed-properties">
				<xsl:with-param name="properties" select="$inline-properties"/>
				<xsl:with-param name="context" select="$dummy-element"/>
				<xsl:with-param name="cascaded-properties" tunnel="yes"
				                select="css:deep-parse-stylesheet(@style)[not(@selector)]/css:property"/>
				<xsl:with-param name="parent-properties" tunnel="yes" select="$source-style"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:apply-templates mode="#current">
			<xsl:with-param name="source-style" tunnel="yes" select="$source-style"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template mode="style" match="text()" as="xs:string">
		<xsl:param name="source-style" as="element()*" tunnel="yes"/>
		<xsl:sequence select="css:serialize-declaration-list($source-style[not(@value=css:initial-value(@name))])"/>
	</xsl:template>
	
	<xsl:template mode="translate-style"
	              match="css:property[@name=('font-style',
	                                         'font-weight',
	                                         'text-decoration',
	                                         'color')]"/>
	
	<xsl:template mode="translate-style" match="css:property[@name='hyphens' and @value='auto']">
		<xsl:param name="result-style" as="element()*" tunnel="yes"/>
		<xsl:if test="$result-style[@name='hyphens' and not(@value='manual')]">
			<css:property name="hyphens" value="manual"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="//dtb:note" mode="identify-blocks"/>
	
	<!--
	    FIXME: because of bug in block-translator-template.xsl (fixed in next version)
	-->
	<xsl:template mode="translate-style" match="css:string[@value]|css:attr" as="element()?">
		<xsl:param name="context" as="element()" tunnel="yes"/>
		<xsl:param name="source-style" as="element()*" tunnel="yes"/> <!-- css:property* -->
		<xsl:param name="result-style" as="element()*" tunnel="yes"/> <!-- css:property* -->
		<xsl:param name="mode" as="xs:string" tunnel="yes"/> <!-- before|after -->
		<xsl:choose>
			<xsl:when test="$mode=('before','after')">
				<xsl:next-match/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="evaluated-string" as="xs:string">
					<xsl:apply-templates mode="css:eval" select=".">
						<xsl:with-param name="context" select="$context"/>
					</xsl:apply-templates>
				</xsl:variable>
				<css:string value="{$evaluated-string}"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!--
	    FIXME: because of bug in block-translator-template.xsl (fixed in next version)
	-->
	<xsl:template match="css:string[@name][not(@target)]" mode="css:serialize" as="xs:string">
		<xsl:sequence select="concat('string(',@name,if (@scope) then concat(', ', @scope) else '',')')"/>
	</xsl:template>
	
</xsl:stylesheet>
