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

$cc_1= $_REQUEST['cc1'];
$cc_2= $_REQUEST['cc2'];
?>
<br/>
<table valign="top" style="border:0px;margin: 0px;padding:0px; ">
<tr>
  <td style="padding: 5px;">
  <? embed_flash_object($cc_1); ?>
</td>
  <td  style="padding: 5px;">
  <? embed_flash_object($cc_2); ?>
</td>
</tr>
</table>
</div>
<?
include "footer.php";
?>
