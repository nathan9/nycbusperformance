#!/bin/bash
# archive2mysql.sh db_name archive_path

set -e
if [ $# -lt 2 ]; then
        echo Usage: `basename $0` db_name archive_path
        exit 1
fi

DB_NAME=$1
ARCHIVE_PATH=$2

mv $ARCHIVE_PATH tmp_positions.csv.xz
xz -d tmp_positions.csv.xz
mysql $DB_NAME < archive_schema.sql
# Import positions data.  Should get as many warnings as there are lines -- MySQL doesn't understand the timestamp 'Z'.  Timestamps will still be correct, though.
mysqlimport --local --fields-terminated-by=, --lines-terminated-by='\r\n' --ignore-lines=1 $DB_NAME tmp_positions.csv
rm tmp_positions.csv

# Next, find trip_indexes using service_date and trip_id from positions and dates from feeds table...

