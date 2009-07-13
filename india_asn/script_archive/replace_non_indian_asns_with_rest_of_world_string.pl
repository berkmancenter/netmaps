#!/usr/bin/perl -w

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );

my $_asn_country_cache = {};

#USAGE: This is a simple perl which takes a CAIDA AS Number relationship file as input and outputs a list in which non-Indian ASN's are replaced with the string 'REST_OF_WORLD'.  Lines beginning with '#' are not altered.

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
            print;
            next;

            #skip comment lines
        }

        my ( $asn1, $asn2, $relationship ) = split;

        die "defined value " unless defined($asn1) && defined($asn2) && defined($relationship);

        if ( !AsnUtils::is_indian_asn($asn1) )
        {
            $asn1 = "REST_OF_WORLD";
        }
        if ( !AsnUtils::is_indian_asn($asn2) )
        {
            $asn2 = "REST_OF_WORLD";
        }

        print "$asn1 $asn2 $relationship\n";
    }

}

main();
