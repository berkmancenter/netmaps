<?

#generate a javascript global array  _cc_to_country_name
function create_code_to_country_array()
{
  $countries_list =  get_sorted_country_list("cmp_country_complexity", "complex", "complexity"); 

  print "var _cc_to_country_name = { \n";

  foreach ($countries_list as $country_xml)
    {
      $country_name =  $country_xml['country_name']; 
      $country_code =  (string)$country_xml['country_code'];
      print "$country_code : \"$country_name\",\n";

    }
  print "};\n";
}

 create_code_to_country_array();

?>

 function country_has_map(country_code)
 {
   if (_cc_to_country_name[country_code])
     {
       return true;
     }
   else
     {
       return false;
     }
 }

 function country_code_to_name(country_code)
 {
   return _cc_to_country_name[country_code];
 }



