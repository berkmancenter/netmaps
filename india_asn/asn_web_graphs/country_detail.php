<?
$country_code = $_REQUEST['cc'];
validate_country_code($country_code);
$xml_file_location = 'results/results.xml';

$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
$xquery_string = "//country[@country_code='$country_code']";
$result_array = $xml->xpath($xquery_string);
$country_xml = $result_array[0];

$xml_file_location = 'results/results.xml';

$country_name = $country_xml['country_name'];

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

include "./header.php"
?>

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

function get_country_png_image_url($country_xml)
{
  $host = $_SERVER["HTTP_HOST"];
  $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
#print_r($country_xml);
#print_r($country_xml["country_name"]);
  $country_name = $country_xml['country_name'];
 # $country_name = get_country_name_x($country_xml);
#print_r($country_name);
  $country_svg_url = "http://$host$path/results/graphs/asn-" .($country_name) . ".png";

  $country_svg_url = htmlentities ($country_svg_url, ENT_QUOTES );
  return $country_svg_url;
}

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

  <? country_xml_list_summary_table(array($country_xml), false); ?>


<?
$country_svg_url = get_country_svg_image_url($country_xml);
$country_png_url = get_country_png_image_url($country_xml);
?>
<h1>Country Network Map</h1>
<img src ="<? echo $country_png_url ?>" alt="country map"/>

<p>
  <b>Note: The red node depicts the wider Internet outside this country.</b>
</p>
<p><a href="<? echo $country_svg_url ?>">Download</a> the full image in SVG format.</p>

<h1>Top 50 Autonomous Systems</h1>

<table>
 <? ?>
<tr>
<td>autonomous system</td>
<td>organization</td>
<td>connected ips</td>
<td>direct ips</td>
</tr>
<?
foreach ($country_xml->summary->as as $as)
{
  $percent_monitorable_str = number_format($as->percent_monitorable, 1);
  $total_monitorable_str   = number_format($as->effective_monitorable_ips);

  $percent_direct_str = number_format($as->percent_direct_ips, 1);
  $total_direct_str   = number_format($as->direct_ips);
  $is_point_of_control = $as["point_of_control" ]==1;
?>
<tr <? if ($is_point_of_control) { ?> id="poc_asn_row" <? } ?> >
<td><? echo $as->asn ?></td>
<td><? echo $as->organization_name ?></td>
<td><? print htmlentities("$total_monitorable_str ($percent_monitorable_str%)",ENT_QUOTES ); ?></td>
<td><? print htmlentities("$total_direct_str ($percent_direct_str%)",ENT_QUOTES ); ?></td>
</tr>

<?
    } 
?>
</table>

<p>
<a href="../home.php">back to summary</a>
</p>
<?
include "footer.php";
?>
