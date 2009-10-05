<?

global $header_text;
$header_text="RAW DATA";
include "./info_page_header.php";

?>
<h1>Data Files</h1>

<p>
The following xml file contains all of the data presented in these web pages, including
</p>
<ul>
<li>the basic data for each country and ASN (name, number of IPs, etc)</li>
<li>the generated Complexity, Points of Control, and IPs per Point of Control data</li>
<li>the network relationships for each ASN within each country.</li>
</ul>

<p> <a href="results/results.xml">Our results in XML format.</a></p>
<p> <a href="./data_csv.php">Our results in CSV format.</a></p>

<p>For more information about the methodology used to generate this data, see the <a href="methods.php">Methods</a> page.<p>

<? 
  include "./info_page_footer.php";
