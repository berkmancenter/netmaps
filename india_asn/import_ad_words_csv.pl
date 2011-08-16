#!/usr/bin/perl

use DBI;
use strict;
use Class::CSV;
use DBIx::Simple;
use Data::Dumper;
use Locale::Country qw(country2code);
use Perl6::Say;

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

    my $fields_old_format =    [         qw / site_name category composition_index audience_reach audience_unique_users country_unique_users country_page_views gcn_text gcn_images gcn_videos gcn_gadgets gcn_impressions_per_day / ];

    my $fields_new_format =  [qw / Publisher AdWords_Posting_URL site_name Type category Has_Advertising gcn_text gcn_images Audio gcn_videos Rich_Media Expandable composition_index audience_reach audience_unique_users country_unique_users country_page_views foo / ];

    #say STDERR Dumper( $fields_new_format );

    #say STDERR "Parsing file ";

    my $csv = Class::CSV->parse(
        filename => $filename,
        fields   => $fields_new_format
    );

    say STDERR "Parsed File $filename";

    #exit;

    my $country_name = lc($filename);
    $country_name =~ s/.*\///;

    $country_name =~ s/\sadplanner.csv//i;

    $country_name =~ s/-20110810.csv//i;
    $country_name =~ s/-20110811.csv//i;
    $country_name =~ s/-/ /gi;

    print "Country Name: '$country_name'\n";

    my $country_code = country2code($country_name);

    say "Country Code: $country_code";

    if ( ! $country_code )
    {
       say STDERR "Warning couldn't find the country code for $country_name\n";
    }

    shift @{ $csv->lines };

    for my $line ( @{ $csv->lines } )
    {

       # add 'fake' fields if necessary

       my $fake_fields = [ qw / gcn_gadgets gcn_impressions_per_day  / ];

       foreach my $fake_field ( @ { $fake_fields } )
       {
	  eval { $line->get( $fake_field ) };
	  if ( $@ )
	  {
              #say STDERR " Adding fake field: $fake_field";
	      $line->_build_fields( [ $fake_field ] );
	      $line->set( $fake_field => '');
	  }
       }

       my $site_name = $line->get( 'site_name' );

       $site_name =~ s/^domain: //;

       $line->set( 'site_name' => $site_name );

#print Dumper ($line->get(qw / site_name category composition_index audience_reach audience_unique_users country_unique_users country_page_views gcn_text gcn_images gcn_videos gcn_gadgets gcn_impressions_per_day/));

       #Purge ',' from fields.
       my $line_db_fields =       [   $line->get(
                qw / site_name category composition_index audience_reach audience_unique_users country_unique_users country_page_views gcn_text gcn_images gcn_videos gcn_gadgets gcn_impressions_per_day/
            ) ];
       $line_db_fields = [ map { $_ =~ s/,//g; $_; } @ { $line_db_fields } ];

       $dbh->query(
'insert into adwords_country_data ( country, country_code, site_name,  category, composition_index, audience_reach, audience_unique_users, country_unique_users, country_page_views, gcn_text,gcn_images,gcn_videos,gcn_gadgets, gcn_impressions_per_day) values (?, ?, ?, ?, ?,?, ?, ?,?, ?, ?, ?, ?, ? )',
            $country_name,
            $country_code,
            @{ $line_db_fields }
        );
    }
}

main();
