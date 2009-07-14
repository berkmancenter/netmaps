#!/bin/bash

working_dir=`dirname $0`

cd $working_dir

source ./set_common_script_variables.sh

./update_caida_as_relationship_data.sh

if ! cmp --quiet $NEWEST_AS_REL_LOCATION_FILE $LAST_AS_REL_LOCATION_FILE
then  echo "Newer CAIDA data avaliable ";
else
exit;
fi
