#!/bin/sh

#
#  This data seems to come from 2006
#
#  It's mirrored by CAIDA but the offical version seems to be hosted at gatech.edu 
#  See http://www.caida.org/data/active/as_taxonomy/

CAIDA_SERVER=www.caida.org
CAIDA_DATA_FILE_URL=http://$CAIDA_SERVER/data/active/as_taxonomy/as2attr.tgz
DATA_DOWNLOAD_DIRECTORY=downloaded_data
WEB_DIRECTORY=asn_web_graphs
wget -P $DATA_DOWNLOAD_DIRECTORY -N  -r -l 1 $CAIDA_DATA_FILE_URL
#find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_SERVER -iname 'as-rel.*txt' -print0 | xargs -0 ls -tdr | tail -n 1 > $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt
tar -x -C $DATA_DOWNLOAD_DIRECTORY -zvf $DATA_DOWNLOAD_DIRECTORY/$CAIDA_SERVER/data/active/as_taxonomy/as2attr.tgz