<?


global $header_text;
$header_text="RESEARCH";
include "./info_page_header.php";

?>

<h1>Overview</h1>
<p>
There are over <a href="http://www.internetworldstats.com/stats.htm">1.5 billion</a> users on the Internet, but all of those users connect through only about <a href="http://www.potaroo.net/tools/asn16/">30,000</a> autonomous systems (ASs).  ASs are generally Internet service providers but can also be large companies, universities, and other such organizations who act as independent entities on the Internet.  These ASs are responsible for assigning individual IP addresses and routing traffic from individual machines / IP addresses out to and in from the wider Internet.  So controlling the traffic (filtering, surveilling, blocking, etc) of those 1.5 billion users only requires controlling those 30,000 ASs.  But the vast majority of those ASs are small organizations that rely on one or more larger ASs for access to the wider Internet, so the vast majority of traffic flows through this much smaller slice of less than a thousand large ASs.
</p>
<p>
It is well understood now that governments exert various kinds of control over their local zones of the Internet, including <a href="http://opennet.net">filtering offensive sites</a>,
 <a href="http://eur-lex.europa.eu/LexUriServ/site/en/oj/2006/l_105/l_10520060413en00540063.pdf">surveilling the activities of users</a>,
and <a href="http://arstechnica.com/tech-policy/news/2009/04/korea-fits-itself-for-a-3-strikes-jackboot.ars">controlling which users  can access the Internet at all</a>.  When broken down into individual countries,
the number of ASs that have access to almost all of the traffic within a given country is at most a few dozen ASs and often only a few ASs, even for the biggest countries.  For
example, we have found that in <a href="country_detail.php/?cc=CN">China</a> over 90% of the country's approximately 190 million IP addresses ultimately connect to the wider Internet through one of only 4 ASs, while in <a href="country_detail.php/?cc=RU">Russia</a> 90% of the country's approximately 20 million IP addresses connect through one of 36 ASs.
</p>


<p>The maps on this site are a rough attempt to map how the ASs in each given country connect to one another and to the rest of the world, with a particular eye for developing metrics for the relative costs of controlling the Internet in each country.  For each country, we provide a visual map of the network of ASs, as well as the following core metrics based on the country AS network data:
</p>
<ul>
<li>Connected IPs: the total number of IP addresses connected to the Internet through this AS, including the IP addresses connected through any children ASs</li>
<li>Points of Control: the minimum set of ASs required to connect to 90% of the IP addresses in each country</li>
<li>IPs per Point of Control: the total number of IP addresses in each country divided by the number of points of control</li>
<li>Complexity: the overall complexity of the network connecting the ASs in each country </li>
</ul>


<p>We provide lists of all countries ranked by each of the <a href="country_complexity_results.php">Complexity</a> and <a href="ips_per_points_of_control_results.php">IPs per Point of Control</a> metrics.</p>

<p>We intend the IPs per Points of Control metric as a measure of the relative ease of centrally controlling the Internet traffic within the country.  China, with 4 points of control and over 190 million IP addresses, has nearly 50 million IPs per point of control.  This means that China can operate a highly centralized control structure for its Internet, controlling an average of 50 million IP addresses at each of its core points of control, and indeed China has installed extensive <a href="http://opennet.net/research/profiles/china">filtering machinery</a> at these points of control.  <a href="country_detail.php/?cc=RU">Russia</a>, by contrast, has 36 points of control for only 20 million IP addresses, meaning that Russia is able to control less than a million IP addresses for each of those points of control, requiring a much more complex, distributed system of control.  And as expected, despite its otherwise authoritarian government, no evidence has been found of widespread Internet filtering by Russia.</p>

<p>A network that is strongly controlled at the center may nonetheless have a great deal of complexity at the edges.  This complexity may make it difficult to control who connects to the network and how, while still allowing for control of the centralized flow of data.  We intend the Complexity metric to measure the degree to which the network itself is complex, meaning that it has lots of connections between ASs and that most of its IPs are located near the edges rather than in or near the core.  <!-- We have found <a href="country_detail.php/?cc=MN">Mongolia</a> to be the most complex network per IP address because even though the traffic of 98% of its IP addresses flows through one core AS (Railcom), that core AS in itself has only 2% of the country's IP addresses, and the next ten ASs control less than 70% of the country's ASs altogether.  So Mongolia could easily filter its network by simply installing a filter in that one core AS, but controlling who can get onto the network requires that Mongolia control the policies of the more than 10 ASs that connect through the core AS. --> </p>

<p>There are a number of important limitations to both the data sets and analyses used for this project, explained in detail in the caveats section below.  The two most important caveats are that we do not include peer relationships in the metrics and that we assume that child ASs with more than one parent share their routes equally among all parents.</p>

<h1>Data</h1>

<p>We generate all of the maps and metrics on this site from four sources of data</p>
<ul>
<li><a href="http://www.caida.org/data/active/as-relationships/index.xml">CAIDA AS Relationships</a> - CAIDA's data set of inferred relationships (customer/provider, peer, or sibling) between ASs based on its distributed route tracing project.</li>
<li><a href="http://www.caida.org/data/active/as_taxonomy/">CAIDA AS Taxonomy</a> - CAIDA's data set of inferred AS types (big ISP, small ISP, IXP, etc) based on its distributed route tracing project.</li>
<li><a href="http://www.team-cymru.org/Services/ip-to-asn.html">Team Cymru IP-to-ASN Service</a> - Team Cymru's IP to ASN mapping service for AS name and country lookup.</li>
<li><a href="http://www.caida.org/data/routing/routeviews-prefix2as.xml">CAIDA Routeviews Prefix to AS Mappings</a> - CAIDA's aggregation of Route Views BGP data into IP block to AS mappings.</li>
</ul>

<h1>Methods</h1>

<p>To generate the individual country maps, we:</p>

<ul>
<li>Generate a list of all traced ASs in the CAIDA AS Relationships data set.</li>
<li>Look up the name and country of each AS using the Team Cymru service.</li>
<li>Look up the type of each AS using the CAIDA AS Taxonomy data set.</li>
<li>Divide the CAIDA AS Relationships data into countries using the Cymru country data.  For each country, reassign all foreign provider ASs to the single, virtual 'Rest of World' AS and drop all other foreign relationships.</li>
<li>Generate a network graph for each country's ASs and relationships using the <a href="http://flare.prefuse.org/">Flare</a> Visualization library.</li>
</ul>

<p>To generate the Connected IPs, we:</p>

<ul>
<li>Look up the number of allocated IP addresses for each ASN in the CAIDA Routeviews Prefix to AS Mappings data set.</li>
<li>Recursively traverse up the tree of ASs for the country, adding the number of IPs of each AS both to its own connected IPs count and to its parent's.  If an AS has more than one parent, add to each parent the connected IPs of the child divided by the number of parents. This is a gross estimation of multiple parent relationships -- see caveats below.</li>
</ul>

<p>To generate the Points of Control for each country, we use a simple greedy algorithm:</p>
<ul>
<li>Start with the AS with the most connected IP addresses as
a point of control.</li>
<li>Add up the connected IPs represented by all of the points of control ASs together, taking care to count children ASs appropriately (do not count ASs in the points of control list as children, and only include a proportional share of children ASs whose parents are not all in the points of control list).</li>
<li>Find the AS that would most increase the number
of connected IP addresses of the points of control.</li>
<li>Repeatedly add the AS that would most increase the connected IPs to the points of control ASs until the sum of the connected IPs of all points of control ASs 
is greater or equal to 90% of all IPs in the country.</li>
</ul>
</p>

<p>To generate the Complexity for each country, we:</p>

<ul>
<li>Use the equation ( C = AS * &sum;( CI(a) / I ) ) / I ) where
<ul>
    <li>C = Complexity</li>
    <li>AS = total number of ASs for country</li>
    <li>&sum; = sum for each AS in country</li>
    <li>CI(a) = connected IPs for AS</li>
    <li>I = total IPs in country</li>
</ul>
</li>

<li>Using this definition of complexity, a network is more complex if it:<ul>

<li>has more ASs per IP address,</li>
<li>has more connections per AS, and</li>
<li>has more of its IP addresses located away from the core of the network.</li>
</ul></li>
</ul>

<h1>Caveats</h1>

<p>There are a number of important limitations to this project:</p>

<ul>
<li>The numbers of IP addresses for each country refers to allocated rather than actively used addresses.  Even to the degree that the IP address numbers represent IP addresses used, many users now connect to the Internet through natural address translation, allowing many users per public IP address.  So the number of IP addresses is only a loose approximation of the number of Internet users.</li>

<li>The core CAIDA AS Relationships data set infers the list of ASs and relationships from data gathered from a large set of traceroutes run from a distributed set of servers.  This <a href="http://www.caida.org/publications/papers/2006/as_relationships_inference/">process of collection and inference</a> finds only 86.7% of customer-provider relationships on the Internet, so not all customer links nor all ASs are represented.</li>

<li>The CAIDA route data is particularly sparse for small countries, where missing a few ASs may drastically impact the mapping.  To avoid misleading results for under-sampled countries, we only include countries with observed ASs including a total of at least 25,000 IP addresses.  Accordingly, we omit the following countries: <?  echo join("; ", get_excluded_country_names()) ?>. We also eliminate the following regions: the African Regional Intellectual Property Organization and the European Union.</li>

<li>The AS Relationships data set only provides AS level relationships, which does not allow us to determine how traffic is routed among the many parents of a single child.  So for each child with multiple parents, we assign to each parent the connected IPs of the child divided by the number of parents.  Using more detailed, block level routing relationships would allow us to determine the real proportion of IP addresses routed to each parent.</li>

<li>The AS Relationships data set only finds 38.7% of peer-to-peer relationships.  Because of the lack of peer relationships in the data set, we ignore them completely for this analysis.  If most of the traffic we care about is served from within one of the ASs we categorize as points of control, or if most of the traffic is in the Rest of World for the country, then the peer relationships will not strongly affect the set of points of control (since the traffic will ultimately need to flow through the points of control in any case).  But whatever portion of traffic for the country is served by ASs near the edges of the network could potentially avoid the points of control by flowing through peer connections.  Likewise, a higher or lower proportion of peer connections than customer-provider connections within a country network could increase or lower the complexity of the country in relation to other countries. </li>

<li>We omit the United States because the U.S. has a large number of sparse Class A networks, vastly inflating the IP address numbers (1.2 billion addresses compared to 190 million for China, even though China and the U.S. have about the same number of Internet users).</li>

<li>We omit from the maps all customer -&gt; provider relationships from the rest of the world to an AS within a country in order to make the links out to the rest of the world (the black node in the maps) much clearer.</li>

</ul>

<h1>Paper</h1>

     <p> Hal Roberts and David Larochelle, <a href="mlic.pdf">Mapping Local Internet Control</a>, 2010.</p>
</p>
<? 
  include "./info_page_footer.php";

