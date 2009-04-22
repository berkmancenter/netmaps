<?
//include "xml_utils.php";
?>

<?


function display_tables($sort_function, $sort_type_adjective, $sort_type_noun) 
{

  $countries_xml = get_sorted_country_list ($sort_function, $sort_type_adjective, $sort_type_noun) ;
  
  $countries_xml_low_15 = array_slice($countries_xml, 0, 15);
  $countries_xml_high_15 = array_slice($countries_xml, -15);
?>
<p>To see the map for a given country, click on one of the lists below and then click on the desired country name.  For more information about the methodology used for the metrics and the maps, see the <a href="methods.php">Methods</a> page.  For an xml file containing the raw data, including the network connections and the metrics for every country, see the <a href="raw_data.php">Raw Data</a> page. </p>
  <h1>Countries by <?echo $sort_type_noun ?> </h1>
  <ul class="mylist" type="disc">
     <li><a href='#most'>most <? echo $sort_type_adjective ?></a></li>
     <li><a href='#least'>least <? echo $sort_type_adjective ?></a></li>
     <li><a href='#all'>all countries</a></li>
  </ul>
<?
  print "<h1><a name='least'>least $sort_type_adjective</a></h1>";
  country_xml_list_summary_table($countries_xml_low_15, true);

  print "<h1><a name='most'>most $sort_type_adjective</a></h1>";
  country_xml_list_summary_table(array_reverse($countries_xml_high_15), true);
  
  print "<h1><a name='all'>full country list sorted by $sort_type_noun</a></h1>";
  country_xml_list_summary_table($countries_xml, true);
}
?>
