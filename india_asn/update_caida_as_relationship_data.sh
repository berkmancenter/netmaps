#!/bin/sh

CAIDA_SERVER=as-rank.caida.org
CAIDA_DATA_DIRECTORY_URL=http://$CAIDA_SERVER/data/2009/
DATA_DOWNLOAD_DIRECTORY=downloaded_data
WEB_DIRECTORY=asn_web_graphs
wget -P $DATA_DOWNLOAD_DIRECTORY -q -N  -r -l 1 $CAIDA_DATA_DIRECTORY_URL
find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_SERVER -iname 'as-rel.*txt' -print0 | xargs -0 ls -tdr | tail -n 1 > $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt
