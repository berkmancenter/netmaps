create table as_taxonomy (
 asn      integer primary key,
 organization_description  text,
 num_inferred_providers   integer NOT NULL,
 num_inferred_peers   integer NOT NULL,
 num_inferred_customers  integer NOT NULL,
 slash_24_eqivalent_prefixes integer NOT NULL,
 advertised_ip_prefixes integer NOT NULL,
 inferred_as_class   char(10)
);

.separator \t
.import downloaded_data/as2attr.txt as_taxonomy

CREATE UNIQUE INDEX asn_index ON as_taxonomy (asn);