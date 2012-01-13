create table as_info (
 asn      integer primary key,
 country  char(2),
 registry  text,
 allocated  text,
 organization_description  text
);

.separator "\t"
.import generated_data/asn_info.tsv as_info
update as_info set organization_description = trim(organization_description, '"');
update as_info set registry = trim(registry, '"');
update as_info set country = trim(country, '"');

CREATE UNIQUE INDEX asn_index ON as_info (asn);