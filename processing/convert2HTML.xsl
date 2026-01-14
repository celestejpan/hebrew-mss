<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:bod="http://www.bodleian.ox.ac.uk/bdlss" xpath-default-namespace="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei html xs bod" version="2.0">

    <!-- Import standard templates shared by all TEI catalogues. The relative path here will
         only work once the consolidated-tei-schema repository has been downloaded by the 
         index-all-qa.sh or index-all-prd.sh script (which avoids the script hanging if network is slow) -->
    <xsl:import href="lib/msdesc2html.xsl"/>

    <!-- Only set this variable if you want full URLs hardcoded into the HTML
         on the web site (previewManuscript.xsl overrides this to do so when previewing.) -->
    <xsl:variable name="website-url" as="xs:string" select="''"/>

    <!-- Any templates added below will override the templates in the shared
         imported stylesheet, allowing customization of manuscript display for each catalogue. -->

    <xsl:template name="Header">
        <p class="list-works">List of works:</p>
        <div class="list-container">
            <xsl:apply-templates select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msItem[title]" mode="fraglist"/>
            <xsl:if test="count(/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msItem[title]) eq 0">
                <div>
                    <xsl:text>No works have been identified in this manuscript.</xsl:text>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="msItem" mode="fraglist">
        <div class="title">
            <xsl:variable name="titletext" select="normalize-space(string-join(title[1]//text()[not(ancestor::foreign)], ' '))"/>
            <xsl:choose>
                <xsl:when test="$titletext">
                    <a href="{ concat('#', @xml:id) }" title="{ $titletext }">
                        <xsl:value-of select="bod:shortenToNearestWord($titletext, 48)"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <br/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
        <div class="frag">
            <xsl:choose>
                <xsl:when test="ancestor::msPart or .//locus">
                    <xsl:if test="ancestor::msPart and (ancestor::msPart//msItem[title])[1]/@xml:id = @xml:id">
                        <a href="{ concat('#', ancestor::msPart[1]/@xml:id) }">
                            <xsl:text>Part </xsl:text>
                            <xsl:value-of select="ancestor::msPart[1]/@n"/>
                        </a>
                        <xsl:if test=".//locus">
                            <br/>
                        </xsl:if>
                    </xsl:if>
                    <xsl:choose>
                        <xsl:when test=".//locus">
                            <xsl:apply-templates select="(.//locus)[1]" mode="fraglist"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <br/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <br/>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>

    <xsl:template match="locus" mode="fraglist">
        <xsl:choose>
            <xsl:when test="exists(.//text())">
                <xsl:value-of select="normalize-space(string-join(.//text(), ' '))"/>
            </xsl:when>
            <xsl:when test="@from and @to">
                <xsl:text>fols. </xsl:text>
                <xsl:value-of select="@from"/>
                <xsl:text>–</xsl:text>
                <xsl:value-of select="@to"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>



    <xsl:template name="AdditionalContent">
        <xsl:if test="starts-with(/TEI/@xml:id, 'volume_')">
            <!-- Currently only Genizah has images -->
            <div class="additional_content">
                <xsl:if test="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/additional/adminInfo/tei:recordHist/tei:source/tei:ref/@facs">
                    <h3>Catalogue Images</h3>
                    <ul style="list-style-type:none;">
                        <xsl:for-each select="tokenize(normalize-space(string-join(/TEI/teiHeader/fileDesc/sourceDesc/msDesc/additional/adminInfo/tei:recordHist/tei:source/tei:ref/@facs, ' ')), ' ')">
                            <li>
                                <a href="{ concat('/images/catalogue/', .) }">
                                    <xsl:value-of select="substring-before(substring-after(., '_'), '.jpg')"/>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
                <xsl:if test="/TEI/facsimile/graphic">
                    <h3>Fragment Images</h3>
                    <p style="float:right;">
                        <xsl:for-each select="/TEI/facsimile/graphic/@url">
                            <xsl:variable name="jpgfilename" select="replace(., '\.tiff*$', '.jpg')"/>
                            <xsl:variable name="fullsizefile" select="concat('/fragments/full/', $jpgfilename)"/>
                            <xsl:variable name="thumbfile" select="concat('/fragments/thumbs/', $jpgfilename)"/>
                            <xsl:variable name="folio" select="tokenize(substring-before($jpgfilename, '.jpg'), '_')[last()]"/>
                            <a href="{ $fullsizefile }" title="{ $folio }" style="display: inline-block; float:right;">
                                <img src="{ $thumbfile }" alt="Thumbnail of { $folio }" height="80"/>
                            </a>
                        </xsl:for-each>
                    </p>
                </xsl:if>
            </div>
        </xsl:if>
    </xsl:template>


    <xsl:template match="msItem/title">
        <xsl:if test="exists(.//text())">
            <div class="tei-title">
                <span class="tei-label">
                    <xsl:copy-of select="bod:standardText('Title: ')"/>
                </span>
                <span class="italic">
                    <xsl:copy-of select="bod:rtl(.)"/>
                    <xsl:apply-templates/>
                </span>
            </div>
        </xsl:if>
    </xsl:template>

    <!-- Override function of bod:direction - Rails now strips style attributes.  TODO move to lib/msdesc2html.xsl -->
    <xsl:function name="bod:rtl" as="attribute()?">
        <xsl:param name="elem" as="element()?"/>
        <!-- This funtion returns a HTML style attribute if the TEI element has a @xml:lang 
             specifying the script, as per BCP 47, is right-to-left (eg. "ar-Arab" or "per-Arab-x-lc"),
             or if over half the characters within match a known right-to-left script, unless it contains
             a foreign TEI element, indicating the contents are split between multiple scripts -->
        <xsl:variable name="langcode" as="xs:string?" select="$elem/@xml:lang"/>
        <xsl:variable name="stringval" as="xs:string" select="normalize-space($elem/string())"/>
        <xsl:if test="not($elem//foreign or matches($langcode, '[^\-]+\-Latn', 'i')) and (
            matches($langcode, '[^\-]+\-(Adlm|Arab|Aran|Armi|Avst|Cprt|Egyd|Egyh|Hatr|Hebr|Hung|Inds|Khar|Lydi|Mand|Mani|Mend|Merc|Mero|Narb|Nbat|Nkoo|Orkh|Palm|Phli|Phlp|Phlv|Phnx|Prti|Rohg|Samr|Sarb|Sogd|Sogo|Syrc|Syre|Syrj|Syrn|Thaa|Wole)', 'i') 
            or string-length(replace($stringval, '[&#x600;-&#x6FF;&#xFE70;-&#xFEFF;&#x10b00;-&#x10b3f;&#x0591;-&#x05f4;&#x0700;-&#x074f;&#x860;-&#x86f;]', '')) lt string-length($stringval) div 2
            )">
            <!-- NOTE: The match against the language code above uses a list of codes for right-to-left 
                 scripts taken from: https://en.wikipedia.org/wiki/ISO_15924#List_of_codes -->
            <!-- NOTE: If all the ranges for Arabic symbols then this would make anything with a number 
                 display as right-to-left. The above should be sufficient to cover most cases. -->
            <!-- TODO: Add more unicode ranges for non-Middle-Eastern R-T-L scripts? -->
            <xsl:attribute name="class">italic foreign</xsl:attribute>
        </xsl:if>
    </xsl:function>



</xsl:stylesheet>
