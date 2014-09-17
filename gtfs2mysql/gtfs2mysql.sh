#!/bin/bash
# gtfs2mysql.sh

set -e
if [ $# -lt 2 ]; then
	echo Usage: `basename $0` db_name gtfs_path [feed_name]
	exit 1
elif [ $# -lt 3 ]; then
	FEED_NAME=$(basename "$2" .zip)
else
	FEED_NAME=$3
fi
DB_NAME=$1
GTFS_PATH=$2
GTFS_FILES=(agency.txt calendar.txt calendar_dates.txt routes.txt shapes.txt stops.txt stop_times.txt trips.txt)

unzip "$GTFS_PATH" -d .

for gtfs_file in ${GTFS_FILES[@]}
do
	perl -i -p -e 's/\r//' $gtfs_file	# remove carriage returns (\r)
	mv $gtfs_file tmp_$gtfs_file
done

./generate_schema.py
mysql $DB_NAME < schema.sql
rm schema.sql

for gtfs_file in ${GTFS_FILES[@]}
do
	mysqlimport --local --fields-optionally-enclosed-by=\" --fields-terminated-by=, --ignore-lines=1 $DB_NAME tmp_$gtfs_file
	rm tmp_$gtfs_file
done

mysql $DB_NAME -e "INSERT feeds SET feed_index = NULL, feed_start_date = '0000-00-00', feed_end_date = '0000-00-00', feed_name = \"$FEED_NAME\""
echo 'Integrating GTFS data into database...'
mysql $DB_NAME < integrate_gtfs.sql
echo 'Done!  (It may be necessary to manually adjust the feed start and end dates to prevent overlap/duplication of services.)'

