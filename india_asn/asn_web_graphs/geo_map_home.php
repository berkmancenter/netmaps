<?
/**
 * geo_map_home.php
 *
 * @package default
 */


global $alternate_css;
$alternate_css='geo_map.css';
global $nav_index;
$show_nav_index=0;
include "./header.php";
include "./get_url_routines.php";
include "./geo_map_scripts.php";
include "./gen_visualizations.php";

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
create_asn_country_drop_down("asn_diagram_shortcut","country_drop_down","update_select_country()" );
?>
</td>
<td style="padding-left: 10px;">
COUNTRY HIGHLIGHTS
<br/>
<a href="http://localhost/asn_web_graphs/asn_diagram_comparison.php?cc1=CN&cc2=RU">China compared to Russia</a><br/>
<a href="http://localhost/asn_web_graphs/asn_diagram_comparison.php?cc1=NG&cc2=CN">Nigeria compared to China</a><br/>
<a href="http://localhost/asn_web_graphs/asn_diagram_comparison.php">Country compared to Country</a><br/>
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
