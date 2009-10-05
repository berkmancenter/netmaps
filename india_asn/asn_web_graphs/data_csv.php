<?
/**
 * raw_data.php
 *
 * @package default
 */
header("Content-type: application/octet-stream");
header("Content-Disposition: attachment; filename=\"internet_mapping_data.csv\"");

include "./xml_utils.php";

$countries_xml = get_all_countries();

csv_dump($countries_xml);

?>
