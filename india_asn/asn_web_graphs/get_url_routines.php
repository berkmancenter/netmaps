<?

/**
 *
 *
 * @param unknown $country_xml
 * @return unknown
 */
function get_image_url_base($country_xml) {
    $host = $_SERVER["HTTP_HOST"];
    $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
    //print_r($country_xml);
    //print_r($country_xml["country_name"]);
    $country_name = $country_xml['country_name'];
    // $country_name = get_country_name_x($country_xml);
    //print_r($country_name);
    $country_svg_url = "http://$host$path/results/graphs/asn-" .($country_name);

    return $country_svg_url;
}


/**
 *
 *
 * @param unknown $country_xml
 * @return unknown
 */
function get_json_summary_url($country_xml) {
    $host = $_SERVER["HTTP_HOST"];
    $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
    $country_code = $country_xml['country_code'];

    $country_json_summary_url = "http://$host$path/country_json_summary.php/?cc=$country_code";
    return $country_json_summary_url;
}


/**
 *
 *
 * @return unknown
 */
function get_flash_url() {
    $host = $_SERVER["HTTP_HOST"];
    $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
    $country_svg_url = "http://$host$path/flare_demo/asn_visualization.swf";

    return $country_svg_url;
}


/**
 *
 *
 * @param unknown $country_xml
 * @return unknown
 */
function get_country_svg_image_url($country_xml) {
    $country_svg_url =  get_image_url_base($country_xml) . ".svg";

    $country_svg_url = htmlentities($country_svg_url, ENT_QUOTES );
    return $country_svg_url;
}


/**
 *
 *
 * @param unknown $country_xml
 * @return unknown
 */
function get_country_png_image_url($country_xml) {
    $country_svg_url =  get_image_url_base($country_xml) . ".png";
    $country_svg_url = htmlentities($country_svg_url, ENT_QUOTES );
    return $country_svg_url;
}


/**
 *
 *
 * @param unknown $country_xml
 * @return unknown
 */
function get_country_graphml_image_url($country_xml) {
    $country_svg_url =  get_image_url_base($country_xml) . ".graphml";
    $country_svg_url = htmlentities($country_svg_url, ENT_QUOTES );
    return $country_svg_url;
}

/**
 *
 *
 * @return unknown
 */
function get_json_complexity_url() {
    $host = $_SERVER["HTTP_HOST"];
    $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
    $json_complexity_url = "http://$host$path//complexity_json.php";

    return $json_complexity_url;
}
