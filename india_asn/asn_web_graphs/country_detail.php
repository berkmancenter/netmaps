<?

include "./header.php"
?>

<?

$xml_file_location = 'results/results.xml';


$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
?>

<?
   $country_name = $_REQUEST['cn'];
$xml_file_location = 'results/results.xml';
$host = $_SERVER["HTTP_HOST"];
$path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
$country_svg_url = "http://$host$path/results/graphs/asn-$country_name.svg";

$xml = new SimpleXMLElement(file_get_contents($xml_file_location));

  $xquery_string = "//country[@country_name='". $country_name . "']";
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
<table>
<tr>
<td>Country Name</td>
<td>Country Code</td>
<td>Total IPs</td>
</tr>
<tr>
<td><? echo "{$country_xml['country_name']}" ?></td>
<td><? echo "{$country_xml['country_code']}" ?></td>
<td><? echo ((string) $country_xml->summary->total_ips) ?></td>
</tr>
</table>
<h1>Top ISPs</h1>

<table>
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
<p>
<a href="<? echo $country_svg_url ?>">Asn Image Graph</a>
</p>

<p>
<a href="../home.php">back to summary</a>
</p>
</body>
</html>