#!/usr/bin/perl

use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Locale::Country qw(country2code);
use AsnIPCount;

sub main
{
    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    my $asn_counts = AsnIPCount::get_asn_counts_from_ip_prefix_file();

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=asn_count.db", "", "", $dbargs ) );

    for ( my $i = 0 ; $i < scalar( @{$asn_counts} ) ; $i++ )
    {
        next if ( !defined( $asn_counts->[$i] ) );
        $dbh->query( 'insert into asn_ip_counts (asn, ip_count) values (?, ? ) ', $i, $asn_counts->[$i] );
    }

    $dbh->commit();
    $dbh->disconnect();

}

main();
