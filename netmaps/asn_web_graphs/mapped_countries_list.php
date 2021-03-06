<?
/**
 * mapped_countries_list.php
 *
 * @package default
 */


/**
 * generate a javascript global array  _cc_to_country_name
 */
function create_code_to_country_array() {
    $country_code_to_name_map = get_country_code_to_name_map();

    print "var _cc_to_country_name = { \n";

    foreach ($country_code_to_name_map as $country_code => $country_name) {
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
