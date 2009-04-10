package AsnTaxonomyClass;

use Class::CSV;
use DBIx::Simple;
use DBI;
use Readonly;
use strict;

my $_as_taxonomy_dbh;
my $_asn_taxonomy_cache;

sub get_asn_taxonomy_class
{
    my ($asn) = @_;

    if (!defined ($_as_taxonomy_dbh) )
    {
        my $dbargs = {
                      AutoCommit => 1,
                      RaiseError => 1,
                      PrintError => 1,
                     };
        
        $_as_taxonomy_dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=asn_taxonomy.db", "", "", $dbargs ) );
    }

    if (!defined($_asn_taxonomy_cache->[$asn] ) )
    {
        my $ip_count = $_as_taxonomy_dbh->query("select inferred_as_class from  as_taxonomy where asn=?", $asn)->flat->[0];
        
        $_asn_taxonomy_cache->[$asn] = $ip_count;
    }

    return $_asn_taxonomy_cache->[$asn];
}


1;
