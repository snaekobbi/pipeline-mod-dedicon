<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xpath-default-namespace="http://www.daisy.org/z3986/2005/dtbook/"
    xmlns="http://www.daisy.org/z3986/2005/dtbook/">

  <xsl:output indent="yes"/>
  <xsl:param name="move-print-colophon-to-last-volume" required="yes"/>

  <!-- Add rearmatter if it does not exist -->
  <xsl:template match="book[not(rearmatter)]">
    <xsl:copy>
      <xsl:apply-templates/>
      <rearmatter>
        <xsl:if test="$move-print-colophon-to-last-volume">
          <xsl:copy-of select="//level1[@class='colophon']"/>
        </xsl:if>
        <xsl:call-template name="generate-colophon-page"/> 
      </rearmatter>
    </xsl:copy>
  </xsl:template>

  <!-- Insert title page template: after docauthor -->
  <xsl:template match="frontmatter/*[self::doctitle or self::docauthor][last()]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:call-template name="generate-title-page"/>                
  </xsl:template>

  <!-- Insert cover template: at end of frontmatter -->
  <xsl:template match="frontmatter/*[last()]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
    <xsl:copy-of select="//level1[@class='flap']"/>
  </xsl:template>

  <!-- Insert print and generated colophon template: after last item in rearmatter -->
  <xsl:template match="rearmatter">
    <xsl:copy>
      <xsl:apply-templates/>
      <xsl:if test="$move-print-colophon-to-last-volume">
        <xsl:copy-of select="//level1[@class='colophon']"/>
      </xsl:if>
      <xsl:call-template name="generate-colophon-page"/> 
    </xsl:copy>
  </xsl:template>

  <!-- Identity template -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!--
    Removes the cover.
    The cover is moved into the frontmatter.
  -->
  <xsl:template match="//level1[@class='flap']"/>

  <!--
    Removes the print colophon.
    The print colophon is moved into the rearmatter.
  -->
  <xsl:template match="//level1[@class='colophon']">
    <xsl:if test="not($move-print-colophon-to-last-volume)">
      <xsl:copy>
        <xsl:apply-templates select="node()|@*"/>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <!--
    Template: generate-title-page
    Inserts the title page for both AL and SV books.
  -->
  <xsl:template name="generate-title-page">
    <xsl:variable name="isbn" select="//meta[@name eq 'dc:Source']/@content"/>
    <level1 id="generated-title-page" class="other">
      <p id="generated-identifier"><xsl:value-of select="//meta[@name eq 'dc:Identifier']/@content"/></p>
      <p id="generated-doctitle"><xsl:copy-of select="//doctitle/node()"/></p>
      <p id="generated-docauthors"><xsl:value-of select="string-join(//docauthor,', ')"/></p>
      <p id="generated-isbn">
        <xsl:if test="matches($isbn, '^[0-9-]{10,}$')">
          ISBN: <xsl:value-of select="$isbn"/>
        </xsl:if>
      </p>
      <div id="generated-title-page-footer">
        <p>Dedicon</p>
        <p id="generated-volume-count">
          Band <span class="placeholder-current-volume"/> van <span class="placeholder-total-volumes"/>
        </p>
      </div>
    </level1>
  </xsl:template>

  <!--
    Template: generate-colophon-page
    Inserts the colophon page for both AL and SV books.
  -->
  <xsl:template name="generate-colophon-page">
    <xsl:choose>
      <xsl:when test="//meta[@name eq 'prod:docType']/@content eq 'ro'">
        <!-- AL -->
        <level1 id="generated-colophon-page" class="other">
          <h1>Colofon Dedicon</h1>
          <p>Dit braille document is verzorgd door de stichting Dedicon, met inachtneming van artikel 15i van de Auteurswet. Het werk is uitsluitend bestemd voor hen die niet op de gebruikelijke manier kunnen lezen.</p>
          <p class="precedingemptyline">Alle intellectuele eigendomsrechten op dit braille document berusten bij de Koninklijke Bibliotheek. Voor opmerkingen omtrent de kwaliteit van dit boek of vragen over het gebruik ervan kan worden gebeld met Bibliotheekservice Passend Lezen, telefoon: 070 338 1500.</p>
        </level1>
      </xsl:when>
      <xsl:otherwise>
        <!-- SV -->
        <xsl:variable name="colophon" select="//meta[@name eq 'prod:colophon']/@content"/>
        <xsl:if test="$colophon eq '1'">
          <!-- Colofon 1: Educatief tekst (binnenlandse uitgevers) -->
          <level1 id="generated-colophon-page" class="other">
            <h1>Colofon Dedicon</h1>
            <p>Dit Brailleboek is uitsluitend bestemd voor eigen gebruik door mensen met een leesbeperking.</p>
            <p class="precedingemptyline">Alle intellectuele eigendomsrechten op dit Brailleboek berusten bij Dedicon. Productie en distributie vinden plaats op basis van art. 15i uit de Nederlandse Auteurswet en zijn conform de Regeling Toegankelijke Lectuur voor mensen met een leesbeperking. Kopiëren, uitlenen of doorverkopen aan anderen is niet toegestaan.</p>
          </level1>
        </xsl:if>
        <xsl:if test="$colophon eq '2'">
          <!-- Colofon 2: Educatief tekst (buitenlandse uitgever met medewerking) -->
          <level1 id="generated-colophon-page" class="other">
            <h1>Colofon Dedicon</h1>
            <p>Dit Brailleboek is uitsluitend bestemd voor eigen gebruik door mensen met een aantoonbare leesbeperking. Het is geproduceerd met medewerking van de uitgever.</p>
            <p class="precedingemptyline">Alle intellectuele eigendomsrechten op dit Brailleboek berusten bij Dedicon. Kopiëren, uitlenen of doorverkopen aan anderen is niet toegestaan.</p>
          </level1>
        </xsl:if>
        <xsl:if test="$colophon eq '3'">
          <!-- Colofon 3: Educatief tekst (buitenlandse uitgever zonder medewerking) -->
          <level1 id="generated-colophon-page" class="other">
            <h1>Colofon Dedicon</h1>
            <p>Dit Brailleboek is uitsluitend bestemd voor eigen gebruik door mensen met een aantoonbare leesbeperking.</p>
            <p class="precedingemptyline">Alle intellectuele eigendomsrechten op dit Brailleboek berusten bij Dedicon. Kopiëren, uitlenen of doorverkopen aan anderen is niet toegestaan.</p>
          </level1>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
