<?
//include "xml_utils.php";
?>

<?
function display_tables($sort_function, $sort_type_adjective, $sort_type_noun) 
{

  $xml = get_xml_file();
  $countries_xml = $xml->xpath("//country");
  $countries_xml_tmp = array_filter($countries_xml, "country_ip_address_count_gt_noise_threshold");
  
#print_r($countries_xml_tmp);
  
  $countries_xml = $countries_xml_tmp;
  
  usort($countries_xml, $sort_function);
  
  $countries_xml_bottom_15 = array_slice($countries_xml, 0, 15);
  $countries_xml_top_15 = array_slice($countries_xml, -15);
?>
  <h1>Countries by <?echo $sort_type_noun ?> </h1>
  <ul class="mylist" type="disc">
     <li><a href='#most'>most <? echo $sort_type_adjective ?></a></li>
     <li><a href='#least'>least <? echo $sort_type_adjective ?></a></li>
     <li><a href='#all'>all countries</a></li>
  </ul>
<?
  print "<h1><a name='most'>most $sort_type_adjective</a></h1>";
  country_xml_list_summary_table(array_reverse($countries_xml_bottom_15));

  print "<h1><a name='least'>least $sort_type_adjective</a></h1>";
  country_xml_list_summary_table($countries_xml_top_15);
  
  print "<h1><a name='all'>full country list sorted by $sort_type_noun</a></h1>";
  country_xml_list_summary_table($countries_xml);
}
?>
