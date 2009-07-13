#!/usr/bin/perl

use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Locale::Country qw(country2code);

sub main
{
    my $dbargs = {
        AutoCommit => 1,
        RaiseError => 1,
        PrintError => 1,
    };

    my $dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/ad_words.db", "", "", $dbargs ) );

    foreach my $file (@ARGV)
    {
        print "File: '$file'\n";
        parse_file( $dbh, $file );
    }

    $dbh->commit();
    $dbh->disconnect();

}

sub parse_file
{

    ( my $dbh, my $filename ) = @_;

    #    $dbh->do("insert into query (query_id, query_name,query_date) values (1,'stuff','2006-11-06')");

    my $csv = Class::CSV->parse(
        filename => $filename,
        fields   => [
            qw / site_name category composition_index audience_reach audience_unique_users country_unique_users country_page_views gcn_text gcn_images gcn_videos gcn_gadgets gcn_impressions_per_day /
        ]
    );

    my $country_name = lc($filename);
    $country_name =~ s/.*\///;

    $country_name =~ s/\sadplanner.csv//i;

    print "Country Name: '$country_name'\n";

    my $country_code = country2code($country_name);

    shift @{ $csv->lines };

    for my $line ( @{ $csv->lines } )
    {

#print Dumper ($line->get(qw / site_name category composition_index audience_reach audience_unique_users country_unique_users country_page_views gcn_text gcn_images gcn_videos gcn_gadgets gcn_impressions_per_day/));

        $dbh->query(
'insert into adwords_country_data ( country, country_code, site_name,  category, composition_index, audience_reach, audience_unique_users, country_unique_users, country_page_views, gcn_text,gcn_images,gcn_videos,gcn_gadgets, gcn_impressions_per_day) values (?, ?, ?, ?, ?,?, ?, ?,?, ?, ?, ?, ?, ? )',
            $country_name,
            $country_code,
            $line->get(
                qw / site_name category composition_index audience_reach audience_unique_users country_unique_users country_page_views gcn_text gcn_images gcn_videos gcn_gadgets gcn_impressions_per_day/
            )
        );
    }
}

main();
