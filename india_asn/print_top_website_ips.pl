#!/usr/bin/perl

use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Readonly;
use Socket;

sub get_ip_for_host {
    my $packed_ip = gethostbyname("www.perl.org");
    
    if (defined $packed_ip) {
        my $ip_address = inet_ntoa($packed_ip);
        return $ip_address;
    }
    else
    {
        die;
    }

    

}
sub main
{
    my $dbargs = {
        AutoCommit => 1,RaiseError => 1,
        PrintError => 1,
    };

    Readonly my $country_code_str => 'in';

    my $dbh = DBIx::Simple->connect(DBI->connect( "dbi:SQLite:dbname=ad_words.db", "", "", $dbargs ));


    my $adwords_data = $dbh->query("select * from adwords_country_data where country_code = ? order by audience_reach desc limit 10", $country_code_str);

    foreach my $line ($adwords_data->hashes() )
    {
        my $site = $line->{site_name};

        print "$site -- " . get_ip_for_host($site) . "\n";
    }

}


main;
