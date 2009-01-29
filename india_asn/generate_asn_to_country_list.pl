#!/usr/bin/perl -w

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );
use Class::CSV;
use AsnUtils;

#USAGE: parses a CAIDA ASN relationship list file and generates a csv list with asn and country.
#Input: A CAIDIA ASN relationship file formated list
#Output: A CSV  listing ASN and Country code.  The CSV file is sent to STDOUT.  #        The header "asn,country" is NOT included in the output.  ASN's are listed as numeric integers values.  E.g. '102' not '102AS'

my $_asn_country_cache = {};

sub print_asn_country_map
{

    my @header = qw (asn country);

    my $csv = Class::CSV->new( fields => \@header );

    foreach my $asn ( sort { $a <=> $b } keys( %{$_asn_country_cache} ) )
    {
        $csv->add_line(
            {
                asn     => $asn,
                country => $_asn_country_cache->{$asn}
            }
        );
    }

    $csv->print;
}

sub look_up_asn_country
{
    my ($asn) = @_;

    defined($asn) || die;

    if ( !defined( $_asn_country_cache->{$asn} ) )
    {
        $_asn_country_cache->{$asn} = get_asn_country($asn);
    }
}

sub main
{
    my $trace_route_list;

    my $tr_list = [];
    my @tr_lists;

    my $prev_line = "";
    my $prev_dest = "";

    my $asns = {};

    while (<>)
    {
        if (/^#/)
        {
            next;

            #skip comment lines
        }

        my ( $asn1, $asn2, $relationship ) = split;

        die "defined value " unless defined($asn1) && defined($asn2) && defined($relationship);

        look_up_asn_country($asn1);
        look_up_asn_country($asn2);
    }

    print_asn_country_map();

}

main();
