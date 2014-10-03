# add_events.sql

CREATE TEMPORARY TABLE positions2departures (
        vehicle_id smallint(4) ZEROFILL NOT NULL,
        service_date date NOT NULL,
        trip_index int NOT NULL,
        stop_id int(6) NOT NULL,
        dep_start datetime,
        dep_end datetime,
	block_assigned bool NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

SET @last_date = '0000-00-00';
SET @last_trip = -1;
SET @last_vehicle = 0;
SET @last_stop = -1;
SET @last_time = NULL;

INSERT positions2departures SELECT vehicle1, service_date1, trip_index1, stop1, dep_start, dep_end, block_assigned FROM (
	SELECT
		@last_vehicle AS vehicle1,
		@last_date AS service_date1,
		@last_trip AS trip_index1,
		@last_stop AS stop1,
		IF(next_stop_id != @last_stop, @last_time, timestamp) AS dep_start,
		IF(next_stop_id != @last_stop, timestamp, NULL) AS dep_end,
		block_assigned,
		@last_time := timestamp,
		@last_date := service_date,
		@last_trip := trip_index,
		@last_vehicle := vehicle_id,
		@last_stop := next_stop_id
	FROM positions
	WHERE
		timestamp BETWEEN SUBTIME(CAST(@start_date AS DATETIME), '01:00:00') AND ADDTIME(CAST(@end_date AS DATETIME), '25:00:00') AND
		next_stop_id IS NOT NULL
	ORDER BY vehicle_id, timestamp
) AS x;

INSERT IGNORE events SELECT service_date, trip_index, vehicle_id, stop_id, ADDTIME(dep_start, SEC_TO_TIME(FLOOR(TIME_TO_SEC(TIMEDIFF(dep_end, dep_start))/2))) AS est_dep_time, CEILING(TIME_TO_SEC(TIMEDIFF(dep_end, dep_start))/2) AS dep_accuracy, IF(MIN(block_assigned > 0), '0000-00-00 00:00:00', NULL) AS sched_dep_time FROM positions2departures WHERE service_date > '0000-00-00' AND dep_end IS NOT NULL AND dep_end > dep_start GROUP BY service_date, trip_index, vehicle_id, stop_id;

# TODO deal with EST vs EDT
UPDATE events e, stop_times st SET sched_dep_time = CONVERT_TZ(ADDTIME(CAST(service_date AS DATETIME), departure_time), '-04:00', '+00:00') WHERE st.trip_index = e.trip_index AND st.stop_id = e.stop_id AND sched_dep_time IS NOT NULL AND pickup_type != 1;

