<?
/**
 * raw_data.php
 *
 * @package default
 */
header("Content-type: application/octet-stream");
header("Content-Disposition: attachment; filename=\"ad_planner_data.csv\"");

include "./xml_utils.php";

function  get_site_info_columns()
{

$column_headings = array(
		 'site_name',
		 'ip',
		 'asn',
		 'audience_unique_users',
		// 'category',
		// 'composition_index',
		 'country',
		 'country_code',
		 'country_page_views',
		 'country_unique_users'
		// 'gcn_images',
		// 'gcn_videos',
		 );

 return $column_headings;
}

function get_site_info_hash( $site_xml) { 


 $column_headings = get_site_info_columns();

 foreach ( $column_headings as $column_heading )
{
	$site_info_hash[ $column_heading ] = (string) $site_xml-> { $column_heading };
}
		return $site_info_hash;
		 
}

function ad_planner_csv_dump($sites_xml)
{

  $stdout = fopen("php://output", "w+");

  fputcsv( $stdout, get_site_info_columns() );
  //echo "dfdfdf";

  //return;

  foreach ($sites_xml as $site) {
  //echo "Site\n";
    $info_hash = get_site_info_hash($site);
    //print_r( $info_hash );
    fputcsv($stdout, $info_hash);
  }

  //echo "Done outputting sites\n";
}


$sites = get_ad_planner_sites();

 ad_planner_csv_dump( $sites );

//csv_dump($sites);

?>
