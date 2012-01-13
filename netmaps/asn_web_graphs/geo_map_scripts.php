<?
/**
 * geo_map_scripts.php
 *
 * @package default
 */


/**
 *
 *
 * @param unknown $div_id
 */
function geo_map_scripts($div_id) {
?>

 <script  type="text/javascript" src="country_to_continent.js"></script>

  <script type='text/javascript'>
<!--//--><![CDATA[//><!--
google.load('visualization', '1', {
    'packages': ['geomap']
});
google.setOnLoadCallback(get_json_info);

var options = {};
var geomap = null;
var data = null;

function get_json_info() {

    var callback = {
        success: drawMapFromJson,
        failure: function (o) {
            alert('ajax failure');
        }
    }

    var transaction = YAHOO.util.Connect.asyncRequest('GET', '<? echo get_json_complexity_url() ?>', callback, null);
}

function drawMapFromJson(json_data) {
    var countries = YAHOO.lang.JSON.parse(json_data.responseText);
    //alert(countries);
    //alert(data);
    data = new google.visualization.DataTable();
    data.addRows(countries.length);
    data.addColumn('string', 'Country');
    data.addColumn('number', 'Complexity');
    data.addColumn('string', 'Hover');

    var i;

    for (i = 0; i < countries.length; i++) {

        var country_name = countries[i]['country_name'];
        var country_code = countries[i]['country_code'];

        if (country_name == 'Russian Federation') {
            country_name = 'Russia';
        }
        else if (country_code == 'IR') {
            country_name = 'Iran';
        }
        else if (country_code == 'TZ') {

            country_name = 'Tanzania';
        }
        else if (country_code == 'TW') {
            country_name = 'Taiwan';
        }

        data.setValue(i, 0, country_code);
        //alert(data);
        var complexity =  countries[i]['complexity'];
        complexity = Number(complexity.toFixed(2));
        //alert(complexity);
        data.setValue(i, 1, complexity);
        data.setValue(i, 2, country_name );
    }

    options['dataMode'] = 'regions';
    options['height'] = '300px';
    options['width'] = '490px';
    options['showZoomOut'] = true;
    options['region'] = 'world';

    redrawMap();
}

function redrawMap(region) {
    var container = document.getElementById('map_canvas');
    geomap = new google.visualization.GeoMap(container);

    google.visualization.events.addListener(geomap, 'regionClick', regionClick_event_handler);
    google.visualization.events.addListener(geomap, 'select', select_event_handler);
    google.visualization.events.addListener(geomap, 'zoomOut', function () {
        options['region'] = 'world';
        redrawMap();
    });

    if (region) {
        if (options['region'] == region) {

            return;
        }
        else {
            options['region'] = region;
        }
    }

    if (options['region'] == 'world') {
        options['showZoomOut'] = false;
    }
    else {
        options['showZoomOut'] = true;
    }

    geomap.draw(data, options);
}

function get_europe_region(country_code) {
    switch (country_code) {
    case "AD":
        // Andorra, Principality of
        return "155";
    case "AL":
        // Albania, Republic of
        return "155";
    case "AT":
        // Austria, Republic of
        return "155";
    case "AX":
        // Åland Islands
        return "151";
    case "BA":
        // Bosnia and Herzegovina
        return "155";
    case "BE":
        // Belgium, Kingdom of
        return "155";
    case "BG":
        // Bulgaria, Republic of
        return "039";
    case "BY":
        // Belarus, Republic of
        return "151";
    case "CH":
        // Switzerland, Swiss Confederation
        return "155";
    case "CZ":
        // Czech Republic
        return "155";
    case "DE":
        // Germany, Federal Republic of
        return "155";
    case "DK":
        // Denmark, Kingdom of
        return "151";
    case "EE":
        // Estonia, Republic of
        return "151";
    case "ES":
        // Spain, Kingdom of
        return "039";
    case "FI":
        // Finland, Republic of
        return "151";
    case "FO":
        // Faroe Islands
        return "151";
    case "FR":
        // France, French Republic
        return "155";
    case "GB":
        // United Kingdom of Great Britain & Northern Ireland
        return "155";
    case "GG":
        // Guernsey, Bailiwick of
        return "151";
    case "GI":
        // Gibraltar
        return "039";
    case "GR":
        // Greece, Hellenic Republic
        return "039";
    case "HR":
        // Croatia, Republic of
        return "155";
    case "HU":
        // Hungary, Republic of
        return "155";
    case "IE":
        // Ireland
        return "155";
    case "IM":
        // Isle of Man
        return "151";
    case "IS":
        // Iceland, Republic of
        return "021";
    case "IT":
        // Italy, Italian Republic
        return "155";
    case "JE":
        // Jersey, Bailiwick of
        return "151";
    case "LI":
        // Liechtenstein, Principality of
        return "151";
    case "LT":
        // Lithuania, Republic of
        return "151";
    case "LU":
        // Luxembourg, Grand Duchy of
        return "151";
    case "LV":
        // Latvia, Republic of
        return "151";
    case "MC":
        // Monaco, Principality of
        return "151";
    case "MD":
        // Moldova, Republic of
        return "151";
    case "ME":
        // Montenegro, Republic of
        return "151";
    case "MK":
        // Macedonia, the former Yugoslav Republic of
        return "151";
    case "MT":
        // Malta, Republic of
        return "151";
    case "NL":
        // Netherlands, Kingdom of the
        return "155";
    case "NO":
        // Norway, Kingdom of
        return "151";
    case "PL":
        // Poland, Republic of
        return "155";
    case "PT":
        // Portugal, Portuguese Republic
        return "039";
    case "RO":
        // Romania
        return "039";
    case "RS":
        // Serbia, Republic of
        return "155";
    case "RU":
        // Russian Federation
        return "151";
    case "SE":
        // Sweden, Kingdom of
        return "151";
    case "SI":
        // Slovenia, Republic of
        return "151";
    case "SJ":
        // Svalbard & Jan Mayen Islands
        return "151";
    case "SK":
        // Slovakia (Slovak Republic)
        return "155";
    case "SM":
        // San Marino, Republic of
        return "151";
    case "UA":
        // Ukraine
        return "151";
    case "VA":
        // Holy See (Vatican City State)
        return "155";

    }
}

function get_AsianRegion(country_code) {

    switch (country_code) {
    case "AE":
        // United Arab Emirates
        return "145";
    case "AF":
        // Afghanistan, Islamic Republic of
        return "145";
    case "AM":
        // Armenia, Republic of
        return "143";
    case "AZ":
        // Azerbaijan, Republic of
        return "143";
    case "BD":
        // Bangladesh, People's Republic of
        return "034";
    case "BH":
        // Bahrain, Kingdom of
        return "145";
    case "BN":
        // Brunei Darussalam
        return "035";
    case "BT":
        // Bhutan, Kingdom of
        return "035";
    case "CC":
        // Cocos (Keeling) Islands
        return "035";
    case "CN":
        // China, People's Republic of
        return "030";
    case "CX":
        // Christmas Island
        return "035";
    case "CY":
        // Cyprus, Republic of
        return "039";
    case "GE":
        // Georgia
        return "143";
    case "HK":
        // Hong Kong, Special Administrative Region of China
        return "034";
    case "ID":
        // Indonesia, Republic of
        return "035";
    case "IL":
        // Israel, State of
        return "145";
    case "IN":
        // India, Republic of
        return "034";
    case "IO":
        // British Indian Ocean Territory (Chagos Archipelago)
        return "034";
    case "IQ":
        // Iraq, Republic of
        return "145";
    case "IR":
        // Iran, Islamic Republic of
        return "145";
    case "JO":
        // Jordan, Hashemite Kingdom of
        return "145";
    case "JP":
        // Japan
        return "030";
    case "KG":
        // Kyrgyz Republic
        return "145";
    case "KH":
        // Cambodia, Kingdom of
        return "035";
    case "KP":
        // Korea, Democratic People's Republic of
        return "030";
    case "KR":
        // Korea, Republic of
        return "030";
    case "KW":
        // Kuwait, State of
        return "145";
    case "KZ":
        // Kazakhstan, Republic of
        return "145";
    case "LA":
        // Lao People's Democratic Republic
        return "034";
    case "LB":
        // Lebanon, Lebanese Republic
        return "145";
    case "LK":
        // Sri Lanka, Democratic Socialist Republic of
        return "034";
    case "MM":
        // Myanmar, Union of
        return "035";
    case "MN":
        // Mongolia
        return "030";
    case "MO":
        // Macao, Special Administrative Region of China
        return "030";
    case "MV":
        // Maldives, Republic of
        return "034";
    case "MY":
        // Malaysia
        return "035";
    case "NP":
        // Nepal, State of
        return "035";
    case "OM":
        // Oman, Sultanate of
        return "145";
    case "PH":
        // Philippines, Republic of the
        return "035";
    case "PK":
        // Pakistan, Islamic Republic of
        return "034";
    case "PS":
        // Palestinian Territory, Occupied
        return "145";
    case "QA":
        // Qatar, State of
        return "145";
    case "SA":
        // Saudi Arabia, Kingdom of
        return "145";
    case "SG":
        // Singapore, Republic of
        return "035";
    case "SY":
        // Syrian Arab Republic
        return "145";
    case "TH":
        // Thailand, Kingdom of
        return "035";
    case "TJ":
        // Tajikistan, Republic of
        return "145";
    case "TL":
        // Timor-Leste, Democratic Republic of
        return "035";
    case "TM":
        // Turkmenistan
        return "143";
    case "TR":
        // Turkey, Republic of
        return "143";
    case "TW":
        // Taiwan
        return "030";
    case "UZ":
        // Uzbekistan, Republic of
        return "145";
    case "VN":
        // Vietnam, Socialist Republic of
        return "034";
    case "YE":
        // Yemen
        return "145";
    }
}

function get_zoom_region(country_code) {
    var country_to_continent = get_country_code_to_continent_list();

    var continent = country_to_continent[country_code];

    var filter = [{
        column: 1,
        value: country_code
    }];

    //alert(filter);
    //alert(filter[0]);
    //filter[0][value] = country_code;

    //alert (data.getFilteredRows(filter) + "'");
    //alert ("baz");
    switch (continent) {
    case "AF":
        //Africa
        return "002";
    case "AN":
        //Antarctica
        return "world";
    case "AS":
        //Asia
        return get_AsianRegion(country_code);
    case "EU":
        //Europe
        return get_europe_region(country_code);
    case "NA":
        return "021";
    case "OC":
        // Oceania
        return "world";
    case "SA":
        // South America
        return "005";
    }
}

<? include "./mapped_countries_list.php" ?>

function update_asn_graph_country(country_code, asn_diagram_wrapper_id) {

  //Javascript should have real default params but we can fake them...
  asn_diagram_wrapper_id 
      = typeof(asn_diagram_wrapper_id) != 'undefined' ? asn_diagram_wrapper_id : "asn_diagram_wrapper";

  var asn_diagram_wrapper = document.getElementById(asn_diagram_wrapper_id);
  
  var json_url_param = document.evaluate("//div[@id='" + asn_diagram_wrapper_id + "']//param[@name='FlashVars']", asn_diagram_wrapper, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null ).singleNodeValue;

    var json_url_param_value = json_url_param.value;
    var json_url_param_new_value = json_url_param_value.replace(/cc=../, 'cc=' + country_code);
    json_url_param.value = json_url_param_new_value;

    var flash_embed_tag_id = document.evaluate("//div[@id='" + asn_diagram_wrapper_id + "']//embed[@name='flash_embed_tag_id']", asn_diagram_wrapper, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null ).singleNodeValue;

    flash_embed_tag_id.setAttribute('FlashVars', json_url_param_new_value);
    flash_embed_tag_id.setAttribute('flashvars', json_url_param_new_value);

    var country_flash_map_header 
      = document.evaluate("//div[@id='" + asn_diagram_wrapper_id + "']//div[@class='vis_head']/span[@class='vis_heading']",
                          asn_diagram_wrapper, null, 
                          XPathResult.FIRST_ORDERED_NODE_TYPE, null ).singleNodeValue;

    var country_name = country_code_to_name(country_code);
    country_flash_map_header.innerHTML = '';
    country_flash_map_header.innerHTML = 'AUTONOMOUS SYSTEM DIAGRAM - ' + country_name;

    var asn_diagram_wrapper_html = asn_diagram_wrapper.innerHTML;
    asn_diagram_wrapper.innerHTML = '';
    asn_diagram_wrapper.innerHTML =  asn_diagram_wrapper_html  + '';
    return;
}

function regionClick_event_handler(e) {
    var country_code = e.region;

    if (country_has_map(country_code)) {
        //alert (country_code + "has map");
        update_asn_graph_country(country_code);

        redrawMap(get_zoom_region(country_code));
        geomap.setSelection(country_code);
    }
    else {
        //alert (country_code + "has no map");
    }
}

function select_event_handler() {
    var selection = geomap.getSelection();
    //alert(selection);
}

function update_select_country() {
    //alert('in update_select_country');
    var country_drop_down = document.getElementById('country_drop_down');
    var country_code = country_drop_down.value;
    //alert(country_code);
    update_asn_graph_country(country_code);
    redrawMap(get_zoom_region(country_code));
    //alert('exiting update_select_country');
}

//--><!]]>
  </script>

<?
}
