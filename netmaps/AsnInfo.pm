package AsnInfo;

use Class::CSV;
use DBIx::Simple;
use DBI;
use Readonly;
use strict;

my $_as_info_dbh;
my $_asn_info_cache;

sub _create_db_handle_if_necessary
{
    if ( !defined($_as_info_dbh) )
    {
        my $dbargs = {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 1,
        };

        $_as_info_dbh = DBIx::Simple->connect( DBI->connect( "dbi:SQLite:dbname=db/as_info.db", "", "", $dbargs ) );
    }
}

sub get_asn_organization_description
{
    my ($asn) = @_;

    _create_db_handle_if_necessary();

    my $org_description =
      $_as_info_dbh->query( "select organization_description from  as_info where asn=?", $asn )->flat->[0];

    return $org_description;
}

1;
