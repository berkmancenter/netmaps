#!/usr/bin/perl

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

my $_country_dns = {
    brazil           => '201.17.0.19',
    china            => '218.30.26.68',
    japan            => '165.76.0.243',
    germany          => '213.133.97.162',
    'united kingdom' => '193.200.98.45',
    france           => '62.39.164.12',
    'south korea'    => '96.17.107.113',
    italy            => '85.38.28.84',
    turkey           => '212.175.13.113',
    'iran'           => '217.218.155.105',
    indonesia        => '202.152.161.67',
    pakistan         => '203.135.0.70',
    mexico           => '201.144.5.42',
    russia           => '62.33.189.250',
    canada           => '205.150.58.80',
    australia        => '210.8.231.65',
    india            => '202.62.224.2',

    #Spain =>
    #Vietnam =>
};

#   my $_res = Net::DNS::Resolver->new(
#     nameservers =>             #[qw(140.247.233.200)], #harvard
#       [qw(  202.62.224.2)],    # india
#                                #[qw(  203.197.196.1 )], # india
#     recurse => 1,
#     debug   => 0,
#   );

sub get_ip_for_host
{
    ( my $host_name, my $res ) = @_;

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

    my $asn = ( get_asn_info($ip_address) )[0];

    #    print ("Host NAME $host_name -- $ip_address  $asn asn\n");
    my $packet = $res->query($host_name);

    if ( !$packet )
    {
        print "Warnng Country DNS did not give IP for $host_name\n";
        return;
    }

    die unless $packet->answer;

    my @asns_addrs = map { ( get_asn_info( $_->{address} ) )[0] } ( $packet->answer );

    if ( grep { $_ eq $asn } @asns_addrs )
    {

    }
    else
    {
        print "local ASN for $host_name is different than country specific \n;";
    }

    return;

    if ($packet)
    {
        $packet->print;
        print "\n" . Dumper( $packet->answer ) . "\n";
    }
}

sub main
{
    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    Readonly my $country_code_str => 'in';

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/ad_words.db", "", "", $dbargs ) );

    foreach my $country ( sort keys %{$_country_dns} )
    {
        print("Country: $country\n");

        my $country_code = country2code($country);

        die "error finding code for country: $country" unless defined($country_code);

        my $adwords_data =
          $dbh->query( "select * from adwords_country_data where country_code = ? order by audience_reach desc limit 150",
            $country_code );

        my $res = Net::DNS::Resolver->new(
            nameservers => [ $_country_dns->{$country} ],
            recurse     => 1,
            debug       => 0,
        );

        next if ( !$res );

        my @top_sites = map { $_->{site_name} } @{ $adwords_data->hashes() };

        push @top_sites, "google.com", "youtube.com";
        foreach my $site (@top_sites)
        {
            print "ProcessingSite: '$site'\n";
            get_ip_for_host( $site, $res );

            print "$site -- " . get_ip_for_host($site) . "\n";
        }
    }
}

main;
