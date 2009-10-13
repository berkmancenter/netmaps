#!/bin/bash

set -e
set -u 

#THIS SCRIPT DOWNLOADS the latest caida route-views -prefix2as file.

source set_common_script_variables.sh

CAIDA_ROUTEVIEWS_SERVER=data.caida.org
CAIDA_DATA_ROUTEVIEWS_DIRECTORY_BASE=datasets/routing/routeviews-prefix2as

function get_month_of_routeviews_data
{
local YEAR=$1;
local MONTH=$2;

CAIDA_DATA_ROUTEVIEWS_DIRECTORY=$CAIDA_DATA_ROUTEVIEWS_DIRECTORY_BASE/$YEAR/$MONTH
CAIDA_DATA_ROUTEVIEWS_DIRECTORY_URL=http://$CAIDA_ROUTEVIEWS_SERVER/$CAIDA_DATA_ROUTEVIEWS_DIRECTORY
echo $CAIDA_DATA_ROUTEVIEWS_DIRECTORY_URL

wget -P $DATA_DOWNLOAD_DIRECTORY --debug --no-parent -N  -A *.gz,*.html -r -l 2 --include-directories=$CAIDA_DATA_ROUTEVIEWS_DIRECTORY $CAIDA_DATA_ROUTEVIEWS_DIRECTORY_URL 
}


YEAR=`date +%Y`
MONTH=`date +%m`
get_month_of_routeviews_data $YEAR $MONTH


#Handle corner case: Data seems to be updated daily but 
#if we run on the 1st of the month there might not be CAIDA data for
# the current month yet.
#In that case just grab the previous month's data

find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_ROUTEVIEWS_SERVER > /dev/null ||
{
echo "Trying previous month";
YEAR=`date --date='1 month ago' +%Y`
MONTH=`date --date='1 month ago' +%m`    
get_month_of_routeviews_data $YEAR $MONTH    
}

find $DATA_DOWNLOAD_DIRECTORY/$CAIDA_ROUTEVIEWS_SERVER -iname 'routeviews-rv2*.pfx2as.*gz' -print0 | xargs -0 ls -tdr | tail -n 1 > $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file_name.txt
ln -sf `pwd`/`cat  $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file_name.txt` $DATA_DOWNLOAD_DIRECTORY/newest_prefix2as_file.txt