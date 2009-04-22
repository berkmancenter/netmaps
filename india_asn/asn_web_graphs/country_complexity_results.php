<?
include "header.php";
?>
<p>
Here we list countries by the complexity of the network of autonomous systems within the country.  This metric captures the number of connections between asns within the country, weighted by the number of children with more than one parent and by the number of IP addresses at the edges of the network.   This metric is intended as a rough metric of the difficulty of controlling which users are able to connect to the Internet and how they are able to connect.
</p> 
<?

include 'country_summary_table.php';

display_tables("cmp_country_complexity", "complex", "complexity"); 
?>
<?
include "footer.php";
?>
