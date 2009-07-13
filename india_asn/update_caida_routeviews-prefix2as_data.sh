#!/bin/sh

CAIDA_SERVER=data.caida.org
CAIDA_DATA_DIRECTORY=datasets/routing/routeviews-prefix2as/2009/06
CAIDA_DATA_DIRECTORY_URL=http://$CAIDA_SERVER/$CAIDA_DATA_DIRECTORY
echo $CAIDA_DATA_DIRECTORY
DATA_DOWNLOAD_DIRECTORY=downloaded_data
WEB_DIRECTORY=asn_web_graphs
wget -P $DATA_DOWNLOAD_DIRECTORY --debug  -N  -A *.gz,*.html -r -l 2 $CAIDA_DATA_DIRECTORY_URL --exclude-directories=$CAIDA_DATA_DIRECTORY/1,$CAIDA_DATA_DIRECTORY/2,$CAIDA_DATA_DIRECTORY/3,$CAIDA_DATA_DIRECTORY/4,$CAIDA_DATA_DIRECTORY/5
find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_SERVER -iname 'routeviews-rv2*.pfx2as.*gz' -print0 | xargs -0 ls -tdr | tail -n 1 > $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file_name.txt
ln -sf `pwd`/`cat  $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file_name.txt` $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file.txt