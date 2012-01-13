package AdPlannerCountryReport;

use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Readonly;
use Socket;
use Net::DNS;
use Net::Abuse::Utils qw( get_asn_info );
use Locale::Country;
use List::Util qw (sum);
use List::MoreUtils qw(uniq any);

my $_host_name_for_ip = {};

sub get_ip_for_host
{
    ( my $host_name ) = @_;

    if ( !defined( $_host_name_for_ip->{$host_name} ) )
    {
        print "Did not find host $host_name in cache\n";
        $_host_name_for_ip->{$host_name} = get_ip_for_host_impl($host_name);
    }
    else
    {
        print "Found host $host_name in cache\n";
    }

    return $_host_name_for_ip->{$host_name};
}

sub get_ip_for_host_impl
{
    ( my $host_name ) = @_;

    my $packed_ip = gethostbyname($host_name);

    if ( !defined $packed_ip )
    {
        $host_name = 'www.' . $host_name;
        $packed_ip = gethostbyname($host_name);
        if ( !defined $packed_ip )
        {
            print "couldn't get ip address for $host_name\n";
            return;
        }
    }

    my $ip_address = inet_ntoa($packed_ip);

    return $ip_address;

    my $asn = ( get_asn_info($ip_address) )[0];

    my $cc = ( get_asn_info($ip_address) )[2];
}

sub get_redirected_url
{
    ( my $site, my $country_code ) = @_;

    #TODO implement

    return $site;
}

my $_asn_for_ip = {};

sub get_asn_for_ip
{
    ( my $ip ) = @_;

    return if ( !$ip );

    if ( !defined( $_asn_for_ip->{$ip} ) )
    {
        print "Did not find ip $ip in cache\n";
        $_asn_for_ip->{$ip} = ( get_asn_info($ip) )[0];
    }
    else
    {
        print "Found ip $ip in cache\n";
    }

    return $_asn_for_ip->{$ip};
}

my $_country_for_ip = {};

sub get_country_code_for_ip
{
    ( my $ip ) = @_;

    return if ( !$ip );

    my $asn = get_asn_for_ip($ip);

    return if ( !$asn );

    return AsnUtils::get_asn_country_code($asn);
}

sub is_url_hosted_in_country
{
    my ( $url_in_country, $country_code ) = @_;

    #print " Country_code = $country_code \n";

    my $host_ip = get_ip_for_host($url_in_country);

    my $host_country_code = get_country_code_for_ip($host_ip);

    my $foo = $country_code eq $host_country_code;

    #print "$country_code ==  $host_country_code \n:' $foo \n";
    return lc($country_code) eq lc($host_country_code);
}

sub hosted_in_country
{
    ( my $site, my $country_code ) = @_;

    my $url_in_country = get_redirected_url( $site, $country_code );

    return is_url_hosted_in_country( $url_in_country, $country_code );
}

sub _list_contains
{
    ( my $value, my $list ) = @_;

    return any { $_ eq $value } @{$list};
}

sub process_country_ad_words_sites
{

    ( my $country_code, my $point_of_control_list ) = @_;

    $country_code = lc $country_code;

    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/ad_words.db", "", "", $dbargs ) );

    my $adwords_data =
      $dbh->query( "select * from adwords_country_data where country_code = ? order by country_page_views desc ", $country_code )
      ->hashes;

    return unless scalar( @{$adwords_data} );

    #store hash and summ total page views.

    my @page_views_list_temp = map { $_->{country_page_views} } @{$adwords_data};
    my $total_page_views = sum @page_views_list_temp;

    my $top_site_count = scalar( @{$adwords_data} );

    # push @top_sites, "google.com", "youtube.com";

    my $top_sites_in_country = 0;

    my $page_views_in_country = 0;
    foreach my $site_hash (@$adwords_data)
    {
        my $site = $site_hash->{site_name};

        #print "ProcessingSite: '$site'\n";

        $site_hash->{ip}           = get_ip_for_host($site);
        $site_hash->{asn}          = get_asn_for_ip( $site_hash->{ip} );
        $site_hash->{country_code} = get_country_code_for_ip( $site_hash->{ip} );

        if ( hosted_in_country( $site, $country_code ) )
        {

            #print "Site is hosted in country\n";
            $top_sites_in_country++;
            $page_views_in_country += $site_hash->{country_page_views};
        }
        else
        {

            #print "Site is NOT hosted in country\n";
        }

        #print "$site -- " . get_ip_for_host($site) . "\n";
    }

    #print Dumper ( grep {$_->{country_code} } @{$adwords_data} );

    #exit;

    my $ret = {};

    print Dumper($point_of_control_list);

    #exclude sites where we can't determine the country
    my $valid_sites      = [ grep { defined( $_->{country_code} ) } @{$adwords_data} ];
    my $in_country_sites = [ grep { lc( $_->{country_code} ) eq lc($country_code) } @{$valid_sites} ];
    my $poc_hosted_sites = [ grep { _list_contains( $_->{asn}, $point_of_control_list ) } @{$in_country_sites} ];

    $ret->{top_site_count}        = scalar( @{$valid_sites} );
    $ret->{top_sites_in_country}  = scalar( @{$in_country_sites} );
    $ret->{top_sites_in_poc}      = scalar( @{$poc_hosted_sites} );

    $ret->{invalid_site_count}    = scalar( @{$adwords_data} ) - scalar ( @ { $valid_sites} );
    $ret->{all_sites}             = $adwords_data;

    $ret->{page_views_in_country} = sum map { $_->{country_page_views} } @{$in_country_sites};
    $ret->{page_views_in_poc}     = sum map { $_->{country_page_views} } @{$poc_hosted_sites};
    $ret->{total_page_views}      = sum map { $_->{country_page_views} } @{$valid_sites};
    $ret->{country_code}          = $country_code;

    #print Dumper ($ret);

    #exit;

    #     print $ret->{top_sites_in_country} . " / "
    #       . $ret->{top_site_count}
    #       . " are in country ( "
    #       . $ret->{top_sites_in_country} / $ret->{top_site_count} * 100.0 . " %)\n";

    #     print $ret->{page_views_in_country} . " / "
    #       . $ret->{total_page_views}
    #       . " are in country ( "
    #       . $ret->{page_views_in_country} / $ret->{total_page_views} * 100.0 . " %)\n";

    return $ret;
}

sub country_ad_words_xml_summary
{
    ( my $country_code, my $point_of_control_list ) = @_;

    my $ad_words_info = process_country_ad_words_sites( $country_code, $point_of_control_list );

    my $xml_graph = XML::LibXML::Element->new('ad_words_summary');

    if ($ad_words_info)
    {
        $xml_graph->appendTextChild( 'top_site_count',        $ad_words_info->{top_site_count} );
        $xml_graph->appendTextChild( 'top_sites_in_country',  $ad_words_info->{top_sites_in_country} );
        $xml_graph->appendTextChild( 'top_sites_in_poc',      $ad_words_info->{top_sites_in_poc} );

	$xml_graph->appendTextChild( 'invalid_site_count',    $ad_words_info->{ invalid_site_count} );

        $xml_graph->appendTextChild( 'page_views_in_country', $ad_words_info->{page_views_in_country} );
        $xml_graph->appendTextChild( 'page_views_in_poc',     $ad_words_info->{page_views_in_poc} );
        $xml_graph->appendTextChild( 'total_page_views',      $ad_words_info->{total_page_views} );
        $xml_graph->appendTextChild( 'country_code',          $ad_words_info->{country_code} );

	my $sites = XML::LibXML::Element->new( 'sites' );
	
	foreach my $site ( @ { $ad_words_info->{ all_sites } } )
	{
	     my $site_xml = XML::LibXML::Element->new( 'site' );
	     foreach my $key ( sort keys % { $site } )
	     {
	         $site_xml->appendTextChild( $key, $site->{ $key } );
	     }
	     
	     $sites->appendChild( $site_xml );
	}

	$xml_graph->appendChild( $sites );
    }

    return $xml_graph;
}

sub test_driver_main
{
    Readonly my $country_code_str => 'in';

    my @country_codes = ('in');

    foreach my $country_code ( sort @country_codes )
    {
        process_country_ad_words_sites($country_code);
    }
}

1;
