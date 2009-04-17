<?
include "./header.php"
?>

<?

$xml_file_location = 'results/results.xml';


$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
?>
<?
function validate_country_code($country_code)
{
  if (strlen($country_code) != 2)
    {
      die ("illegal country code");
    }  

  if (preg_match("/[^A-Z]/", $country_code))
    {
      die ("illegal country code");
    }
}

?>
<?
$country_code = $_REQUEST['cc'];
validate_country_code($country_code);
$xml_file_location = 'results/results.xml';

$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
$xquery_string = "//country[@country_code='$country_code']";
$result_array = $xml->xpath($xquery_string);
$country_xml = $result_array[0];

?>

<?
/*

<Applet code="net.claribole.zgrviewer.ZGRApplet.class" archive="zvtm-0.9.8.jar,zgrviewer-0.8.2.jar" width="850" height="600"> 
 <param name="type" value="application/x-java-Applet;version=1.4" />
  <param name="scriptable" value="false" /> 
 <param name="width" value="850" />
  <param name="height" value="600" />
  <param name="svgURL" value="<? echo $country_svg_url ?>" /> 
 <param name="title" value="zgrviewer - Applet" /> 
 <param name="appletBackgroundColor" value="#FFFFFF" /> 
  <param name="graphBackgroundColor" value="#FFFFFF" /> 
 <!-- <param name="highlightColor" value="red" />  -->
  </Applet> 
*/
?>

<h1>Country Statistics</h1>

<? country_xml_list_summary_table(array($country_xml)); ?>

<h1>Top ASNs</h1>

<table>
 <? ?>
<tr>
<td>asn</td>
<td>organization</td>
<td>percent monitorable</td>
<td>monitorable ips</td>
<td>direct ips</td>
</tr>
<?
foreach ($country_xml->summary->as as $as)
{
?>
<tr>
<td><? echo $as->asn ?></td>
<td><? echo $as->organization_name ?></td>
<td><? echo $as->percent_monitorable ?></td>
<td><? echo $as->monitorable_ips ?></td>
<td><? echo $as->direct_ips ?></td>
</tr>
<?
    } 
?>
</table>
<?

function get_country_svg_image_url($country_xml)
{
  $host = $_SERVER["HTTP_HOST"];
  $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
#print_r($country_xml);
#print_r($country_xml["country_name"]);
  $country_name = $country_xml['country_name'];
 # $country_name = get_country_name_x($country_xml);
#print_r($country_name);
  $country_svg_url = "http://$host$path/results/graphs/asn-" .($country_name) . ".svg";

  $country_svg_url = htmlentities ($country_svg_url, ENT_QUOTES );
  return $country_svg_url;
}

?>
<?
$country_svg_url = get_country_svg_image_url($country_xml);
?>

<iframe src ="<? echo $country_svg_url ?>" width="800" height="800">
  <p>Your browser does not support iframes.</p>
</iframe>

<p>

<a href="<? echo $country_svg_url ?>">Asn Image Graph</a>
</p>

<p>
<a href="../home.php">back to summary</a>
</p>
</body>
</html>