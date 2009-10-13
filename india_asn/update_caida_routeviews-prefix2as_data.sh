#!/bin/bash

#This data seems to be updated daily but there is a possible issue with running this on the first of the month as the CAIDA data may be a few hours behind.

source set_common_script_variables.sh

CAIDA_ROUTEVIEWS_SERVER=data.caida.org
CAIDA_DATA_ROUTEVIEWS_DIRECTORY_BASE=datasets/routing/routeviews-prefix2as
YEAR=`date +%Y`
MONTH=`date +%m`
CAIDA_DATA_ROUTEVIEWS_DIRECTORY=$CAIDA_DATA_ROUTEVIEWS_DIRECTORY_BASE/$YEAR/$MONTH
CAIDA_DATA_ROUTEVIEWS_DIRECTORY_URL=http://$CAIDA_ROUTEVIEWS_SERVER/$CAIDA_DATA_ROUTEVIEWS_DIRECTORY
echo $CAIDA_DATA_ROUTEVIEWS_DIRECTORY_URL

wget -P $DATA_DOWNLOAD_DIRECTORY --debug --no-parent -N  -A *.gz,*.html -r -l 2 --include-directories=$CAIDA_DATA_ROUTEVIEWS_DIRECTORY $CAIDA_DATA_ROUTEVIEWS_DIRECTORY_URL 
find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_ROUTEVIEWS_SERVER -iname 'routeviews-rv2*.pfx2as.*gz' -print0 | xargs -0 ls -tdr | tail -n 1 > $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file_name.txt
ln -sf `pwd`/`cat  $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file_name.txt` $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file.txt