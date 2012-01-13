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

#TODO figure out a better way to prevent the warning...
sub get_asn_country_wrapper
{
    my $asn = shift;
    my $rr = Net::Abuse::Utils::_return_rr( "AS${asn}.asn.cymru.com", 'TXT' );

    return if ( !$rr );
    my $as_cc = ( split( /\|/, $rr ) )[1];
    if ($as_cc)
    {
        return Net::Abuse::Utils::_strip_whitespace($as_cc);
    }
    return;
}

sub look_up_asn_country
{
    my ($asn) = @_;

    defined($asn) || die;

    if ( !defined( $_asn_country_cache->{$asn} ) )
    {
        my $asn_country;
        {
            $asn_country = get_asn_country_wrapper($asn);
        }

        $_asn_country_cache->{$asn} = $asn_country;
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

    my $line_num = 0;
    
    while (<>)
    {
	$line_num++;
        if (/^#/)
        {
            next;

            #skip comment lines
        }

	chomp;
	my $line = $_;

        my ( $asn1, $asn2, $relationship ) = split '\|';

        die "defined value " unless defined($asn1) && defined($asn2) && defined($relationship);

	die "Line '$line': Not number '$asn1'" unless $asn1 =~ /^\d*$/;
	die "Line '$line': Not number '$asn2'" unless $asn2 =~ /^\d*$/;

        look_up_asn_country($asn1);
        look_up_asn_country($asn2);
    }

    print_asn_country_map();

}

main();
