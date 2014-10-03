# setup.sh db_name

if [ $# -lt 1 ]; then
        echo Usage: `basename $0` db_name
        exit 1
fi

read -p 'Are you sure?  All existing GTFS data will be deleted.  [y/N]: ' -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	echo Setup aborted.
	exit 1
fi

DB_NAME=$1

mysql $DB_NAME < multifeed_gtfs_schema.sql
cp dates.sql.xz dates_copy.sql.xz
xz -d dates_copy.sql.xz
mysql $DB_NAME < dates_copy.sql
rm dates_copy.sql

