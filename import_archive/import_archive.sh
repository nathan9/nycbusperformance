# import_archive.sh db_name archive_path

set -e
if [ $# -lt 2 ]; then
        echo Usage: `basename $0` db_name archive_path
        exit 1
fi

DB_NAME=$1
ARCHIVE_PATH=$2

cp $ARCHIVE_PATH tmp_positions.csv.xz
xz -d tmp_positions.csv.xz
mysql $DB_NAME < tmp_archive_schema.sql
# Import positions data.  Should get as many warnings as there are lines -- MySQL doesn't understand the 'Z' character at the end of the ISO 8601 timestamp (it indicates that the timestamp is in UTC time).  Nevertheless, timestamps will be imported correctly.
mysqlimport --local --fields-terminated-by=, --lines-terminated-by='\r\n' --ignore-lines=1 $DB_NAME tmp_positions.csv
mysql nycbus -e "SELECT COUNT(1) FROM tmp_positions"
rm tmp_positions.csv

# Add positions data to permanent table, using integer trip_index in place of string trip_id.
mysql nycbus -e "INSERT positions SELECT timestamp_utc, vehicle_id, latitude, longitude, bearing, progress, service_date, trip_index, block_assigned, next_stop_id, dist_along_route, dist_from_stop FROM tmp_positions, feeds, trips WHERE (service_date BETWEEN feed_start_date AND feed_end_date) AND feeds.feed_index = trips.feed_index AND trips.trip_id = tmp_positions.trip_id"
mysql nycbus -e "DROP TABLE tmp_positions"

mysql nycbus -e "SELECT DATE(timestamp_utc) date, COUNT(1) FROM positions GROUP BY date ORDER BY date DESC LIMIT 1"

