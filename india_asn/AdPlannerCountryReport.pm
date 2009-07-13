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

sub get_ip_for_host
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

    print " -- Asn : $asn Country $cc -- ";

}

sub get_redirected_url
{
    ( my $site, my $country_code ) = @_;

    #TODO implement

    return $site;
}

sub is_url_hosted_in_country
{
    my ( $url_in_country, $country_code ) = @_;

    #print " Country_code = $country_code \n";

    my $host_ip = get_ip_for_host($url_in_country);

    my $host_country_code = ( get_asn_info($host_ip) )[2];

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

sub process_country_ad_words_sites
{

    ( my $country_code ) = @_;

    $country_code = lc $country_code;

    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/ad_words.db", "", "", $dbargs ) );

    my $adwords_data =
      $dbh->query( "select * from adwords_country_data where country_code = ? order by audience_reach desc ", $country_code )
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

    my $ret = {};

    $ret->{top_site_count}        = $top_site_count;
    $ret->{top_sites_in_country}  = $top_sites_in_country;
    $ret->{page_views_in_country} = $page_views_in_country;
    $ret->{total_page_views}      = $total_page_views;
    $ret->{country_code}          = $country_code;

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
    ( my $country_code ) = @_;

    my $ad_words_info = process_country_ad_words_sites($country_code);

    my $xml_graph = XML::LibXML::Element->new('ad_words_summary');

    if ($ad_words_info)
    {
        $xml_graph->appendTextChild( 'top_site_count',        $ad_words_info->{top_site_count} );
        $xml_graph->appendTextChild( 'top_sites_in_country',  $ad_words_info->{top_sites_in_country} );
        $xml_graph->appendTextChild( 'page_views_in_country', $ad_words_info->{page_views_in_country} );
        $xml_graph->appendTextChild( 'total_page_views',      $ad_words_info->{total_page_views} );
        $xml_graph->appendTextChild( 'country_code',          $ad_words_info->{country_code} );
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
