package AsnTaxonomyClass;

use Class::CSV;
use DBIx::Simple;
use DBI;
use Readonly;
use strict;

my $_as_taxonomy_dbh;
my $_asn_taxonomy_cache;

sub _create_db_handle_if_necessary
{
    if ( !defined($_as_taxonomy_dbh) )
    {
        my $dbargs = {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 1,
        };

        $_as_taxonomy_dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=asn_taxonomy.db", "", "", $dbargs ) );
    }
}

sub get_asn_taxonomy_class
{
    my ($asn) = @_;

    _create_db_handle_if_necessary();

    return if ( $asn eq "REST_OF_WORLD" );

    if ( !defined( $_asn_taxonomy_cache->[$asn] ) )
    {
        my $ip_count = $_as_taxonomy_dbh->query( "select inferred_as_class from  as_taxonomy where asn=?", $asn )->flat->[0];

        $_asn_taxonomy_cache->[$asn] = $ip_count;
    }

    return $_asn_taxonomy_cache->[$asn];
}

sub get_asn_organization_description
{
    my ($asn) = @_;

    _create_db_handle_if_necessary();

    my $org_description =
      $_as_taxonomy_dbh->query( "select organization_description from  as_taxonomy where asn=?", $asn )->flat->[0];

    return $org_description;
}

1;
