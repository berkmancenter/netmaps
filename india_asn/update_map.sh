#!/bin/sh

CAIDA_SERVER=as-rank.caida.org
CAIDA_DATA_DIRECTORY_URL=http://$CAIDA_SERVER/data/2009/
WEB_DIRECTORY=asn_web_graphs
wget -q -N  -r -l 1 $CAIDA_DATA_DIRECTORY_URL
find $CAIDA_SERVER -iname 'as-rel.*txt' -print0 | xargs -0 ls -tdr | tail -n 1 > newest_as_rel_file_name.txt
if ! cmp --quiet newest_as_rel_file_name.txt last_mapped_as_rel_file_name.txt
then  echo "files differ ";
else
echo "Files don't differ";
exit;
fi


echo "rebuilding results"

mkdir results
mkdir results/graphs
./make_asn_graph.pl < `cat newest_as_rel_file_name.txt`
mv results $WEB_DIRECTORY/results_new
rm -rf $WEB_DIRECTORY/results_old
mv $WEB_DIRECTORY/results $WEB_DIRECTORY/results_old
mv $WEB_DIRECTORY/results_new  $WEB_DIRECTORY/results
mv newest_as_rel_file_name.txt last_mapped_as_rel_file_name.txt
