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

<p> <a href="results/results.xml">Complete country, autonomous system, and relationship data (XML file).</a></p>
<p> <a href="./data_csv.php">Summary of country data (CSV file).</a></p>

<p>For more information about the methodology used to generate this data, see the <a href="methods.php">Methods</a> page.<p>

<? 
  include "./info_page_footer.php";
