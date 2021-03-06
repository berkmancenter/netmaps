#!/bin/bash

set -u
set -o  errexit

source ./set_common_script_variables.sh

CAIDA_SERVER=as-rank.caida.org

function download_for_year
{
local YEAR=$1

CAIDA_DATA_DIRECTORY_URL=http://$CAIDA_SERVER/data/$YEAR.01

wget  -P $DATA_DOWNLOAD_DIRECTORY -q -N  -R 'paths.*.txt' -r -l 1 $CAIDA_DATA_DIRECTORY_URL 
}

YEAR=`date +%Y`
download_for_year $YEAR
find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_SERVER > /dev/null || {
echo "Trying prior year";
YEAR=`date --date='1 year ago' +%Y`
download_for_year $YEAR

}
find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_SERVER -iname 'as-rel.*txt' -print0 | xargs -0 ls -tdr | tail -n 1 > $DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt
