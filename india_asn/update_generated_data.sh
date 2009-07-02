#!/bin/sh

DATA_DOWNLOAD_DIRECTORY=downloaded_data
GENERATED_DATA_DIRECTORY=generated_data
WEB_DIRECTORY=asn_web_graphs
DATABASE_DIRECTORY=db
mkdir -p $GENERATED_DATA_DIRECTORY
cat $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt | xargs cat | head -n 200 | ./generate_asn_to_country_list.pl  >  $GENERATED_DATA_DIRECTORY/asn_to_country.csv
cat $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt | xargs cat | head -n 200 | ./generate_asn_cymru_tsv.pl  >  $GENERATED_DATA_DIRECTORY/asn_info.tsv
mkdir -p $DATABASE_DIRECTORY
rm $DATABASE_DIRECTORY/as_info.db
sqlite3 $DATABASE_DIRECTORY/as_info.db < sql_scripts/as_info.sql
rm $DATABASE_DIRECTORY/asn_ip_counts.db
sqlite3 $DATABASE_DIRECTORY/asn_ip_counts.db < sql_scripts/asn_ip_counts.sql
./import_ip_prefixes_to_db.pl
rm $DATABASE_DIRECTORY/asn_taxonomy.db
sqlite3 $DATABASE_DIRECTORY/asn_taxonomy.db < sql_scripts/asn_taxonomy.sql