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
include "./geo_map_scripts.php";
include "./gen_visualizations.php";

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
  <? embed_flash_object('CN'); ?>
</div>
</div>
</td>
</tr>
</table>
</div>
<?
include "footer.php";
?>
