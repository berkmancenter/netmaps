#!/usr/bin/perl

use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Locale::Country qw(country2code);
#use AsnIPCount;

my $_asn_count = [];

sub _read_ip_prefix_to_asn_file
{
    my ($ip_prefix_to_asn_file) = @_;
    print "reading ip _prefix  file\n";
    my $csv = Class::CSV->parse(
        filename       => $ip_prefix_to_asn_file,
        fields         => [qw /ip ip_prefix_length asn /],
        csv_xs_options => { binary => 1, sep_char => "\t" }
    );

    for my $line ( @{ $csv->lines } )
    {
        my $num_ips = 2**( 32 - $line->ip_prefix_length );

        my @asns = split( "_", $line->asn );

        @asns = map { split( ",", $_ ) } @asns;

        foreach my $asn (@asns)
        {
            $_asn_count->[$asn] ||= 0;
            $_asn_count->[$asn] += $num_ips;
        }
    }
}

sub get_asn_counts_from_ip_prefix_file
{
    my ($ip_prefix_to_asn_file) = @_;
    _read_ip_prefix_to_asn_file($ip_prefix_to_asn_file);

    return $_asn_count;
}


sub main
{
    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    my $asn_counts = get_asn_counts_from_ip_prefix_file('/home/dlarochelle/Desktop/routeviews-rv2-20090302-1132.pfx2as');

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/asn_ip_counts.db", "", "", $dbargs ) );

    for ( my $i = 0 ; $i < scalar( @{$asn_counts} ) ; $i++ )
    {
        next if ( !defined( $asn_counts->[$i] ) );
        $dbh->query( 'insert into asn_ip_counts (asn, ip_count) values (?, ? ) ', $i, $asn_counts->[$i] );
    }

    $dbh->commit();
    $dbh->disconnect();

}

main();
