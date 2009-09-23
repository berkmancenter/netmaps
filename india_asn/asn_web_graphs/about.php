<?
/**
 * raw_data.php
 *
 * @package default
 */


global $alternate_css;
$alternate_css='geo_map.css';
global $nav_index;
$show_nav_index=0;
include "./header.php";

?>
<table class="info_box">
<tr>
<td>
<div class="vis_head">
<span class="vis_heading">ABOUT PROJECT</span>
</div>
</td>
</tr>
<tr>
<td>
<? include "about_text.php"; ?>
</td>
</tr>
</table>

<?
include "footer_new.php";
?>

