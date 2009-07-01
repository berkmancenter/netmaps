package AsnUtils;

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );
use Class::CSV;
use Data::Dumper;

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

sub get_asn_whois_info
{
    my ($asn) = @_;

    $asn = lc($asn);

    if ( $asn !~ /^as/ )
    {
        $asn = "as$asn";
    }

    #print Dumper($asn);

    my @whois = ` whois -h whois.cymru.com " -v $asn"`;

    #print Dumper(@whois);
    chomp( $whois[1] );

    my @whois_results = split( /\s*\|\s*/, $whois[1] );

    my %ret;
    @ret{ 'as', 'cc', 'registry', 'allocated', 'name' } = @whois_results;

    #print Dumper( \ %ret);
    return \%ret;
}

sub get_asn_dig_info
{
    my ($asn) = @_;

    $asn = lc($asn);

    if ( $asn !~ /^as/ )
    {
        $asn = "AS$asn";
    }

    #print Dumper($asn);

    my %ret;

    while (1)
    {
        my @whois = `dig +short $asn.asn.cymru.com TXT`;

        #print Dumper(@whois);
        chomp( $whois[0] );

        my $dig_response = $whois[0];

        $dig_response =~ s/^"(.*)"$/$1/;

        my @whois_results = split( /\s*\|\s*/, $dig_response );

        @ret{ 'as', 'cc', 'registry', 'allocated', 'name' } = @whois_results;

        last unless ( ( defined( $ret{as} ) ) && ( $ret{as} =~ /.*timed out.*/ ) );
        print STDERR "retrying query for $asn\n";
    }

    #print Dumper( \ %ret);
    return \%ret;
}

sub _read_asn_to_country_csv_file
{
    print STDERR "Reading asn_to_country.csv\n";
    my $csv = Class::CSV->parse(
        filename => 'asn_to_country.csv',
        fields   => [qw /asn country_code/]
    );

    for my $line ( @{ $csv->lines } )
    {
        $_asn_country_cache->{ $line->asn } = $line->country_code;
    }
    print STDERR "Done reading asn_to_country.csv\n";
}

sub is_indian_asn
{
    my ($asn) = @_;

    defined($asn) || die;

    return get_asn_country_code($asn) eq "IN";
}

1;
