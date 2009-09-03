<?
/**
 * geo_map_home.php
 *
 * @package default
 */


global $alternate_css;
$alternate_css='geo_map.css';
include "./header.php";
include "./get_url_routines.php";
?>

<?


/**
 *
 *
 * @return unknown
 */
function get_json_complexity_url() {
    $host = $_SERVER["HTTP_HOST"];
    $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
    $json_complexity_url = "http://$host$path//complexity_json.php";

    return $json_complexity_url;
}


include "./geo_map_scripts.php";


/**
 *
 *
 * @param unknown $country_code
 */
function embed_flash_object_bak($country_code) {
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


/**
 *
 */
function create_asn_country_drop_down() {
?>
<select id="country_drop_down" onChange="update_select_country()" name="asn_diagram_shortcut">
<?
    $country_code_to_name_map = get_country_code_to_name_map();
?>

  <option value="Select a Country">Select a Country</option>
<?
    foreach ($country_code_to_name_map as $country_code => $country_name) {
?>
  <option value="<? echo $country_code ?>"><? echo $country_name ?></option>
<? } ?>
 </select>
<?
}


?>


<?
geo_map_scripts('map_canvas');
?>
<div class="geomaptable">
<table valign="top">
<tr valign="top">
  <td style="height: 100%" >
<table style="height: 100%">
<tr valign="top">
<td>
<div id="foo"><div class="vis_head">
<span class="vis_heading">WORLD COMPLEXITY MAP</span> <span class="vis_sub_heading">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; select a country to see ASN diagram</span>
</div>
<div id='map_canvas'></div>
</div>
</td>
</tr>
<tr valign="bottom">
<td>
<div id="foo">
<table valign="top"  width='100%' border='1'>
<tr>
<td colspan="3">
<div class="vis_head">
<span class="vis_heading">COUNTRY VIEW LIST</span> <span class="vis_sub_heading">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; select a country to see ASN diagram</span>
</div>
</td>
</tr>
<tr valign="top" style="background: white; color: #aeaeae;">
<td style="border-right: 1px solid #a0a0a0;">
ASN DIAGRAM SHORTCUT
<br/>
<?
create_asn_country_drop_down();
?>
</td>
<td style="padding-left: 10px;">
COUNTRY HIGHLIGHTS
<br/>
China compared to Russia<br/>
Nigeria compared to China<br/>
Country compared to Country<br/>
</td>
</tr>
</table>
</div>
</td>
</tr>
</table>
</td>
<td>
<div id="foo">
<div id='country_flash_object'>
  <? embed_flash_object_bak('CN'); ?>
</div>
</div>
</td>
</tr>
</table>
</div>
<?
include "footer.php";
?>
