<?
/**
 * raw_data.php
 *
 * @package default
 */
header("Content-type: application/octet-stream");
header("Content-Disposition: attachment; filename=\"my-data.csv\"");

global $alternate_css;
$alternate_css='geo_map.css';
global $nav_index;
$show_nav_index=0;

include "./xml_utils.php";

$countries_xml = get_sorted_country_list ("cmp_ips_per_points_of_control", "IPs per point of control", "IPs per point of control", "fewest");

csv_dump($countries_xml);

?>
