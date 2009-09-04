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

if (isset($_REQUEST['cc1']) )
  {
    $cc_1= $_REQUEST['cc1'];
  }
else
  {
    $cc_1='CN';
  }

if (isset($_REQUEST['cc2']) )
  {
    $cc_2= $_REQUEST['cc2'];
  }
else
  {
    $cc_2='RU';
  }

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
<form id="selection_countries" action="<? echo $_SERVER['PHP_SELF'] ?>"  method="get">
<tr>

<td><? create_asn_country_drop_down("cc1"); ?></td>
<td> <? create_asn_country_drop_down("cc2"); ?></td>
</tr>
<tr>
<td>
 <input type="submit" value="submit"/> 
 <a href="geo_map_home.php?cc=<?  print $cc_2  ?>"><input type="button" value="Show World Map"></a>
</td>
</tr>
</form>

</table>


<?
include "footer.php";
?>
