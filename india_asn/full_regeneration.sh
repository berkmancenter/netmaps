#!/bin/bash

working_dir=`dirname $0`

cd $working_dir

./update_downloaded_caida_data.sh; ./update_generated_data.sh ; ./update_map.sh 
