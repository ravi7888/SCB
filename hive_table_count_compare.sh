#!/bin/bash

## Setup logging
log_file=$(pwd)/table-count-compare.log

if [ ! -f "$log_file" ]; then
        touch "$log_file"
fi

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$log_file 2>&1
## Everything below will go to the file 'table-count-compare.log':

echo -e "Start date: $(date)\n"

proj_dir_default=$(pwd)

export HIVE_CONF_DIR=/etc/hive/conf
export beeline=/usr/hdp/2.6.4.162-1/hive/bin/beeline

# Declare jks file location for both the cluster on local node and make sure file exists.
#src_jks_file=/etc/hive-jks/hivetrust.jks
#dest_jks_file=$(pwd)/hivetrust.jks

src_jks_file=/home/1536047/hive-validation/hivetrust.jks
dest_jks_file=/etc/hive-jks/hivetrust.jks

#
hive1_url=""
hive2_url=""

if [ "$#" -ne 1 ]; then
  echo -e "Argument specification: \n '\$1': Table name in <database_name.table_name> format, Mandatory. \n '\$2': src beeline URL, optional, default: $haas1_dev_url \n '\$3': Dest beeline URL, optional, default: $haas2_dev_url \n  '\$4': Project dir, optional, default is $(pwd) " >&3
  exit 1;
fi

table_name=${1}
echo -e "Table Name : $table_name\n"
src_beeline_url=${2:-$hive1_url}
#echo -e "Source Beeline URL : $src_beeline_url\n"
dest_beeline_url=${3:-$hive2_url}
#echo -e "Destination Beeline URL : $dest_beeline_url\n"

proj_dir=${4:-$proj_dir_default}
proj_dir=$proj_dir/hive_counts
mkdir -p $proj_dir
echo -e "Project dir: $proj_dir"

query="select count(1) from $table_name"

echo -e "Execution at source--->"
src_table_cnt=`beeline -u $src_beeline_url --showHeader=false --silent=true --outputformat=csv2 -e "$query"`
echo -e  "src: $src_table_cnt\n"

echo -e "Execution at Destination--->"
dest_table_cnt=`beeline -u $dest_beeline_url --showHeader=false --silent=true --outputformat=csv2 -e "$query"`
echo -e  "dest: $dest_table_cnt\n"

if [[ -z "$src_table_cnt"  ||  -z "$dest_table_cnt" ]]
then
  echo -e "ERROR: cant't comapre between src and destination $table_name count is NULL/empty ;  src count: $src_table_cnt; dest count: $dest_table_cnt \n"
elif [[ "$src_table_cnt" -eq "$dest_table_cnt" ]]
then
  echo -e "$table_name count matches between src and destination"
  echo -e  "src,$table_name,$src_table_cnt,$dest_table_cnt" >> $proj_dir/counts.csv
#  echo -e  "dest,$table_name,$dest_table_cnt">> $proj_dir/counts.csv
else
  echo -e "$table_name count does NOT match between src and destination ;src count: $src_table_cnt; dest count: $dest_table_cnt \n"
fi

echo -e "\nEnd date: $(date)\n"
echo -e "=====================================================================================================================================================================================\n"
