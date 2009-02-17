#!/usr/bin/perl -w

use strict;
use List::MoreUtils qw(uniq);
use AsnUtils;

my $_asn_country_cache = {};

#USAGE:
#input: CAIDA asn file format relationship list 
#
#output: Identical to the inputed asn relationship list except that lines in which neither ASN is Indian are prefixed with the string "Not indian".  (Lines beginning with '#' are not altered.
#
# Example:
#
# To obtain an ASN list in which at least one ASN in every pair is indian:
#
#    cat as-rel.20080818.a0.01000.txt  | ./mark_non_indian_asn_pairs.pl | grep -v "Not indian"  > as-rel-indian.txt
#

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

        if ( AsnUtils::is_indian_asn($asn2) || AsnUtils::is_indian_asn($asn1) )
        {
            print;
        }
        else
        {
            print "Not indian";
            print;
        }
    }

}

main();
