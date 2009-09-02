<?
$show_ad_planner_results = 1;

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

  return (double) $complexity;  
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

function get_country_name_x(SimpleXMLElement $country)
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
  return (integer) ($total_ips/$points_of_control);
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

function get_country_top_sites(SimpleXMLElement $country_xml)
{
  $ret = (String) $country_xml->ad_words_summary->top_site_count;

  if (!$ret)
    {
      $ret = 'N/A';
    }

  return $ret ;
}

function get_top_sites_in_country(SimpleXMLElement $country_xml)
{
  $ret = (String) $country_xml->ad_words_summary->top_sites_in_country;

  if (!$ret)
    {
      $ret = 'N/A';
    }

  return $ret ;
}

function get_top_sites_country_percent(SimpleXMLElement $country_xml)
{

  $top_site_count = get_country_top_sites($country_xml);
  $top_sites_in_country = get_top_sites_in_country($country_xml);

  if ($top_site_count == 'N/A')
    {
      return 'N/A';
    }

  return $top_sites_in_country/$top_site_count*100.0;
}

function get_top_sites_PoC_percent(SimpleXMLElement $country_xml)
{
  $top_site_count = get_country_top_sites($country_xml);
  $top_sites_in_country = get_top_sites_in_PoC($country_xml);

  if ($top_site_count == 'N/A')
    {
      return 'N/A';
    }

  return $top_sites_in_country/$top_site_count*100.0;
}

function get_total_page_views(SimpleXMLElement $country_xml)
{
 $ret = (String) $country_xml->ad_words_summary->total_page_views;

  if (!$ret)
    {
      $ret = 'N/A';
    }

  return $ret ;
}

function get_page_views_in_country(SimpleXMLElement $country_xml)
{
 $ret = (String) $country_xml->ad_words_summary->page_views_in_country;

  if (!$ret)
    {
      $ret = 'N/A';
    }

  return $ret ;
}

function get_page_view_country_percent(SimpleXMLElement $country_xml)
{

  $total_page_views =  get_total_page_views($country_xml);
  $page_views_in_country = get_page_views_in_country($country_xml);

  if ($total_page_views == 'N/A')
    {
      return 'N/A';
    }

  return round(100.0*$page_views_in_country/$total_page_views, 2);
}

function get_page_view_PoC_percent(SimpleXMLElement $country_xml)
{

  $total_page_views =  get_total_page_views($country_xml);
  $page_views_in_country = get_PoC_page_views($country_xml);

  if ($total_page_views == 'N/A')
    {
      return 'N/A';
    }

  return round(100.0*$page_views_in_country/$total_page_views, 2);
}

function get_top_sites_in_PoC(SimpleXMLElement $country_xml)
{
 $ret = (String) $country_xml->ad_words_summary->top_sites_in_poc;

 $total_page_views =  get_total_page_views($country_xml);

 if ($ret == '')
    {
      $ret = 'N/A';
    }

  return $ret ;
}

function get_PoC_page_views(SimpleXMLElement $country_xml)
{
 $ret = (String) $country_xml->ad_words_summary->page_views_in_poc;

 $total_page_views =  get_total_page_views($country_xml);

 if ($ret == '')
    {
      $ret = get_top_sites_in_PoC($country_xml);
    }

  return $ret ;
}

function country_xml_table_row(SimpleXMLElement $country, $show_rank, $country_rank, $total_countries )
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
     <? if ($show_rank) { ?>
     <td><? echo "$country_rank of $total_countries" ?></td>
       <? } ?>
    
     <td> <a href="<? echo get_local_url("country_detail.php/?cc=". urlencode($country_code)) ?>" > <? echo "$country_name"; ?>
</a></td>
    <td><? echo "{$country['country_code']}"; ?></td>
    <td><? echo htmlentities(number_format( $total_ips)); ?></td>
    <td><? echo htmlentities(number_format( $total_asns)); ?></td>

                                                                 <td><? echo  htmlentities(number_format($points_of_control)) ?></td>
                                                                 <td><? echo  htmlentities(number_format($ips_per_points_of_control)) ?></td>
                                                                 <td><? echo  htmlentities(number_format($complexity,2)) ?></td>
<? 
global $show_ad_planner_results;

if ($show_ad_planner_results) { ?>
    <td> <? echo get_country_top_sites($country) ?> </td>
    <td> <? echo get_top_sites_in_country($country) ?> </td>
    <td> <? echo get_top_sites_country_percent($country) ?> </td>
    <td> <? echo get_top_sites_in_PoC($country) ?></td>
    <td> <? echo get_top_sites_PoC_percent($country) ?></td>
    <td> <? echo get_total_page_views($country) ?> </td>
    <td> <? echo get_page_views_in_country($country) ?> </td>
    <td> <? echo get_page_view_country_percent($country) ?> </td>
    <td> <? echo get_PoC_page_views($country) ?></td>
    <td> <? echo get_page_view_PoC_percent($country) ?></td>
<? } ?>


  </tr>
<?  
}

function get_country_code_to_name_map()
{
  $countries_xml = get_sorted_country_list("cmp_country_complexity", "complex", "complexity"); 

  $result_array = Array();

  $i = 0;
  foreach ($countries_xml as $country_xml)
  {
    $country_code =  (string)$country_xml['country_code'];
    $country_name  = (string) $country_xml['country_name'];
    
    $result_array[$country_code] = $country_name;
  }
  
  asort($result_array);
  return $result_array;
}

function is_country_not_region(SimpleXMLElement $country_xml)
{
  return $country_xml['country_code_is_region'] == 0;
}

function get_all_countries()
{
  $xml = get_xml_file();
  $countries_xml = $xml->xpath("//country");
  $countries_xml_tmp = array_filter($countries_xml, "is_country_not_region");
  $countries_xml = $countries_xml_tmp;
  return $countries_xml;
}

function get_sorted_country_list ($sort_function, $sort_type_adjective, $sort_type_noun) 
{
  $countries_xml = get_all_countries();
  $countries_xml_tmp = array_filter($countries_xml, "country_ip_address_count_gt_noise_threshold");
  $countries_xml = $countries_xml_tmp;
  
  usort($countries_xml, $sort_function);

  return $countries_xml;
}

function get_excluded_country_names()
{
 $countries_xml = get_all_countries();
 $countries_xml_included =  array_filter($countries_xml, "country_ip_address_count_gt_noise_threshold");

  print count( $countries_xml) . " total countries\n";
  print count( $countries_xml_included) . " included countries\n";

  $countries_xml_excluded = array();
  #array_diff doesn't work on object arrays so write our own
  foreach ($countries_xml as $country_xml)
    {
      if (!in_array($country_xml, $countries_xml_included)) {
        array_push ($countries_xml_excluded, $country_xml);
      }
    }
  #print_r($countries_xml);
  #print_r( $countries_xml_excluded );
  $countries_excluded_names = array_map("get_country_name_x", $countries_xml_excluded);

  sort ($countries_excluded_names);
  return $countries_excluded_names;

}

function top_countries_table($sort_function, $sort_type_adjective, $sort_type_noun, $list_size) 
{
  $countries_xml = get_sorted_country_list ($sort_function, $sort_type_adjective, $sort_type_noun) ;
  
  $countries_xml_high_15 = array_slice($countries_xml, -1* $list_size);
 
  print "<h1><a name='most'>most $sort_type_adjective</a></h1>";
  country_xml_list_summary_table(array_reverse($countries_xml_high_15), true);
}


function high_15_table($sort_function, $sort_type_adjective, $sort_type_noun) 
{
  top_countries_table( $sort_function, $sort_type_adjective, $sort_type_noun, 15);
}

?>

<?
function country_xml_list_summary_table($countries_xml, $show_rank)
{
?>
<table>
<tr>
    <? if ($show_rank) { ?> <td>Rank</td> <? } ?> 
<td>Country</td>
<td>Code</td>
<td>Total IPs</td>
<td>Total Autonomous Systems</td>
<td>Points of Control</td>
<td>IPs Per Point of Control</td>
<td>Complexity</td>
<? global $show_ad_planner_results;
if ($show_ad_planner_results) { ?>
<td>top sites</td>
<td>top sites in country</td>
<td>country site %</td>
<td>top sites in PoC</td>
<td>PoC sites %</td>
<td>total page views</td>
<td>country page views</td>
<td>country page view %</td>
<td>PoC page views</td>
<td>PoC page view %</td>
<? } ?>
</tr>

<?
    $total_countries = count($countries_xml);

  $current_country_num = 0;

foreach ($countries_xml as $country) 
{
  $current_country_num++;
  country_xml_table_row($country, $show_rank, $current_country_num, $total_countries);
}
?>
</table>
<?
}
?>
