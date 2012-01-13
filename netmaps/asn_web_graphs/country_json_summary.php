<?
/**
 * country_json_summary.php
 *
 * @package default
 */

include 'xml_utils.php';

$country_code = $_REQUEST['cc'];
validate_country_code($country_code);
$xml_file_location = 'results/results.xml';

$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
$xquery_string = "//country[@country_code='$country_code']";
$xq_array = $xml->xpath($xquery_string);
$country_xml = $xq_array[0];


$asn_list_array = array();

$i = 0;
foreach ($country_xml->summary->as as $as) {
    $percent_monitorable_str = $as->percent_monitorable . '';
    $total_monitorable_str   = $as->effective_monitorable_ips . '';

    $percent_direct_str = $as->percent_direct_ips . '';
    $total_direct_ips   = $as->direct_ips . '';
    $is_point_of_control = $as["point_of_control" ]==1;

    $organization_name =  $as->organization_name . '';

    $customers  = $as->customers . '';

    $customers = split(',', $customers);

    $asn = $as->asn . '';

    $asn_list_array[$i] = array(
        'asn' => $asn,
        'organization_name' => $organization_name,
        'percent_monitorable' => $percent_monitorable_str,
        'direct_ips' => $total_direct_ips,
        'total_monitorable'   => $total_monitorable_str,
        'is_point_of_control' => $is_point_of_control,
        'customers'         =>  $customers);
    $i++;
}

$country_info = get_country_info_hash($country_xml);

$ret_array = array(
                   'asns' => $asn_list_array,
                   'country_level_info' => $country_info,
                   );

print json_encode($ret_array);


/**
 *
 *
 * @param unknown $country_code
 */
function validate_country_code($country_code) {
    if (strlen($country_code) != 2) {
        die ("illegal country code");
    }

    if (preg_match("/[^A-Z]/", $country_code)) {
        die ("illegal country code");
    }
}
