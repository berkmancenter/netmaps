#!/usr/bin/perl -w

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );
use Class::CSV;
use AsnUtils;
use Data::Dumper;

#USAGE: parses a CAIDA ASN relationship list file and generates a csv list with asn and country.
#Input: A CAIDIA ASN relationship file formated list
#Output: A CSV  listing ASN and Country code.  The CSV file is sent to STDOUT.  #        The header "asn,country" is NOT included in the output.  ASN's are listed as numeric integers values.  E.g. '102' not '102AS'

my $_asn_info_cache = {};

sub print_asn_country_map
{

    my @header = qw (asn country registry allocated as_name);

    my $csv = Class::CSV->new( fields => \@header, csv_xs_options => { binary => 1, sep_char => "\t" } );

    foreach my $asn ( sort { $a <=> $b } keys( %{$_asn_info_cache} ) )
    {
        my $asn_info = $_asn_info_cache->{$asn};

        warn Dumper($asn_info) unless ( !defined( $asn_info->{as} ) || ( $asn == $asn_info->{as} ) );

        if ( $asn_info->{as} != $asn )
        {
            print STDERR "No info for AS$asn\n";
        }

        #print Dumper($asn_info);

        $csv->add_line(
            {
                asn       => $asn,
                country   => $asn_info->{cc},
                registry  => $asn_info->{registry},
                allocated => $asn_info->{allocated},
                as_name   => $asn_info->{name},
            }
        );
    }

    $csv->print;
}

sub _look_up_asn_info
{
    my ($asn) = @_;

    defined($asn) || die;

    if ( !defined( $_asn_info_cache->{$asn} ) )
    {
        $_asn_info_cache->{$asn} = AsnUtils::get_asn_dig_info($asn);
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

    my $counter = 0;

    while (<>)
    {
        if (/^#/)
        {
            next;

            #skip comment lines
        }

        my ( $asn1, $asn2, $relationship ) = split;

        die "defined value " unless defined($asn1) && defined($asn2) && defined($relationship);

        _look_up_asn_info($asn1);
        _look_up_asn_info($asn2);

        $counter++;
        if ( $counter % 300 == 0 )
        {
            print STDERR "processed $counter records\n";
        }
    }

    print_asn_country_map();

}

main();
