<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step type="dedicon:dtbook-to-pef" version="1.0"
                xmlns:dedicon="http://www.dedicon.nl"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:px="http://www.daisy.org/ns/pipeline/xproc"
                xmlns:dtb="http://www.daisy.org/z3986/2005/dtbook/"
                exclude-inline-prefixes="#all"
                name="main">

    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
        <h1 px:role="name">DTBook to PEF (Dedicon)</h1>
        <p px:role="desc">Transforms a DTBook (DAISY 3 XML) document into a PEF.</p>
    </p:documentation>
    
    <p:input port="source" primary="true" px:name="source" px:media-type="application/x-dtbook+xml"/>
    
    <p:option name="pef-output-dir"/>
    <p:option name="brf-output-dir"/>
    <p:option name="preview-output-dir"/>
    <p:option name="temp-dir"/>
    <p:option name="stylesheet" select="'http://www.dedicon.nl/pipeline/modules/braille/default.scss'"/>
    <p:option name="ascii-table"/>
    <p:option name="include-preview" select="'false'"/>
    <p:option name="include-brf" select="'true'"/>
    <p:option name="add-boilerplate" px:type="boolean" select="'true'">
        <p:documentation xmlns="http://www.w3.org/1999/xhtml">
            <h2 px:role="name">Add boilerplate text</h2>
            <p px:role="desc">When enabled, and when the input has a `docauthor` element, will insert boilerplate text such as a title page.</p>
        </p:documentation>
    </p:option>
    <p:option name="page-width" select="'33'"/>
    <p:option name="page-height" select="'28'"/>
    <p:option name="left-margin"/>
    <p:option name="duplex" select="'true'"/>
    <p:option name="hyphenation" select="'from-meta'">
        <p:pipeinfo>
            <px:data-type>
                <choice>
                    <documentation xmlns="http://relaxng.org/ns/compatibility/annotations/1.0">
                        <value>Yes</value>
                        <value>No</value>
                        <value>Use value from metadata field</value>
                    </documentation>
                    <value>true</value>
                    <value>false</value>
                    <value>from-meta</value>
                </choice>
            </px:data-type>
        </p:pipeinfo>
    </p:option>
    <p:option name="line-spacing" select="'single'"/>
    <p:option name="tab-width"/>
    <p:option name="capital-letters" select="'true'"/>
    <p:option name="accented-letters" select="'true'"/>
    <p:option name="include-captions" select="'true'"/>
    <p:option name="include-images" select="'true'"/>
    <p:option name="include-image-groups" select="'true'"/>
    <p:option name="include-line-groups" select="'true'"/>
    <p:option name="include-production-notes" select="'true'"/>
    <p:option name="show-braille-page-numbers" select="'true'"/>
    <p:option name="show-print-page-numbers" select="'true'"/> <!-- TODO: use XPath -->
    <p:option name="force-braille-page-break" select="'false'"/>
    <p:option name="toc-depth" select="'2'"/>
    <p:option name="ignore-document-title"/>
    <p:option name="include-symbols-list"/>
    <p:option name="number-of-pages"/>
    <p:option name="maximum-number-of-pages"/>
    <p:option name="minimum-number-of-pages"/>
    
    <p:import href="http://www.daisy.org/pipeline/modules/common-utils/library.xpl"/>
    <p:import href="http://www.daisy.org/pipeline/modules/braille/dtbook-to-pef/dtbook-to-pef.xpl"/>
    <p:import href="http://www.dedicon.nl/pipeline/modules/braille/library.xpl"/>
    
    <p:choose>
        <p:when test="$add-boilerplate='true'">
            <p:in-scope-names name="parameters"/>
            <dedicon:pre-processing>
                <p:input port="parameters">
                    <p:pipe port="result" step="parameters"/>
                </p:input>
                <p:input port="source">
                    <p:pipe port="source" step="main"/>
                </p:input>
            </dedicon:pre-processing>
        </p:when>
        <p:otherwise>
            <px:message message="Skipping Dedicon-specific pre-processing steps"/>
        </p:otherwise>
    </p:choose>

    <px:dtbook-to-pef>
        <p:with-option name="pef-output-dir" select="$pef-output-dir"/>
        <p:with-option name="brf-output-dir" select="$brf-output-dir"/>
        <p:with-option name="preview-output-dir" select="$preview-output-dir"/>
        <p:with-option name="temp-dir" select="$temp-dir"/>
        <p:with-option name="stylesheet" select="$stylesheet"/>
        <p:with-option name="transform" select="'(formatter:dotify)(translator:dedicon)'"/>
        <p:with-option name="ascii-table" select="$ascii-table"/>
        <p:with-option name="include-preview" select="$include-preview"/>
        <p:with-option name="include-brf" select="$include-brf"/>
        <p:with-option name="page-width" select="$page-width"/>
        <p:with-option name="page-height" select="$page-height"/>
        <p:with-option name="left-margin" select="$left-margin"/>
        <p:with-option name="duplex" select="$duplex"/>
        <p:with-option name="hyphenation" select="$hyphenation"/>
        <p:with-option name="line-spacing" select="$line-spacing"/>
        <p:with-option name="tab-width" select="$tab-width"/>
        <p:with-option name="capital-letters" select="$capital-letters"/>
        <p:with-option name="accented-letters" select="$accented-letters"/>
        <p:with-option name="include-captions" select="$include-captions"/>
        <p:with-option name="include-images" select="$include-images"/>
        <p:with-option name="include-image-groups" select="$include-image-groups"/>
        <p:with-option name="include-line-groups" select="$include-line-groups"/>
        <p:with-option name="include-production-notes" select="$include-production-notes"/>
        <p:with-option name="show-braille-page-numbers" select="$show-braille-page-numbers"/>
        <p:with-option name="show-print-page-numbers"
                       select="if ($show-print-page-numbers='from-meta')
                               then (//dtb:meta[@name='prod:docHyphenate']/@content,'Y')[1]='Y'
                               else $show-print-page-numbers='true'"/>
        <p:with-option name="force-braille-page-break" select="$force-braille-page-break"/>
        <p:with-option name="toc-depth" select="$toc-depth"/>
        <p:with-option name="ignore-document-title" select="$ignore-document-title"/>
        <p:with-option name="include-symbols-list" select="$include-symbols-list"/>
        <p:with-option name="number-of-pages" select="$number-of-pages"/>
        <p:with-option name="maximum-number-of-pages" select="$maximum-number-of-pages"/>
        <p:with-option name="minimum-number-of-pages" select="$minimum-number-of-pages"/>
    </px:dtbook-to-pef>    
</p:declare-step>
