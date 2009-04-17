<?
function get_xml_file() 
{
  $xml_file_location = 'results/results.xml';


  $xml = new SimpleXMLElement(file_get_contents($xml_file_location));
  return $xml;
}
?>

<?

function get_points_of_control($country_xml)
{
  return (string)$country_xml->summary->ninty_percent_asns["count"];
}

function get_complexity($country_xml)
{ 
  $complexity = $country_xml->summary->complexity;

  return (integer) $complexity;  
}

function get_ip_address_count($country_xml)
{
  return (string)$country_xml->summary->total_ips;
}

function country_ip_address_count_gt_noise_threshold($country_xml)
{
  $ip_address_noise_threshold = 25000;

  $ip_address_count = get_ip_address_count($country_xml);
  if ( $ip_address_count >   $ip_address_noise_threshold)
  {
     return true;
  }
  else
  { 
      return false;
  }
}

function cmp_country_complexity(SimpleXMLElement $a, SimpleXMLElement $b)
{
  $complexity_a = get_complexity($a);
  $complexity_b = get_complexity($b);

  if ( $complexity_a  ==  $complexity_b)
    {
      return 0;
    }

  return ($complexity_a < $complexity_b) ? -1: 1;
}

function get_country_name_x(SimpleXMLElement $county)
{
  #print ("START get_country_name\n");
  #print("Country Object '$country_x'\n");
  #print_r($country_x['country_name']);
  
  $ret = (string)$country['country_name'];

  #print "END get_country_name return = '$ret'\n";
  return $ret;
}

function get_ips_per_points_of_control(SimpleXMLElement $country)
{
  $total_ips =  get_ip_address_count($country);
  $points_of_control         =  get_points_of_control($country);  
  return $total_ips/$points_of_control;
}

function cmp_ips_per_points_of_control(SimpleXMLElement $a, SimpleXMLElement $b)
{
  $ips_per_points_of_control_a = get_ips_per_points_of_control($a);
  $ips_per_points_of_control_b = get_ips_per_points_of_control($b);

  if ( $ips_per_points_of_control_a  ==  $ips_per_points_of_control_b)
    {
      return 0;
    }

  return ($ips_per_points_of_control_a < $ips_per_points_of_control_b) ? -1: 1;
}

function country_xml_table_row(SimpleXMLElement $country)
{
  #print ("START country_xml_table_row '$country'\n");
  #if (!defined($country) ) die ("XX") ;
  $country_name =  $country['country_name']; 
  #$country_name = get_country_name_x($country);
  $country_code =  (string)$country['country_code'];
  $xquery_string = "//country[@country_code='". $country_code . "']/summary/ninty_percent_asns";
  $total_ips =  get_ip_address_count($country);
  $total_asns = $country->summary->total_asns;
  $points_of_control         =  get_points_of_control($country);
  $complexity =  get_complexity($country);
  $ips_per_points_of_control  = get_ips_per_points_of_control($country);
 # print_r( $country_code);
 # print_r($country);
?>
  <tr>
    
     <td> <a href=<? echo "\"country_detail.php/?cc=". urlencode($country_code). "\"" ?> > <? echo "$country_name"; ?>
</a></td>
    <td><? echo "{$country['country_code']}"; ?></td>
    <td><? echo $total_ips; ?></td>
    <td><? echo $total_asns; ?></td>
<?
   #print_r( $country_code); print_r(' ');
  
 #  print_r( $xquery_string);
 ?>
    <td><? echo $points_of_control ?></td>
    <td><? echo $ips_per_points_of_control ?></td>
    <td><? echo $complexity ?></td>
  </tr>
<?  
}
?>


<?
function country_xml_list_summary_table($countries_xml)
{
?>
<table>
<tr>
<td>Country</td>
<td>Code</td>
<td>Total IPs</td>
<td>Total ANs</td>
<td>Points of Control</td>
<td>IPs Per Point of Control</td>
<td>Complexity</td>
</tr>
<?
foreach ($countries_xml as $country) 
{
  country_xml_table_row($country);
}
?>
</table>
<?
}
?>
