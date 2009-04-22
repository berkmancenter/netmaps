<?
include "header.php";
?>
<p>
Here you will find country-based maps of Internet autonomous systems.  We use the maps to generate two different metrics of the controllability of the Internet in each country -- IPs per Points of Control and Complexity -- and present a sorted list of all countries for each metric.</p>

<p>
To see the map for a given country, click on either of the lists below and then click on the desired country name.  For more information about the methodology used for the metrics and the maps, see the <a href="methods.php">Methods</a> page.  For an xml file containing the raw data, including the network connections and the metrics for every country, see the <a href="raw_data.php">Raw Data</a> page. 
</p>

    <? // top_countries_table("cmp_ips_per_points_of_control", "IPs per point of control", "IPs per point of control", 10); ?>
<h1><a href="ips_per_points_of_control_results.php">Countries ranked by IP addresses per point of control</a></h1>
<p>
<ul>
<li><a href="ips_per_points_of_control_results.php#most">Most IP addresses per point of control</a></li>
<li><a href="ips_per_points_of_control_results.php#least">Least IP addresses per point of control</a></li>
<li><a href="ips_per_points_of_control_results.php#all">Full List</a></li>
</ul>

<h1><a href="country_complexity_results.php">Countries ranked by network complexity</a></h1>
<ul>
<li><a href="country_complexity_results.php#most">Most complex networks</a></li>
<li><a href="country_complexity_results.php#least">Least complex networks</a></li>
<li><a href="country_complexity_results.php#all">Full List</a></li>
</ul>
</p>
<?
include "footer.php";
?>