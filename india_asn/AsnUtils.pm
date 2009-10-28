package AsnUtils;

use strict;
use List::MoreUtils qw(uniq);
use Net::Abuse::Utils qw( :all );
use Class::CSV;
use Data::Dumper;
use Perl6::Say;

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
        my $resolver =  Net::DNS::Resolver->new;
        my $packet   = $resolver->query("$asn.asn.cymru.com", "TXT");

        if (!defined($packet) ) {
            print STDERR "Asn lookup failed for $asn\n";
            last;
        }

        my @answer = $packet->answer;

        my $answer = $answer[0];

        die unless $answer->type eq 'TXT';

        #say STDERR $packet->string;
        #say STDERR $answer->txtdata;

        my @whois_results = split( /\s*\|\s*/, $answer->txtdata );


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
        filename => 'generated_data/asn_to_country.csv',
        fields   => [qw /asn country_code/]
    ) || die;

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
