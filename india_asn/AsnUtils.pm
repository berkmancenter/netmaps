package AsnUtils;

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );
use Class::CSV;

my $_asn_country_cache = {};

sub get_asn_country_code
{
    my ($asn) = @_;

    defined($asn) || die;

    if ( !keys %{$_asn_country_cache} )
    {
        _read_asn_to_country_csv_file();
    }

    #     if ( !defined( $_asn_country_cache->{$asn} ) )
    #     {
    #         $_asn_country_cache->{$asn} = get_asn_country($asn);
    #     }

    return $_asn_country_cache->{$asn};
}

sub _read_asn_to_country_csv_file
{
    my $csv = Class::CSV->parse(
        filename => 'asn_to_country.csv',
        fields   => [qw /asn country_code/]
    );

    for my $line ( @{ $csv->lines } )
    {
        $_asn_country_cache->{ $line->asn } = $line->country_code;
    }
}

sub is_indian_asn
{
    my ($asn) = @_;

    defined($asn) || die;

    return get_asn_country_code($asn) eq "IN";
}
