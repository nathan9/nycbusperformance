# add_events.sql (@start_date, @end_date)

# Requires timezone info: sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

CREATE TEMPORARY TABLE positions2departures (
        vehicle_id smallint(4) ZEROFILL NOT NULL,
        service_date date NOT NULL,
        trip_index int NOT NULL,
        stop_id int(6) NOT NULL,
        dep_start_utc datetime,
        dep_end_utc datetime,
	block_assigned bool NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

SET @last_date = '0000-00-00';
SET @last_trip = -1;
SET @last_vehicle = 0;
SET @last_stop = -1;
SET @last_time = NULL;

INSERT positions2departures SELECT vehicle1, service_date1, trip_index1, stop1, dep_start_utc, dep_end_utc, block_assigned FROM (
	SELECT
		@last_vehicle AS vehicle1,
		@last_date AS service_date1,
		@last_trip AS trip_index1,
		@last_stop AS stop1,
		IF(next_stop_id != @last_stop, @last_time, timestamp_utc) AS dep_start_utc,
		IF(next_stop_id != @last_stop, timestamp_utc, NULL) AS dep_end_utc,
		block_assigned,
		@last_time := timestamp_utc,
		@last_date := service_date,
		@last_trip := trip_index,
		@last_vehicle := vehicle_id,
		@last_stop := next_stop_id
	FROM positions
	WHERE
		timestamp_utc BETWEEN SUBTIME(CAST(@start_date AS DATETIME), '01:00:00') AND ADDTIME(CAST(@end_date AS DATETIME), '25:00:00') AND
		next_stop_id IS NOT NULL
	ORDER BY vehicle_id, timestamp_utc
) AS x;

INSERT IGNORE events
	SELECT
		service_date,
		p2d.trip_index,
		vehicle_id,
		p2d.stop_id,
		ADDTIME(dep_start_utc, SEC_TO_TIME(FLOOR(TIME_TO_SEC(TIMEDIFF(dep_end_utc, dep_start_utc)) / 2))) AS est_dep_utc,
		CEILING(TIME_TO_SEC(TIMEDIFF(dep_end_utc, dep_start_utc)) / 2) AS dep_accuracy,
		NULL AS sched_dep_utc,
		IF(MIN(block_assigned > 0), '0000-00-00', NULL) AS sched_dep_date,	# mark departures where block assigned; departure time subject to comparison with schedule to determine schedule adherence
		NULL AS sched_dep_hour,
		route_id,
		direction_id
	FROM positions2departures p2d, trips t, routes r
	WHERE service_date > '0000-00-00' AND dep_end_utc IS NOT NULL AND p2d.trip_index = t.trip_index AND t.route_index = r.route_index AND dep_end_utc > dep_start_utc
	GROUP BY service_date, trip_index, vehicle_id, stop_id;

# Set scheduled departure times from stop_times where block assigned.  Times are rounded to the nearest minute because that is what`s advertised at bus stops (except SBS+, which is advertised as frequency-based).

UPDATE events e, stop_times st
	SET
		sched_dep_utc = @sched_dep_utc := CONVERT_TZ(
			ADDTIME(
				CAST(service_date AS DATETIME),
				SEC_TO_TIME(60 * ROUND(TIME_TO_SEC(departure_time) / 60))
			),
			TIME_FORMAT(
				TIMEDIFF(
					@noon := ADDTIME(CAST(service_date AS DATETIME), '12:00:00'),
					CONVERT_TZ(@noon, 'America/New_York', 'UTC')
				),
				'%H:%i'
			),
			'UTC'),
		sched_dep_date = DATE(@local := CONVERT_TZ(@sched_dep_utc, 'UTC', 'America/New_York')),
		sched_dep_hour = HOUR(@local)
		WHERE sched_dep_date = '0000-00-00' AND (e.trip_index = st.trip_index AND e.stop_id = st.stop_id) AND pickup_type != 1;

UPDATE events SET sched_dep_date = NULL WHERE sched_dep_date = '0000-00-00';	# departures where no pickup or stop not on specified trip

