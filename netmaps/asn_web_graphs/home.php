<?
/**
 * home.php
 *
 * @package default
 */


include "header.php";
?>


<? include "about_text.php"; ?>

    <? // top_countries_table("cmp_ips_per_points_of_control", "IPs per point of control", "IPs per point of control", 10); ?>
<h1><a href="ips_per_points_of_control_results.php">Countries ranked by IP addresses per point of control</a></h1>
<ul>
<li><a href="ips_per_points_of_control_results.php#least">Fewest IP addresses per point of control</a></li>
<li><a href="ips_per_points_of_control_results.php#most">Most IP addresses per point of control</a></li>
<li><a href="ips_per_points_of_control_results.php#all">Full List</a></li>
</ul>

<h1><a href="country_complexity_results.php">Countries ranked by network complexity</a></h1>
<ul>
<li><a href="country_complexity_results.php#least">Least complex networks</a></li>
<li><a href="country_complexity_results.php#most">Most complex networks</a></li>
<li><a href="country_complexity_results.php#all">Full List</a></li>
</ul>
</p>
<?
include "footer.php";
?>
