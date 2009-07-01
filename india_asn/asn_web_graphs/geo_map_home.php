<?

include "./header.php"
?>

<?

function get_json_complexity_url()
{
  $host = $_SERVER["HTTP_HOST"];
  $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
  $json_complexity_url = "http://$host$path//complexity_json.php";

  return $json_complexity_url;
}


function geo_map_scripts($div_id)
{
?>
  <script type='text/javascript'>
<!--//--><![CDATA[//><!--

   google.load('visualization', '1', {'packages': ['geomap']});
   google.setOnLoadCallback(get_json_info);


    function get_json_info()
   {

   var callback = 
   { 
   success: drawMapFromJson, 
   failure: function(o) { alert ('ajax failure');}
   }
 
   var transaction = YAHOO.util.Connect.asyncRequest('GET', '<? echo get_json_complexity_url() ?>', callback, null);
   }

   function drawMapFromJson(json_data)
   {
     var countries = YAHOO.lang.JSON.parse(json_data.responseText);
     //alert(countries);
     //alert(data);
  var data = new google.visualization.DataTable();
      data.addRows( countries.length);
      data.addColumn('string', 'Country');
      data.addColumn('number', 'Complexity');

     var i;

     for (i = 0 ; i < countries.length; i++) {

      var country_name =  countries[i]['country_name'];
      var country_code =  countries[i]['country_code'];
 
      if (country_name == 'Russian Federation')
      {
          country_name = 'Russia';
      }
      else if (country_code == 'IR')
      {
          country_name = 'Iran';
      }
      else if (country_code == 'TZ')
          {

              country_name = 'Tanzania';
          }
      else if (country_code == 'TW')
          {
              country_name = 'Taiwan';
          }

      data.setValue(i, 0, country_name);
                      //alert(data);
      data.setValue(i, 1, countries[i]['complexity']);
    }


      var options = {};
      options['dataMode'] = 'regions';
      options['height']   = '1000px'
      var container = document.getElementById('map_canvas');
      var geomap = new google.visualization.GeoMap(container);

      google.visualization.events.addListener(geomap, 'regionClick', regionClick_event_handler);

      geomap.draw(data, options);
   }

  function regionClick_event_handler(e)
  {

    var url = 'http://localhost/asn_web_graphs/country_detail.php/?cc=' + e.region;

    //alert (url);

      var json_url_param = document.getElementById('json_url_parm');

      
      var json_url_param_value = json_url_param.value;

      //.replace(/cc=??/, 'cc=' . e.region);

      //alert(json_url_param_value);

      var json_url_param_new_value = json_url_param_value.replace(/cc=../, 'cc=' + e.region);

      // alert(json_url_param_value.replace(/cc=../, 'cc=' + e.region));

      // alert ('json_url_param.value ' + json_url_param.value);

      var flash_embed_tag_id = document.getElementsByName('flash_embed_tag_id')[0];

      //flash_embed_tag_id = flash_embed_tag_id.attributes['FlashVars'];

      //alert ('flash_embed_tag_id.flashvars ' + flash_embed_tag_id.getAttribute('FlashVars'));


            json_url_param.value=json_url_param_new_value;
            flash_embed_tag_id.setAttribute('FlashVars', json_url_param_new_value);
            flash_embed_tag_id.setAttribute('flashvars', json_url_param_new_value);

      // alert ('json_url_param.value ' + json_url_param.value);
      //alert ('flash_embed_tag_id.flashvars' + flash_embed_tag_id.getAttribute('FlashVars'));




      var country_flash_map_header = document.getElementById('country_flash_map_header');

      
      country_flash_map_header.innerHTML='';
      
      country_flash_map_header.innerHTML='Showing ASN map for ' + e.region;

      var country_flash_object_div = document.getElementById('country_flash_object');
      var country_map_html =  country_flash_object_div.innerHTML;

      country_flash_object_div.innerHTML =  '';
      country_flash_object_div.innerHTML =  country_map_html + '';


  }

//--><!]]>
  </script>

<?
}
?>
<?

function get_image_url_base($country_xml)
{
  $host = $_SERVER["HTTP_HOST"];
  $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
#print_r($country_xml);
#print_r($country_xml["country_name"]);
  $country_name = $country_xml['country_name'];
 # $country_name = get_country_name_x($country_xml);
#print_r($country_name);
  $country_svg_url = "http://$host$path/results/graphs/asn-" .($country_name);

  return $country_svg_url;
}

function get_json_summary_url($country_xml)
{
  $host = $_SERVER["HTTP_HOST"];
  $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
  $country_code = $country_xml['country_code'];
  
  $country_json_summary_url = "http://$host$path/country_json_summary.php/?cc=$country_code";
  return $country_json_summary_url;
}

function get_flash_url()
{
  $host = $_SERVER["HTTP_HOST"];
  $path = rtrim(dirname($_SERVER["PHP_SELF"]), "/\\");
  $country_svg_url = "http://$host$path/flare_demo/asn_visualization.swf";

  return $country_svg_url;
}


function get_country_svg_image_url($country_xml)
{
  $country_svg_url =  get_image_url_base($country_xml) . ".svg";

  $country_svg_url = htmlentities ($country_svg_url, ENT_QUOTES );
  return $country_svg_url;
}

function get_country_png_image_url($country_xml)
{
  $country_svg_url =  get_image_url_base($country_xml) . ".png";
  $country_svg_url = htmlentities ($country_svg_url, ENT_QUOTES );
  return $country_svg_url;
}

function get_country_graphml_image_url($country_xml)
{
  $country_svg_url =  get_image_url_base($country_xml) . ".graphml";
  $country_svg_url = htmlentities ($country_svg_url, ENT_QUOTES );
  return $country_svg_url;
}

function embed_flash_object($country_code)
{
$xml_file_location = 'results/results.xml';

$xml = new SimpleXMLElement(file_get_contents($xml_file_location));
$xquery_string = "//country[@country_code='$country_code']";
$result_array = $xml->xpath($xquery_string);
$country_xml = $result_array[0];

?>


       <h1 id='country_flash_map_header'>Showing ASN map for CN</h1>

       <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
			id="demos" width="1000" height="1000"
			codebase="http://fpdownload.macromedia.com/get/flashplayer/current/swflash.cab">
			<param name="movie" value="asn_visualization.swf" />
			<param name="quality" value="high" />
			<param name="bgcolor" value="#ffffff" />
			<param name="allowScriptAccess" value="sameDomain" />
                        <param id='json_url_parm' name="FlashVars" value="json_url=<? echo get_json_summary_url($country_xml) ?>" />
			<embed name='flash_embed_tag_id' src="<? echo get_flash_url() ?>" quality="high" bgcolor="#ffffff"
				width="1000" height="1000" name="demos" align="middle"
				play="true"
				loop="false"
				quality="high"
				allowScriptAccess="sameDomain"
				type="application/x-shockwave-flash"
                                FlashVars="json_url=<? echo get_json_summary_url($country_xml) ?>"
				pluginspage="http://www.adobe.com/go/getflashplayer">
			</embed>
	</object>
<?
    }
?>


<?
geo_map_scripts('map_canvas');
?>

<table>
<tr>
<td>
<h1>World Complexity Map</h1>

<div id='map_canvas'></div>
</td>
<td>
<div id='country_flash_object'>
  <? embed_flash_object('CN'); ?>
</div>
</td>
</tr>
</table>

<?
include "footer.php";
?>
