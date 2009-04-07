package AsnIPCount;

use Class::CSV;
use DBIx::Simple;
use DBI;
use Readonly;
use strict;

Readonly my $ip_to_asn_csv_file => '/home/dlarochelle/Desktop/GeoIPASNum2.csv';
Readonly my $ip_prefix_to_asn_tsv_file => '/home/dlarochelle/Desktop/routeviews-rv2-20090302-1132.pfx2as';

my $_asn_count = [];

sub _read_asn_to_ip_file
{
    print "reading asn to ip file\n";
    my $csv = Class::CSV->parse(
        filename => $ip_to_asn_csv_file,
        fields   => [qw /ip_block_start ip_block_end asn /],
        csv_xs_options  =>  {  binary => 1}
    );

    for my $line ( @{ $csv->lines } )
    {
        my $num_ips = ($line->ip_block_end - $line->ip_block_start) + 1;
        $line->asn =~ /AS(\d+)/;
        my $asn_int = $1;
        die unless defined ($asn_int);
        
        $_asn_count->[ $asn_int ] ||= 0;
        $_asn_count->[ $asn_int ] += $num_ips;

    }
}

sub _read_ip_prefix_to_asn_file
{
    print "reading ip _prefix  file\n";
    my $csv = Class::CSV->parse(
        filename => $ip_prefix_to_asn_tsv_file,
        fields   => [qw /ip ip_prefix_length asn /],
        csv_xs_options  =>  {  binary => 1, sep_char => "\t" }
    );

    for my $line ( @{ $csv->lines } )
    {
        my $num_ips = 2 ** (32 - $line->ip_prefix_length);

        my @asns      = split("_", $line->asn);

        @asns      = map {split(",", $_) } @asns;

        foreach my $asn (@asns)
        {
            $_asn_count->[ $asn ] ||= 0;
            $_asn_count->[ $asn ] += $num_ips;
        }
    }
}

sub get_asn_counts_from_ip_prefix_file
{
    _read_ip_prefix_to_asn_file();

    return $_asn_count;
}

my $_ip_count_dbh;

sub get_ip_address_count_for_asn
{
    my ($asn) = @_;

    if (!defined ($_ip_count_dbh) )
    {
        my $dbargs = {
                      AutoCommit => 1,
                      RaiseError => 1,
                      PrintError => 1,
                     };
        
        $_ip_count_dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=asn_count.db", "", "", $dbargs ) );
    }

    if (!defined($_asn_count->[$asn] ) )
    {
        my $ip_count = $_ip_count_dbh->query("select ip_count from  asn_ip_counts where asn=?", $asn)->flat->[0];
        
        $_asn_count->[$asn] = $ip_count;
    }

    return $_asn_count->[$asn];
}

sub test
{
    _read_asn_to_ip_file();

    for (my $asn_number = 0; $asn_number < scalar(@{$_asn_count}); $asn_number++)
    {
        my $asn_count = $_asn_count->[$asn_number];
        if (defined($asn_count) )
        {
            print "AS$asn_number  ==> $asn_count\n";
        }
    }
}

1;
