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
<span class="vis_heading">RAW DATA</span>
</div>
</td>
</tr>
<tr>
<td>

<h1>Data Files</h1>

<p>
The following xml file contains all of the data presented in these web pages, including
</p>
<ul>
<li>the basic data for each country and ASN (name, number of IPs, etc)</li>
<li>the generated Complexity, Points of Control, and IPs per Point of Control data</li>
<li>the network relationships for each ASN within each country.</li>
</ul>

<p> <a href="results/results.xml">Our results in XML format.</a></p>
<p> <a href="./data_csv.php">Our results in CSV format.</a></p>

<p>For more information about the methodology used to generate this data, see the <a href="methods.php">Methods</a> page.<p>

</td>
</tr>
</table>

<?
include "footer_new.php";
?>

