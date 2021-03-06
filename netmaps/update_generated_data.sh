#!/bin/bash

set -u
set -o  errexit

DATA_DOWNLOAD_DIRECTORY=downloaded_data
GENERATED_DATA_DIRECTORY=generated_data
WEB_DIRECTORY=asn_web_graphs
DATABASE_DIRECTORY=db
mkdir -p $GENERATED_DATA_DIRECTORY
rm -rf $GENERATED_DATA_DIRECTORY/*
mkdir -p $GENERATED_DATA_DIRECTORY

#Verify that the files exist
cat $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt > /dev/null
cat $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt | xargs cat > /dev/null

cat $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt | xargs cat  | ./generate_asn_to_country_list.pl  >  $GENERATED_DATA_DIRECTORY/asn_to_country.csv

cat $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt | xargs cat | ./generate_asn_cymru_tsv.pl  >  $GENERATED_DATA_DIRECTORY/asn_info.tsv
rm -rf  $DATABASE_DIRECTORY
mkdir -p $DATABASE_DIRECTORY
rm -f $DATABASE_DIRECTORY/as_info.db
sqlite3 $DATABASE_DIRECTORY/as_info.db < sql_scripts/as_info.sql
rm -f $DATABASE_DIRECTORY/asn_ip_counts.db
sqlite3 $DATABASE_DIRECTORY/asn_ip_counts.db < sql_scripts/asn_ip_counts.sql
./import_ip_prefixes_to_db.pl
rm -f $DATABASE_DIRECTORY/asn_taxonomy.db
sqlite3 $DATABASE_DIRECTORY/asn_taxonomy.db < sql_scripts/asn_taxonomy.sql
rm -f     $DATABASE_DIRECTORY/ad_words.db
sqlite3 $DATABASE_DIRECTORY/ad_words.db < sql_scripts/ad_words_schema.sql 
./import_ad_planner_data_into_sqlite.sh
