# add_events.sh db_name start_date [end_date]

set -e
if [ $# -lt 2 ]; then
        echo Usage: `basename $0` db_name start_date [end_date]
        exit 1
fi

DB_NAME=$1
START_DATE=$2

if [ $# -lt 3 ]; then
	END_DATE=$START_DATE
else
	END_DATE=$3
fi

# Infer events
mysql $DB_NAME -e "SET @start_date:='$START_DATE'; SET @end_date:='$END_DATE'; SOURCE add_events.sql;"

