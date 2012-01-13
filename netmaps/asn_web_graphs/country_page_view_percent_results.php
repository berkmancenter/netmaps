<?

global $header_text;
$header_text="In Country Page View Percent";

include "./info_page_header.php";

include 'country_summary_table.php';
?>

<p>Here we list countries by percent of page views from their internet users for sites within the country. Our data comes from Google AdPlanner.
</p>

<?
  filter_and_display_tables("country_has_adplanner_data", "cmp_page_view_country_percent", "Page View Country Percent", "Page View Country Percent", "lowest");

include "./info_page_footer.php";