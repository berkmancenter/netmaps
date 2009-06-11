<?
$country_code = $_REQUEST['cc'];
validate_country_code($country_code);
$xml_file_location = 'results/results.xml';

$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
$xquery_string = "//country[@country_code='$country_code']";
$result_array = $xml->xpath($xquery_string);
$country_xml = $result_array[0];


$i = 0;
foreach ($country_xml->summary->as as $as)
{
  $percent_monitorable_str = number_format($as->percent_monitorable, 1);
  $total_monitorable_str   = number_format($as->effective_monitorable_ips);

  $percent_direct_str = number_format($as->percent_direct_ips, 1);
  $total_direct_str   = number_format($as->direct_ips);
  $is_point_of_control = $as["point_of_control" ]==1;

  $organization_name =  $as->organization_name . '';

  $customers  = $as->customers . '';

  $customers = split (',', $customers);

  $asn = $as->asn . '';

  $result_array[$i] = Array(
                          'asn' => $asn,
                          'organization_name' => $organization_name,
                          'percent_monitoral' => $percent_monitorable_str,
                          'total_monitoral'   => $total_monitorable_str,
                          'is_point_of_control' => $is_point_of_control,
                          'customers'         =>  $customers);
  $i++;
}

print json_encode($result_array);

function validate_country_code($country_code)
{
  if (strlen($country_code) != 2)
    {
      die ("illegal country code");
    }  

  if (preg_match("/[^A-Z]/", $country_code))
    {
      die ("illegal country code");
    }
}
