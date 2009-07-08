<?
error_reporting(E_ALL | (E_NOTICE | E_STRICT) );
#ini_set("display_errors", 1);
include "xml_utils.php";

$host = $_SERVER["HTTP_HOST"];
$path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");

function get_path()
{
  return trim(dirname($_SERVER["PHP_SELF"]), "/\\");
}

function get_local_url($file)
{
  $host = $_SERVER["HTTP_HOST"];
  $path = get_path();
  return "http://$host/$path/$file";
}

function get_country_name_from_code()
{
  $country_code = $_REQUEST['cc'];
  validate_country_code($country_code);
  $xml_file_location = 'results/results.xml';
  
  $xml = new SimpleXMLElement(file_get_contents($xml_file_location));
  $xquery_string = "//country[@country_code='$country_code']";
  $result_array = $xml->xpath($xquery_string);
  $country_xml = $result_array[0];
  
  $xml_file_location = 'results/results.xml';
  
  $country_name = $country_xml['country_name'];
  return $country_name;
}

function get_page_title()
{
  $page = $_SERVER['SCRIPT_NAME'];
  $page = substr($page, 1);

  $path = get_path();

  #print_r("$path/home.php");

  switch ($page) {
  case "$path/home.php":
    return "Home";
    break;
  case $path .'/ips_per_points_of_control_results.php':
    return "IPs per Points of Control";
    break;
 case $path . '/country_complexity_results.php':
    return "Network Complexity";
    break;
  case $path . 'raw_data.php':
    return "Raw Data";
    break;
  case $path . '/country_detail.php':
    return "Country Report: " . get_country_name_from_code();
     break;
  case $path . '/methods.php':
    return "Methods";
    break;

  case $path . '/geo_map_home.php':
    return "GeoMap Visualization Demo";
    break;

  default:
    return "???'$page'???";
    break;
  }
}

?>
<!DOCTYPE html PUBLIC
     "-//W3C//DTD XHTML 1.0 Transitional//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />

<link rel="stylesheet" href="http://yui.yahooapis.com/2.6.0/build/reset-fonts-grids/reset-fonts-grids.css" /> <style type="text/css"></style>

<link rel="stylesheet" type="text/css"
 href="http://yui.yahooapis.com/2.5.2/build/fonts/fonts-min.css" />

<link rel="stylesheet" type="text/css" href="<? echo "http://$host$path"?>/style.css" media="all" />

<script type="text/javascript" src="<? echo "http://$host$path"?>/yui/build/yahoo/yahoo-min.js" ></script> 

<script type="text/javascript" src="<? echo "http://$host$path"?>/yui/build/event/event-debug.js" ></script> 
<script src="<? echo "http://$host$path"?>/yui/build/connection/connection-debug.js"
   type="text/javascript"></script> 
  <script  type="text/javascript" src="<? echo "http://$host$path"?>/yui/build/json/json-min.js"></script> 

  <script type='text/javascript' src='http://www.google.com/jsapi'></script>


  <title>Mapping Local Internet Control - <? echo get_page_title() ?></title>
  </head>
  <body>
<div id="mainnav">
<div>
<ul>
<li><a href="<? echo get_local_url('home.php') ?>">Home</a></li>
<li><a href="<? echo get_local_url('ips_per_points_of_control_results.php') ?>">IPs per Point of Control</a></li>
<li><a href="<? echo get_local_url('country_complexity_results.php') ?>">Network Complexity</a></li>
<li><a href="<? echo get_local_url('methods.php') ?>">Methods</a></li>
<li><a href="<? echo get_local_url('raw_data.php') ?>">Raw Data</a></li>
<li>  </li>
</ul>
</div>
</div>
<br/>
<br/>
<h1>Mapping Local Internet Control [private draft - please don't share]</h1>
<i>from the <a href="http://cyber.law.harvard.edu">Berkman Center for Intenet &amp; Society at Harvard University</a></i>
