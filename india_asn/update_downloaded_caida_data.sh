source ./set_common_script_variables.sh

mkdir -p $DATA_DOWNLOAD_DIRECTORY

./update_caida_as2attr_data.sh ; ./update_caida_as_relationship_data.sh ; ./update_caida_routeviews-prefix2as_data.sh;