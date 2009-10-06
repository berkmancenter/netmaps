<?
/**
 * xml_utils.php
 *
 * @see complexity_json.php
 * @see header.php
 * @package default
 */


$show_ad_planner_results = 1;


function get_xml_file() {
    $xml_file_location = 'results/results.xml';


    $xml = new SimpleXMLElement(file_get_contents($xml_file_location));
    return $xml;
}


function get_points_of_control($country_xml) {
    return (string)$country_xml->summary->ninty_percent_asns["count"];
}


function get_complexity($country_xml) {
    $complexity = $country_xml->summary->complexity;

    return (double) $complexity;
}


function get_ip_address_count($country_xml) {
    return (string)$country_xml->summary->total_ips;
}

//implements the perl spaceship operator
function spaceship($a, $b)
{
    if ( $a  ==  $b) {
        return 0;
    }

    return ($a < $b) ? -1: 1;
}

function cmp_country_complexity(SimpleXMLElement $a, SimpleXMLElement $b) {
    $complexity_a = get_complexity($a);
    $complexity_b = get_complexity($b);

    return spaceship($complexity_a,  $complexity_b);
}

function cmp_ips_per_points_of_control(SimpleXMLElement $a, SimpleXMLElement $b) {
    $ips_per_points_of_control_a = get_ips_per_points_of_control($a);
    $ips_per_points_of_control_b = get_ips_per_points_of_control($b);

    return spaceship( $ips_per_points_of_control_a,  $ips_per_points_of_control_b);
}

function cmp_page_view_country_percent(SimpleXMLElement $a, SimpleXMLElement $b) {

  return  spaceship(get_page_view_country_percent($a), get_page_view_country_percent($b));
}

function country_ip_address_count_gt_noise_threshold($country_xml) {
    $ip_address_noise_threshold = 25000;

    $ip_address_count = get_ip_address_count($country_xml);
    if ( $ip_address_count >   $ip_address_noise_threshold) {
        return true;
    }
    else {
        return false;
    }
}


function country_has_adplanner_data($country_xml) {
    return get_page_view_country_percent($country_xml) != 'N/A';
}

function get_country_name_x(SimpleXMLElement $country) {
    $ret = (string)$country['country_name'];

    return $ret;
}

function get_ips_per_points_of_control(SimpleXMLElement $country) {
    $total_ips =  get_ip_address_count($country);
    $points_of_control         =  get_points_of_control($country);
    return (integer) ($total_ips/$points_of_control);
}

function get_country_top_sites(SimpleXMLElement $country_xml) {
    $ret = (string) $country_xml->ad_words_summary->top_site_count;

    if (!$ret) {
        $ret = 'N/A';
    }

    return $ret ;
}

function get_top_sites_in_country(SimpleXMLElement $country_xml) {
    $ret = (string) $country_xml->ad_words_summary->top_sites_in_country;

    if (!$ret) {
        $ret = 'N/A';
    }

    return $ret ;
}

function get_top_sites_country_percent(SimpleXMLElement $country_xml) {

    $top_site_count = get_country_top_sites($country_xml);
    $top_sites_in_country = get_top_sites_in_country($country_xml);

    if ($top_site_count == 'N/A') {
        return 'N/A';
    }

    return $top_sites_in_country/$top_site_count*100.0;
}

function get_top_sites_PoC_percent(SimpleXMLElement $country_xml) {
    $top_site_count = get_country_top_sites($country_xml);
    $top_sites_in_country = get_top_sites_in_PoC($country_xml);

    if ($top_site_count == 'N/A') {
        return 'N/A';
    }

    return $top_sites_in_country/$top_site_count*100.0;
}

function get_total_page_views(SimpleXMLElement $country_xml) {
    $ret = (string) $country_xml->ad_words_summary->total_page_views;

    if (!$ret) {
        $ret = 'N/A';
    }

    return $ret ;
}

function get_page_views_in_country(SimpleXMLElement $country_xml) {
    $ret = (string) $country_xml->ad_words_summary->page_views_in_country;

    if (!$ret) {
        $ret = 'N/A';
    }

    return $ret ;
}

function get_page_view_country_percent(SimpleXMLElement $country_xml) {

    $total_page_views =  get_total_page_views($country_xml);
    $page_views_in_country = get_page_views_in_country($country_xml);

    if ($total_page_views == 'N/A') {
        return 'N/A';
    }

    return round(100.0*$page_views_in_country/$total_page_views, 2);
}

function get_page_view_PoC_percent(SimpleXMLElement $country_xml) {

    $total_page_views =  get_total_page_views($country_xml);
    $page_views_in_country = get_PoC_page_views($country_xml);

    if ($total_page_views == 'N/A') {
        return 'N/A';
    }

    return round(100.0*$page_views_in_country/$total_page_views, 2);
}

function get_top_sites_in_PoC(SimpleXMLElement $country_xml) {
    $ret = (string) $country_xml->ad_words_summary->top_sites_in_poc;

    $total_page_views =  get_total_page_views($country_xml);

    if ($ret == '') {
        $ret = 'N/A';
    }

    return $ret ;
}

function get_PoC_page_views(SimpleXMLElement $country_xml) {
    $ret = (string) $country_xml->ad_words_summary->page_views_in_poc;

    $total_page_views =  get_total_page_views($country_xml);

    if ($ret == '') {
        $ret = get_top_sites_in_PoC($country_xml);
    }

    return $ret ;
}

function get_country_info_hash(SimpleXMLElement $country) {
    $country_name =  $country['country_name'];
    //$country_name = get_country_name_x($country);
    $country_code =  (string)$country['country_code'];
    $xquery_string = "//country[@country_code='". $country_code . "']/summary/ninty_percent_asns";
    $total_ips =  get_ip_address_count($country);
    $total_asns = $country->summary->total_asns;
    $points_of_control         =  get_points_of_control($country);
    $complexity =  get_complexity($country);
    $ips_per_points_of_control  = get_ips_per_points_of_control($country);

    $ad_planner_country_top_sites = get_country_top_sites($country);
    $ad_planner_top_sites_in_country = get_top_sites_in_country($country);
    $ad_planner_top_sites_country_percent = get_top_sites_country_percent($country);
    $ad_planner_top_sites_in_PoC = get_top_sites_in_PoC($country);
    $ad_planner_top_sites_PoC_percent = get_top_sites_PoC_percent($country);
    $ad_planner_total_page_views = get_total_page_views($country);
    $ad_planner_page_views_in_country = get_page_views_in_country($country);
    $ad_planner_page_view_country_percent = get_page_view_country_percent($country);
    $ad_planner_PoC_page_views = get_PoC_page_views($country);
    $ad_planner_page_view_PoC_percent = get_page_view_PoC_percent($country);

    $ret = array(
        "country_name" => $country_name,
        "country_code" => $country_code,
        "xquery_string" => $xquery_string,
        "total_ips" => $total_ips,
        "total_asns" => $total_asns,
        "points_of_control" => $points_of_control,
        "complexity" => $complexity,
        "ips_per_points_of_control" => $ips_per_points_of_control,
        "ad_planner_country_top_sites" => $ad_planner_country_top_sites,
        "ad_planner_top_sites_in_country" => $ad_planner_top_sites_in_country,
        "ad_planner_top_sites_country_percent" => $ad_planner_top_sites_country_percent,
        "ad_planner_top_sites_in_PoC" => $ad_planner_top_sites_in_PoC,
        "ad_planner_top_sites_PoC_percent" => $ad_planner_top_sites_PoC_percent,
        "ad_planner_total_page_views" => $ad_planner_total_page_views,
        "ad_planner_page_views_in_country" => $ad_planner_page_views_in_country,
        "ad_planner_page_view_country_percent" => $ad_planner_page_view_country_percent,
        "ad_planner_PoC_page_views" => $ad_planner_PoC_page_views,
        "ad_planner_page_view_PoC_percent" => $ad_planner_page_view_PoC_percent,
    );

    return $ret;
}

function country_xml_table_row(SimpleXMLElement $country, $show_rank, $country_rank, $total_countries, $column_list ) {
    //print ("START country_xml_table_row '$country'\n");
    //if (!defined($country) ) die ("XX") ;


    $info_hash = get_country_info_hash($country);

    $country_name  = $info_hash['country_name'];

    $country_code  = $info_hash['country_code'];
    $xquery_string = $info_hash['xquery_string'];
    $total_ips  = $info_hash['total_ips'];
    $total_asns  = $info_hash['total_asns'];
    $points_of_control          = $info_hash['points_of_control'];
    $complexity  = $info_hash['complexity'];
    $ips_per_points_of_control   = $info_hash['ips_per_points_of_control'];
    $info_hash['country_rank'] = "$country_rank of $total_countries";
?>
  <tr>
    <? foreach ($column_list as $column) { ?>

      <td><? if ($column == 'complexity') {
            echo htmlentities(number_format( $info_hash[$column], 2));
        }
        else if ($column == 'country_name') {
          $country_detail_url_prefix = "geo_map_home.php?cc=";
          #uncomment to display old country detail page.
          #$country_detail_url_prefix = "country_detail.php/?cc=";
                ?><a href="<? echo get_local_url($country_detail_url_prefix . urlencode($country_code)) ?>" > <? echo "$country_name";?></a><?
            }
        else if (!is_numeric($info_hash[$column])) {
                echo htmlentities($info_hash[$column]);
            }
        else {
            echo htmlentities(number_format( $info_hash[$column]));
        }
        ?></td>
    <? } ?>
  </tr>
<?
}

function get_country_code_to_name_map() {
    $countries_xml = get_sorted_country_list("cmp_country_complexity", "complex", "complexity");

    $result_array = array();

    $i = 0;
    foreach ($countries_xml as $country_xml) {
        $country_code =  (string)$country_xml['country_code'];
        $country_name  = (string) $country_xml['country_name'];

        $result_array[$country_code] = $country_name;
    }

    asort($result_array);
    return $result_array;
}

function is_country_not_region(SimpleXMLElement $country_xml) {
    return $country_xml['country_code_is_region'] == 0;
}

function get_all_countries() {
    $xml = get_xml_file();
    $countries_xml = $xml->xpath("//country");
    $countries_xml_tmp = array_filter($countries_xml, "is_country_not_region");
    $countries_xml = $countries_xml_tmp;
    return $countries_xml;
}

function get_unsorted_country_list()
{
    $countries_xml = get_all_countries();
    $countries_xml_tmp = array_filter($countries_xml, "country_ip_address_count_gt_noise_threshold");
    $countries_xml = $countries_xml_tmp;
    return $countries_xml;
}

function get_sorted_country_list($sort_function, $sort_type_adjective, $sort_type_noun) {

  $countries_xml = get_unsorted_country_list();

    usort($countries_xml, $sort_function);

    return $countries_xml;
}

function get_excluded_country_names() {
    $countries_xml = get_all_countries();
    $countries_xml_included =  array_filter($countries_xml, "country_ip_address_count_gt_noise_threshold");

    print count( $countries_xml) . " total countries\n";
    print count( $countries_xml_included) . " included countries\n";

    $countries_xml_excluded = array();
    //array_diff doesn't work on object arrays so write our own
    foreach ($countries_xml as $country_xml) {
        if (!in_array($country_xml, $countries_xml_included)) {
            array_push($countries_xml_excluded, $country_xml);
        }
    }
    //print_r($countries_xml);
    //print_r( $countries_xml_excluded );
    $countries_excluded_names = array_map("get_country_name_x", $countries_xml_excluded);

    sort($countries_excluded_names);
    return $countries_excluded_names;

}

function top_countries_table($sort_function, $sort_type_adjective, $sort_type_noun, $list_size) {
    $countries_xml = get_sorted_country_list ($sort_function, $sort_type_adjective, $sort_type_noun) ;

    $countries_xml_high_15 = array_slice($countries_xml, -1* $list_size);

    print "<h1><a name='most'>most $sort_type_adjective</a></h1>";
    country_xml_list_summary_table(array_reverse($countries_xml_high_15), true);
}

function high_15_table($sort_function, $sort_type_adjective, $sort_type_noun) {
    top_countries_table( $sort_function, $sort_type_adjective, $sort_type_noun, 15);
}

 $column_headings = array('country_rank' => 'Rank',
        'country_code' => 'Code',
        'country_name' => 'Country',
        'total_ips' => 'Total IPs',
        'total_asns'=> 'Total Autonomous Systems',
        'points_of_control' => 'Points of Control',
        'ips_per_points_of_control' => 'IPs Per Point of Control',
        'complexity' => 'Complexity',
        'ad_planner_country_top_sites' => 'top sites',
        'ad_planner_top_sites_in_country' => 'top sites in country',
        'ad_planner_top_sites_country_percent' => 'country site %',
        'ad_planner_top_sites_in_PoC' => 'top sites in PoC',
        'ad_planner_top_sites_PoC_percent' => 'PoC sites %',
        'ad_planner_total_page_views' => 'total page views',
        'ad_planner_page_views_in_country' => 'country page views',
        'ad_planner_page_view_country_percent' => 'Country Page View %',
        'ad_planner_PoC_page_views' => 'PoC page views',
        'ad_planner_page_view_PoC_percent' => 'PoC page view %',
    );

function country_xml_list_summary_table($countries_xml, $show_rank) {

  global $column_headings;

    $column_list = array (
        'country_rank',
        'country_name',
        // 'country_code',
        'total_ips',
        'total_asns',
        'points_of_control',
        'ips_per_points_of_control',
        'complexity',
        //                           'ad_planner_country_top_sites',
        //                           'ad_planner_top_sites_in_country',
        //                           'ad_planner_top_sites_country_percent',
        //                           'ad_planner_top_sites_in_PoC',
        //                           'ad_planner_top_sites_PoC_percent',
        //                           'ad_planner_total_page_views',
        //                          'ad_planner_page_views_in_country',
        'ad_planner_page_view_country_percent',
        //                           'ad_planner_PoC_page_views',
        //                           'ad_planner_page_view_PoC_percent',
    );

    if (!$show_rank) {
        array_shift($column_list);
    }

?>
<table class="country_list_table">
<tr>
<?
    foreach ($column_list as $column) {
?>
<td><? echo $column_headings[$column] ?></td>
       <? } ?>
</tr>

<?
    $total_countries = count($countries_xml);

    $current_country_num = 0;

    foreach ($countries_xml as $country) {
        $current_country_num++;
        country_xml_table_row($country, $show_rank, $current_country_num, $total_countries, $column_list);
    }
?>
</table>
<?
}

function csv_dump($countries_xml)
{

  global $column_headings;

 $csv_columns = array(
        'country_code',
        'country_name',
        'total_ips',
        'total_asns',
        'points_of_control',
        'ips_per_points_of_control',
        'complexity',
        'ad_planner_country_top_sites',
        'ad_planner_top_sites_in_country',
        'ad_planner_top_sites_country_percent',
        'ad_planner_top_sites_in_PoC',
        'ad_planner_top_sites_PoC_percent',
        'ad_planner_total_page_views',
        'ad_planner_page_views_in_country',
        'ad_planner_page_view_country_percent',
        'ad_planner_PoC_page_views',
        'ad_planner_page_view_PoC_percent',
    );


  $stdout = fopen("php://output", "w+");
 
  foreach ($csv_columns as $column)
      {
        $csv_header[] =  $column_headings[$column];
      }


  fputcsv($stdout, $csv_header);

  foreach ($countries_xml as $country) {
    $info_hash = get_country_info_hash($country);

    $country_info = array();
    //THIS should really use CLOSURES but UBUNTU doesn't yet have php 5.3
    foreach ($csv_columns as $column)
      {
        $country_info[] = $info_hash[$column];
      }

    fputcsv($stdout, $country_info);
  }
}
