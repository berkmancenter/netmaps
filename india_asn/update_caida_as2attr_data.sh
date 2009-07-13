#!/bin/bash

#
#  This data seems to come from 2006
#
#  It's mirrored by CAIDA but the offical version seems to be hosted at gatech.edu 
#  See http://www.caida.org/data/active/as_taxonomy/

source ./set_common_script_variables.sh

CAIDA_AS2ATTR_SERVER=www.caida.org
CAIDA_AS2ATTR_DATA_FILE_URL=http://$CAIDA_AS2ATTR_SERVER/data/active/as_taxonomy/as2attr.tgz

wget -P $DATA_DOWNLOAD_DIRECTORY -N  -r -l 1 $CAIDA_AS2ATTR_DATA_FILE_URL
tar -x -C $DATA_DOWNLOAD_DIRECTORY -zvf $DATA_DOWNLOAD_DIRECTORY/$CAIDA_AS2ATTR_SERVER/data/active/as_taxonomy/as2attr.tgz