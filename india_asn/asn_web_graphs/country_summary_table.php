<?

$xml_file_location = 'results/results.xml';


$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
?>

<table>
<tr>
<td>Country</td>
<td>Code</td>
<td>Total IPs</td>
<td>number of 90 controlling AS</td>
</tr>

<?
foreach ($xml->country as $country) 
{
  $country_code =  (string)$country['country_code'];
  $country_name =  (string)$country['country_name'];

 # print_r( $country_code);
 # print_r($country);
?>
  <tr>
    
    <td> <a href=<? echo "\"country_detail.php/?cn=$country_name\"" ?> > <? echo "{$country['country_name']}"; ?>
</a></td>
    <td><? echo "{$country['country_code']}"; ?></td>
    <td><? echo $country->summary->total_ips; ?></td>
<?
   #print_r( $country_code); print_r(' ');
   $xquery_string = "//country[@country_code='". $country_code . "']/summary/as/percent_monitorable[. > 90]";
 #  print_r( $xquery_string);
 ?>
    <td>
        <?# print_r($country->xpath($xquery_string)); ?>
        <? echo count($country->xpath($xquery_string)) ?></td>
  </tr>
<?  
}
?>

</table>