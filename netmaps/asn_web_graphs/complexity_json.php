<?
/**
 * complexity_json.php
 *
 * @package default
 */


include 'xml_utils.php';

include 'country_summary_table.php';



$countries_xml = get_sorted_country_list("cmp_country_complexity", "complex", "complexity");


$result_array = array();

$i = 0;
foreach ($countries_xml as $country_xml) {
    $country_code =  (string)$country_xml['country_code'];
    $complexity   =  get_complexity($country_xml);
    $country_name  = (string) $country_xml['country_name'];

    $result_array[$i] = array(
        'country_code' => $country_code,
        'country_name' => $country_name,
        'complexity'         =>  $complexity);
    $i++;
}

print json_encode($result_array);
