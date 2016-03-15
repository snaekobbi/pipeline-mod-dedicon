<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns="http://www.daisy.org/z3986/2005/dtbook/">

  <xsl:output indent="yes"/>
    
  <xsl:template match="frontmatter/docauthor">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:call-template name="generate-title-page"/>                
  </xsl:template>

  <xsl:template match="rearmatter/*[last()]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:call-template name="generate-colophon-page"/>                
  </xsl:template>

  <xsl:template match="rearmatter[not(node())]">
    <rearmatter>
      <xsl:call-template name="generate-colophon-page"/>                
    </rearmatter>
  </xsl:template>

  <xsl:template match="node()">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="generate-title-page">
    <level1 id="generated-title-page" class="other">
      <p id="generated-identifier"><xsl:value-of select="//meta[@name eq 'dc:Identifier']/@content"/></p>
      <p id="generated-doctitle"><xsl:value-of select="//doctitle"/></p>
      <p id="generated-docauthor"><xsl:value-of select="//docauthor"/></p>
      <p id="generated-isbn">ISBN: <xsl:value-of select="//meta[@name eq 'dc:Source']/@content"/></p>
      <p id="generated-production-date">
        <!-- FIXME: should be Dutch (nl-NL) month names -->
        <xsl:value-of select="//meta[@name eq 'dc:Publisher']/@content"/>,
        <xsl:value-of select="format-date(current-date(), '[MNn] [Y]')"/>
      </p>
      <p id="generated-volume-count">
        Band <span class="placeholder-current-volume"/> (totaal <span class="placeholder-total-volumes"/>)
      </p>
    </level1>
  </xsl:template>

  <xsl:template name="generate-colophon-page">
    <level1 id="generated-colophon-page" class="other">
      <p>The colophon goes here.</p>
    </level1>
  </xsl:template>

</xsl:stylesheet>
