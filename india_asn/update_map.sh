#!/bin/sh

DATA_DOWNLOAD_DIRECTORY=downloaded_data
./update_caida_as_relationship_data.sh

NEWEST_AS_REL_LOCATION_FILE=$DATA_DOWNLOAD_DIRECTORY/newest_as_rel_file_name.txt
LAST_AS_REL_LOCATION_FILE=$DATA_DOWNLOAD_DIRECTORY/last_mapped_as_rel_file_name.txt
WEB_DIRECTORY=asn_web_graphs
if ! cmp --quiet $NEWEST_AS_REL_LOCATION_FILE $LAST_AS_REL_LOCATION_FILE
then  echo "files differ ";
else
echo "Files don't differ";
exit;
fi


echo "rebuilding results"

mkdir -p results/graphs
./make_asn_graph.pl < `cat $NEWEST_AS_REL_LOCATION_FILE | head -n 200`
mv results $WEB_DIRECTORY/results_new
rm -rf $WEB_DIRECTORY/results_old
mv $WEB_DIRECTORY/results $WEB_DIRECTORY/results_old
mv $WEB_DIRECTORY/results_new  $WEB_DIRECTORY/results
mv $NEWEST_AS_REL_LOCATION_FILE $LAST_AS_REL_LOCATION_FILE
