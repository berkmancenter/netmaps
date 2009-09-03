<?


/**
 *
 *
 * @param unknown $country_code
 */
function embed_flash_object($country_code) {
    $xml_file_location = 'results/results.xml';

    $xml = new SimpleXMLElement(file_get_contents($xml_file_location));
    $xquery_string = "//country[@country_code='$country_code']";
    $result_array = $xml->xpath($xquery_string);
    $country_xml = $result_array[0];
    $country_name =  $country_xml['country_name'];
?>

       <div id="asn_diagram_wrapper">
       <div class="vis_head">
          <span id='country_flash_map_header' class="vis_heading">AUTNOMOUS SYSTEM DIAGRAM - <? echo $country_name ?></span> <span class="vis_sub_heading">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; mouse over and click on nodes</span></div>

       <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
			id="demos" width="650" height="525"
			codebase="http://fpdownload.macromedia.com/get/flashplayer/current/swflash.cab">
			<param name="movie" value="asn_visualization.swf" />
			<param name="quality" value="high" />
			<param name="bgcolor" value="#ffffff" />
			<param name="allowScriptAccess" value="sameDomain" />
                        <param id='json_url_parm' name="FlashVars" value="json_url=<? echo get_json_summary_url($country_xml) ?>" />
			<embed name='flash_embed_tag_id' src="<? echo get_flash_url() ?>" bgcolor="#ffffff"
				width="650" height="525" name="demos" align="middle"
				play="true"
				loop="false"
				quality="high"
				allowScriptAccess="sameDomain"
				type="application/x-shockwave-flash"
                                FlashVars="json_url=<? echo get_json_summary_url($country_xml) ?>"
				pluginspage="http://www.adobe.com/go/getflashplayer">
			</embed>
	</object>
       </div>
<?
}

