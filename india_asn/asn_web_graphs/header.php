<?
error_reporting(E_ALL | (E_NOTICE | E_STRICT) );
#ini_set("display_errors", 1);
include "xml_utils.php";

$host = $_SERVER["HTTP_HOST"];
$path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");


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

<title>ASN map</title>
  </head>
  <body>
<div id="mainnav">
<div>
<ul>
<li><a href="<? echo "http://$host$path"?>/home.php">Home</a></li>
<li><a href="ips_per_points_of_control_results.php">IPs per Points of Controls</a></li>
<li><a href="country_complexity_results.php">Network complexity</a></li>
<li>  </li>
</ul>
</div>
</div>
<br/>
<br/>